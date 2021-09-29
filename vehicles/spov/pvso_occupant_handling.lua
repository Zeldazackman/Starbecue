function p.forceSeat( occupantId, seatindex )
	if occupantId then
		vehicle.setLoungeEnabled("occupant"..seatindex, true)
		world.sendEntityMessage(occupantId, "pvsoMakeNonHostile")
		world.sendEntityMessage( occupantId, "pvsoForceSit", {index=seatindex, source=entity.id()})
	end
end

function p.unForceSeat(occupantId)
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoRemoveForceSit", 1, entity.id())
	end
end

function p.eat( occupantId, location )
	local seatindex = p.occupants.total
	local emptyslots = p.occupantSlots - p.occupants.total
	if not p.includeDriver then
		seatindex = seatindex + 1
		emptyslots = emptyslots - 1
	end

	if occupantId == nil or p.entityLounging(occupantId) or p.inedible(occupantId) or p.locationFull(location) then return false end -- don't eat self

	local loungeables = world.entityQuery( world.entityPosition(occupantId), 5, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.entityLounging", callScriptArgs = { occupantId }
	} )

	local edibles = world.entityQuery( world.entityPosition(occupantId), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { occupantId, seatindex, entity.id(), emptyslots, p.vso.locations[location].max }
	} )

	if edibles[1] == nil then
		if loungeables[1] == nil then -- now just making sure the prey doesn't belong to another loungable now
			p.occupant[seatindex].id = occupantId
			p.occupant[seatindex].location = location
			p.forceSeat( occupantId, seatindex)
			p.updateOccupants(0)
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] ):gsub("^spov","") -- "spov"..species
	p.occupant[seatindex].id = occupantId
	p.occupant[seatindex].species = species
	p.occupant[seatindex].location = location
	p.forceSeat( occupantId, seatindex )
	p.updateOccupants(0)
	return true
end

function p.uneat( occupantId )
	if occupantId == nil or not world.entityExists(occupantId) then return end
	world.sendEntityMessage( occupantId, "PVSOClear")
	world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoRemoveBellyEffects")
	p.unForceSeat( occupantId )
	if not p.lounging[occupantId] then return end
	local seatindex = p.lounging[occupantId].index
	local occupantData = p.lounging[occupantId]
	if world.entityType(occupantId) == "player" then
		world.sendEntityMessage(occupantId, "openPVSOInterface", "close")
	end

	if occupantData.species ~= nil then
		table.insert(p.preyRecepients, {
			vso = world.spawnVehicle( "spov"..occupantData.species, p.localToGlobal({ occupantData.victimAnim.last.x or 0, occupantData.victimAnim.last.y or 0}), { driver = occupantId, settings = occupantData.smolPreyData.settings, uneaten = true, startState = occupantData.smolPreyData.state, layer = occupantData.smolPreyData.layer } ),
			owner = occupantId
		})
	else
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoRemoveInvisible")
	end

	p.lounging[occupantId] = nil
	p.occupant[seatindex] = p.clearOccupant(seatindex)
	p.updateOccupants(0)
	return true
end

function p.edible( occupantId, seatindex, source, emptyslots, locationslots )
	if p.driver ~= occupantId then return false end
	local total = p.occupants.total
	if not p.includeDriver then
		total = total + 1
	end
	if total > emptyslots or total > locationslots then return false end
	if p.stateconfig[p.state].edible then
		world.sendEntityMessage( source, "smolPreyData", seatindex, p.getSmolPreyData(p.settings, world.entityName( entity.id() ):gsub("^spov",""), p.state, p.seats[p.driverSeat].smolPreyData), entity.id())
		local nextSlot = 1
		for i = 1, p.occupantSlots do
			if p.occupant[i].id ~= nil then
				local location = p.occupant[i].location
				local occupantData = p.clearOccupant(seatindex + nextSlot)
				local massMultiplier = p.vso.locations[location].mass or 0

				occupantData.location = "nested"
				if p.settings[location] ~= nil and p.settings[location].hyper then
					massMultiplier = p.vso.locations[location].hyperMass or massMultiplier
				end

				occupantData = sb.jsonMerge(occupantData, {
					id = p.occupant[i].id,
					visible = false,
					occupantTime = p.occupant[i].occupantTime,
					smolPreyData = p.occupant[i].smolPreyData,
					nestedPreyData = {
						owner = p.driver,
						location = location,
						massMultiplier = massMultiplier,
						digest = p.vso.locations[location].digest
				}})
				world.sendEntityMessage( source, "addPrey", seatindex + nextSlot, occupantData)
				nextSlot = nextSlot+1
			end
		end
		return true
	end
end

p.preyRecepients = {}

function p.sendPreyTo()
	for j, recepient in ipairs(p.preyRecepients) do
		local nextSlot = 1
		if world.entityExists(recepient.vso) then
			for i = 0, p.occupantSlots do
				if p.occupant[i].id ~= nil and p.occupant[i].location == "nested" and p.occupant[i].nestedPreyData.owner == recepient.owner then
					local occupantData = sb.jsonMerge(p.occupant[i], {
						location = p.occupant[i].nestedPreyData.location,
						visible = false
					})
					world.sendEntityMessage( recepient.vso, "addPrey", nextSlot, occupantData)
					p.occupant[i].id = nil
					nextSlot = nextSlot+1
				end
			end
			table.remove(p.preyRecepients, j)
		end
	end
end

function p.firstNotLounging(entityaimed)
	for _, eid in ipairs(entityaimed) do
		if not p.entityLounging(eid) then
			return eid
		end
	end
end

function p.moveOccupantLocation(args, location)
	if p.locationFull(location) then return false end
	p.lounging[args.id].location = location
	return true
end

function p.findFirstOccupantIdForLocation(location)
	for i = 0, p.occupantSlots do
		if p.occupant[i].location == location then
			return p.occupant[i].id, i
		end
	end
	return
end


function p.locationFull(location)
	if p.occupants.total == p.occupants.maximum then
		return true
	else
		return p.occupants[location] == p.vso.locations[location].max
	end
end

function p.locationEmpty(location)
	if p.occupants.total == 0 then
		return true
	else
		return p.occupants[location] == 0
	end
end

function p.doVore(args, location, statuses, sound )
	if p.eat( args.id, location ) then
		p.justAte = args.id
		vehicle.setInteractive( false )
		p.showEmote("emotehappy")
		p.transitionLock = true
		--vsoVictimAnimSetStatus( "occupant"..i, statuses );
		return true, function()
			p.justAte = nil
			p.transitionLock = false
			vehicle.setInteractive( true )
			if sound then animator.playSound( sound ) end
		end
	else
		return false
	end
end

function p.doEscape(args, statuses, afterstatus )
	local victim = args.id
	if not victim then return false end -- could be part of above but no need to log an error here

	vehicle.setInteractive( false )
	--vsoVictimAnimSetStatus( "occupant"..i, statuses );
	p.transitionLock = true
	return true, function()
		p.transitionLock = false
		vehicle.setInteractive( true )
		p.uneat( victim )
		--world.sendEntityMessage( victim, "applyStatusEffect", afterstatus.status, afterstatus.duration, entity.id() )
	end
end

function p.applyStatusEffects(eid, statuses)
	for i = 1, #statuses do
		world.sendEntityMessage(eid, "applyStatusEffect", statuses[i][1], statuses[i][2], entity.id())
	end
end

function p.applyStatusLists()
	for i = 0, p.occupantSlots do
		if p.occupant[i].id ~= nil and world.entityExists(p.occupant[i].id) then
			if not p.weirdFixFrame then
				vehicle.setLoungeEnabled(p.occupant[i].seatname, true)
			end
			p.loopedMessage( p.occupant[i].seatname.."NonHostile", p.occupant[i].id, "pvsoMakeNonHostile")
			p.loopedMessage( p.occupant[i].seatname.."StatusEffects", p.occupant[i].id, "pvsoApplyStatusEffects", {p.occupant[i].statList} )
			p.loopedMessage( p.occupant[i].seatname.."ForceSeat", p.occupant[i].id, "pvsoForceSit", {{index=i, source=entity.id()}})
		else
			vehicle.setLoungeEnabled(p.occupant[i].seatname, false)
		end
	end
	p.weirdFixFrame = nil
end

function p.addStatusToList(index, status, power, source)
	p.occupant[index].statList[status] = {
		power = power or 1,
		source = source or entity.id()
	}
end

function p.removeStatusFromList(index, status)
	p.occupant[index].statList[status] = nil
end

function p.resetOccupantCount()
	p.occupants.total = 0
	for location, data in pairs(p.vso.locations) do
		if data.sided then
			p.occupants[location.."R"] = 0
			p.occupants[location.."L"] = 0
		else
			p.occupants[location] = 0
		end
	end
	p.occupants.fatten = p.settings.fatten or 0
	p.occupants.mass = 0
end

function p.updateOccupants(dt)
	p.sendPreyTo()
	p.resetOccupantCount()

	local lastFilled = true

	for i = 0, p.occupantSlots do
		if not (i == 0 and not p.includeDriver) then
			if p.occupant[i].id ~= nil and world.entityExists(p.occupant[i].id) then
				p.occupants.total = p.occupants.total + 1
				if not lastFilled and p.swapCooldown <= 0 then
					p.swapOccupants( i-1, i )
					i = i - 1
				end

				p.occupant[i].index = i
				local seatname = "occupant"..i
				p.occupant[i].seatname = seatname
				p.lounging[p.occupant[i].id] = p.occupant[i]
				p.seats[p.occupant[i].seatname] = p.occupant[i]
				p.occupant[i].occupantTime = p.occupant[i].occupantTime + dt

				local massMultiplier = 0
				local mass = p.occupant[i].controls.mass
				local location = p.occupant[i].location

				if location == "nested" then
					local owner = p.occupant[i].nestedPreyData.owner
					location = p.lounging[owner].location
					mass = mass * p.occupant[i].nestedPreyData.massMultiplier
					animator.resetTransformationGroup(seatname.."Position")
					animator.translateTransformationGroup(seatname.."Position", p.globalToLocal(world.entityPosition(owner)))
				end

				p.occupants[location] = p.occupants[location] + 1

				massMultiplier = p.vso.locations[location].mass or 0

				if p.settings[location] ~= nil and p.settings[location].hyper then
					massMultiplier = p.vso.locations[location].hyperMass or massMultiplier
				end

				p.occupants.mass = p.occupants.mass + mass * massMultiplier

				if p.occupant[i].progressBarActive == true then
					p.occupant[i].progressBar = p.occupant[i].progressBar + (((math.log(p.occupant[i].controls.powerMultiplier)+1) * dt) * p.occupant[i].progressBarMultiplier)
					if p.occupant[i].progressBarMultiplier > 0 then
						p.occupant[i].progressBar = math.min(100, p.occupant[i].progressBar)
						if p.occupant[i].progressBar >= 100 and p.occupant[i].progressBarFinishFuncName ~= nil then
							p[p.occupant[i].progressBarFinishFuncName](i)
							p.occupant[i].progressBarActive = false
						end
					else
						p.occupant[i].progressBar = math.max(0, p.occupant[i].progressBar)
						if p.occupant[i].progressBar <= 0 and p.occupant[i].progressBarFinishFuncName ~= nil then
							p[p.occupant[i].progressBarFinishFuncName](i)
							p.occupant[i].progressBarActive = false
						end
					end
				end

				p.occupant[i].indicatorCooldown = p.occupant[i].indicatorCooldown - dt

				if world.entityType(p.occupant[i].id) == "player" and p.occupant[i].indicatorCooldown <= 0 then
					-- p.occupant[i].indicatorCooldown = 0.5
					local struggledata = (p.stateconfig[p.state].struggle or {})[p.occupant[i].location] or {}
					local directions = {}
					if not p.transitionLock then
						for dir, data in pairs(struggledata.directions or {}) do
							if data and (not p.driving or data.drivingEnabled) then
								if dir == "front" then dir = ({"left","","right"})[p.direction+2] end
								if dir == "back" then dir = ({"right","","left"})[p.direction+2] end
								directions[dir] = data.indicate or "default"
							end
						end
					end
					p.loopedMessage(p.occupant[i].id.."-indicator", p.occupant[i].id, -- update quickly but minimize spam
						"openPVSOInterface", {"indicatorhud",
						{
							owner = entity.id(),
							directions = directions,
							progress = {
								active = p.occupant[i].progressBarActive,
								color = p.occupant[i].progressBarColor,
								percent = p.occupant[i].progressBar,
								dx = (math.log(p.occupant[i].controls.powerMultiplier)+1) * p.occupant[i].progressBarMultiplier,
							},
							time = p.occupant[i].occupantTime
						}
					})
				end

				lastFilled = true
			elseif p.occupant[i].id ~= nil and not world.entityExists(p.occupant[i].id) then
				p.occupant[i] = p.clearOccupant(i)
				p.refreshList = true
				lastFilled = false
			else
				lastFilled = false
				p.occupant[i] = p.clearOccupant(i)
			end
		end
	end
	p.swapCooldown = math.max(0, p.swapCooldown - 1)

	mcontroller.applyParameters({mass = p.movementParams.mass + p.occupants.mass})
	animator.setGlobalTag( "totaloccupants", tostring(p.occupants.total) )
	for location, data in pairs(p.vso.locations) do
		if data.combine ~= nil then -- this doesn't work for sided stuff, but I don't think we'll ever need combine for sided stuff
			for _, combine in ipairs(data.combine) do
				p.occupants[location] = p.occupants[location] + p.occupants[combine]
				p.occupants[combine] = p.occupants[location]
			end
		end
		if data.sided then
			if p.direction >= 1 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
				animator.setGlobalTag( location.."2occupants", tostring(p.occupants[location.."R"]) )
				animator.setGlobalTag( location.."1occupants", tostring(p.occupants[location.."L"]) )
			else
				animator.setGlobalTag( location.."1occupants", tostring(p.occupants[location.."R"]) )
				animator.setGlobalTag( location.."2occupants", tostring(p.occupants[location.."L"]) )
			end
		else
			animator.setGlobalTag( location.."occupants", tostring(p.occupants[location]) )
		end
	end
end

function p.swapOccupants(a, b)
	local A = p.occupant[a]
	local B = p.occupant[b]
	p.occupant[a] = B
	p.occupant[b] = A

	p.swapCooldown = 10 -- p.unForceSeat and p.forceSeat are asynchronous, without some cooldown it'll try to swap multiple times and bad things will happen
end

function p.entityLounging( entity )
	for i = 0, p.occupantSlots do
		if entity == p.occupant[i].id then return true end
	end
	return false
end

function p.doBellyEffects(dt)
	if p.occupants.total <= 0 then return end

	local bellyEffect = p.settings.bellyEffect or "pvsoRemoveBellyEffects"
	local hungereffect = 0
	if (bellyEffect == "pvsoDigest") or (bellyEffect == "pvsoSoftDigest") then
		hungereffect = 1
	end
	if p.settings.displayDamage then
		if p.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
			bellyEffect = p.config.bellyDisplayStatusEffects[bellyEffect]
		end
	end

	local powerMultiplier = math.log(p.seats[p.driverSeat].controls.powerMultiplier) + 1

	for i = 0, p.occupantSlots do
		local eid = p.occupant[i].id
		if eid and world.entityExists(eid) and (not (i == 0 and not p.includeDriver)) then
			local health = world.entityHealth(eid)
			local light = p.vso.lights.prey
			light.position = world.entityPosition( eid )
			world.sendEntityMessage( eid, "PVSOAddLocalLight", light )

			if p.occupant[i].location == "nested" then -- to make nested prey use the belly effect of the one they're in
				local owner = p.occupant[i].nestedPreyData.owner
				local settings = p.lounging[owner].smolPreyData.settings or {}
				local status = settings.bellyEffect or "pvsoRemoveBellyEffects"
				local powerMultiplier = math.log(p.lounging[owner].controls.powerMultiplier) + 1
				if p.occupant[i].nestedPreyData.digest then
					world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, owner)
				end
			elseif p.vso.locations[p.occupant[i].location].digest then
				if (p.settings.bellySounds == true) then p.randomTimer( "gurgle", 1.0, 8.0, function() animator.playSound( "digest" ) end ) end
				local hunger_change = (hungereffect * powerMultiplier * dt)/100
				if bellyEffect ~= nil and bellyEffect ~= "" then world.sendEntityMessage( eid, "applyStatusEffect", bellyEffect, powerMultiplier, entity.id() ) end
				if (p.settings.bellyEffect == "pvsoSoftDigest") and health[1] <= 1 then hunger_change = 0 end
				if p.driver then
					world.sendEntityMessage( p.driver, "addHungerHealth", hunger_change)
				end
				p.hunger = math.min(100, p.hunger + hunger_change)

				p.extraBellyEffects(i, eid, health, bellyEffect)
			else
				p.otherLocationEffects(i, eid, health, bellyEffect)
			end
		end
	end
end

function p.handleStruggles(dt)
	if p.transitionLock then return end
	local struggler = -1
	local struggledata
	local movedir = nil

	while (movedir == nil) and struggler < p.occupantSlots do
		struggler = struggler + 1
		movedir = p.getSeatDirections( p.occupant[struggler].seatname )
		p.occupant[struggler].bellySettleDownTimer = math.max( 0, p.occupant[struggler].bellySettleDownTimer - dt)

		if (p.occupant[struggler].seatname == p.driverSeat) and not p.includeDriver then
			movedir = nil
		end
		if p.occupant[struggler].bellySettleDownTimer <= 0 then
			p.occupant[struggler].struggleCount = math.max( 0, p.occupant[struggler].struggleCount - 1)
			p.occupant[struggler].bellySettleDownTimer = 4
		end

		if movedir then
			struggledata = p.stateconfig[p.state].struggle[p.occupant[struggler].location]
			if struggledata == nil or struggledata.directions == nil or struggledata.directions[movedir] == nil then
				movedir = nil
			elseif p.partsAreStruggling(struggledata.parts) then
				movedir = nil
			elseif config.getParameter("name") ~= "spovegg" then
				if p.occupant[struggler].species ~= nil and p.config.speciesStrugglesDisabled[p.occupant[struggler].species] then
					movedir = nil
				end
			end
		end
	end
	if movedir == nil then return end -- invalid struggle

	local strugglerId = p.occupant[struggler].id

	if struggledata.script ~= nil then
		local statescript = state[p.state][struggledata.script]
		if statescript ~= nil then
			statescript({id = strugglerId, direction = movedir})
		else
			sb.logError("no script named: ["..struggledata.script.."] in state: ["..p.state.."]")
		end
	end

	if p.struggleChance(struggledata, struggler, movedir) then
		p.occupant[struggler].struggleCount = 0
		p.doTransition( struggledata.directions[movedir].transition, {direction = movedir, id = strugglerId} )
	else
		p.occupant[struggler].struggleCount = p.occupant[struggler].struggleCount + 1
		p.occupant[struggler].bellySettleDownTimer = 5

		local animation = {offset = struggledata.directions[movedir].offset}
		for _, part in ipairs(struggledata.parts) do
			animation[part] = "s_"..movedir
		end

		p.doAnims(animation)

		if not p.movement.animating then
			p.doAnims( struggledata.directions[movedir].animation or struggledata.animation )
		else
			p.doAnims( struggledata.directions[movedir].animationWhenMoving or struggledata.animationWhenMoving )
		end

		if struggledata.directions[movedir].victimAnimation then
			local id = strugglerId
			if struggledata.directions[movedir].victimAnimLocation ~= nil then
				id = p.findFirstOccupantIdForLocation(struggledata.directions[movedir].victimAnimLocation)
			end
			p.doVictimAnim( id, struggledata.directions[movedir].victimAnimation, (struggledata.parts[1] or "body").."State" )
		end

		local sound = struggledata.sound
		if struggledata.directions[movedir].sound ~= nil then
			sound = struggledata.directions[movedir].sound
		end
		if sound == nil then
			animator.playSound( "struggle" )
		elseif sound then
			animator.playSound( sound )
		end
	end
end

function p.struggleChance(struggledata, struggler, movedir)
	local chances = struggledata.chances
	if struggledata.directions[movedir].chances ~= nil then
		chances = struggledata.directions[movedir].chances
	end
	if chances ~= nil and chances[p.settings.escapeModifier] ~= nil then
		chances = chances[p.settings.escapeModifier]
	end
	if chances ~= nil and chances.max == 0 then return true end
	return (p.settings.escapeModifier ~= "noEscape")
	and chances ~= nil and (chances.min ~= nil) and (chances.max ~= nil)
	and (math.random(chances.min, chances.max) <= p.occupant[struggler].struggleCount)
	and ((not p.driving) or struggledata.directions[movedir].drivingEnabled)
end
