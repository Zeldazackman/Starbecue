function p.forceSeat( occupantId, seatindex )
	if occupantId then
		vehicle.setLoungeEnabled("occupant"..seatindex, true)
		world.sendEntityMessage(occupantId, "sbqMakeNonHostile")
		world.sendEntityMessage( occupantId, "sbqForceSit", {index=seatindex, source=entity.id()})
	end
end

function p.unForceSeat(occupantId)
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "sbqRemoveForceSit", 1, entity.id())
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
		callScript = "p.edible", callScriptArgs = { occupantId, seatindex, entity.id(), emptyslots, p.sbqData.locations[location].maxNested or p.sbqData.locations[location].max }
	} )

	if edibles[1] == nil then
		if loungeables[1] == nil then -- now just making sure the prey doesn't belong to another loungable now
			p.occupant[seatindex].id = occupantId
			p.occupant[seatindex].location = location
			p.forceSeat( occupantId, seatindex)
			p.refreshList = true
			p.updateOccupants(0)
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] )
	p.occupant[seatindex].id = occupantId
	p.occupant[seatindex].species = species
	p.occupant[seatindex].location = location
	p.forceSeat( occupantId, seatindex )
	p.refreshList = true
	p.updateOccupants(0)
	return true
end

function p.uneat( occupantId )
	if occupantId == nil or not world.entityExists(occupantId) then return end
	world.sendEntityMessage( occupantId, "sbqClearDrawables")
	world.sendEntityMessage( occupantId, "applyStatusEffect", "sbqRemoveBellyEffects")
	world.sendEntityMessage( occupantId, "primaryItemLock", false)
	world.sendEntityMessage( occupantId, "altItemLock", false)
	p.unForceSeat( occupantId )
	if not p.lounging[occupantId] then return end

	local seatindex = p.lounging[occupantId].index
	local occupantData = p.lounging[occupantId]
	if world.entityType(occupantId) == "player" then
		world.sendEntityMessage(occupantId, "sbqOpenInterface", "sbqClose")
	end

	if occupantData.species ~= nil then
		table.insert(p.preyRecepients, {
			vehicle = world.spawnVehicle( occupantData.species, p.localToGlobal({ occupantData.victimAnim.last.x or 0, occupantData.victimAnim.last.y or 0}), { driver = occupantId, settings = occupantData.smolPreyData.settings, uneaten = true, startState = occupantData.smolPreyData.state, layer = occupantData.smolPreyData.layer } ),
			owner = occupantId
		})
	else
		world.sendEntityMessage( occupantId, "sbqRemoveStatusEffects", p.config.predStatusEffects)
		world.sendEntityMessage( occupantId, "sbqPredatorDespawned" ) -- to clear the current data for players
	end
	world.sendEntityMessage( occupantId, "sbqLight", nil )

	p.refreshList = true
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
	if total > emptyslots or (total > locationslots and locationslots ~= -1) then return false end
	if p.stateconfig[p.state].edible then
		world.sendEntityMessage(source, "smolPreyData", seatindex,
			p.getSmolPreyData(
				p.settings,
				world.entityName( entity.id() ),
				p.state,
				p.partTags,
				p.seats[p.driverSeat].smolPreyData
			),
			entity.id()
		)

		local nextSlot = 1
		for i = 1, p.occupantSlots do
			if p.occupant[i].id ~= nil then
				local location = p.occupant[i].location
				local massMultiplier = 0

				if location == "nested" then
					location = p.occupant[i].nestedPreyData.ownerLocation
				end
				massMultiplier = p.sbqData.locations[location].mass or 0

				if p.occupant[i].location == "nested" then
					massMultiplier = massMultiplier * p.occupant[i].nestedPreyData.massMultiplier
				end

				local occupantData = sb.jsonMerge(p.occupant[i], {
					location = "nested",
					visible = false,
					nestedPreyData = {
						owner = p.driver,
						location = p.occupant[i].location,
						massMultiplier = massMultiplier,
						digest = p.sbqData.locations[location].digest,
						nestedPreyData = p.occupant[i].nestedPreyData
					}
				})
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
		if world.entityExists(recepient.vehicle) then
			for i = 0, p.occupantSlots do
				if p.occupant[i].id ~= nil and p.occupant[i].location == "nested" and p.occupant[i].nestedPreyData.owner == recepient.owner then

					local occupantData = sb.jsonMerge(p.occupant[i], {
						location = p.occupant[i].nestedPreyData.location,
						visible = false,
						nestedPreyData = p.occupant[i].nestedPreyData.nestedPreyData
					})
					world.sendEntityMessage( recepient.vehicle, "addPrey", nextSlot, occupantData)

					p.occupant[i] = p.clearOccupant(i)
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
	if p.occupants[location] >= p.sbqData.locations[location].max then return false end
	local maxNested = p.sbqData.locations[location].maxNested or ( p.sbqData.locations[location].max - 1 )
	local nestCount = 0
	for i = 0, p.occupantSlots do
		if p.occupant[i].location == "nested" and p.occupant[i].nestedPreyData.owner == args.id then
			nestCount = nestCount + 1
		end
	end
	if nestCount > maxNested and (not maxNested == -1) then return false end
	p.lounging[args.id].location = location
	return true
end

function p.findFirstOccupantIdForLocation(location)
	for i = 0, p.occupantSlots do
		if p.occupant[i].location == location then
			return p.occupant[i].id, i
		end
	end
end


function p.locationFull(location)
	if p.occupants.total == p.occupants.maximum then
		return true
	else
		return p.occupants[location] == p.sbqData.locations[location].max
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
		world.sendEntityMessage( args.id, "sbqApplyStatusEffects", statuses )
		return true, function()
			p.justAte = nil
			p.transitionLock = false
			p.checkDrivingInteract()
			if sound then animator.playSound( sound ) end
		end
	else
		return false
	end
end

function p.doEscape(args, statuses, afterstatuses )
	local victim = args.id
	if not victim then return false end -- could be part of above but no need to log an error here

	vehicle.setInteractive( false )
	world.sendEntityMessage( victim, "sbqApplyStatusEffects", statuses )
	p.transitionLock = true
	return true, function()
		p.transitionLock = false
		p.checkDrivingInteract()
		p.uneat( victim )
		world.sendEntityMessage( victim, "sbqApplyStatusEffects", afterstatuses )
	end
end

function p.applyStatusLists()
	for i = 0, p.occupantSlots do
		if p.occupant[i].id ~= nil and world.entityExists(p.occupant[i].id) then
			if not p.weirdFixFrame then
				vehicle.setLoungeEnabled(p.occupant[i].seatname, true)
			end
			p.loopedMessage( p.occupant[i].seatname.."NonHostile", p.occupant[i].id, "sbqMakeNonHostile")
			p.loopedMessage( p.occupant[i].seatname.."StatusEffects", p.occupant[i].id, "sbqApplyStatusEffects", {p.occupant[i].statList} )
			p.loopedMessage( p.occupant[i].seatname.."ForceSeat", p.occupant[i].id, "sbqForceSit", {{index=i, source=entity.id()}})
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
	for location, data in pairs(p.sbqData.locations) do
		p.occupants[location] = 0
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
					mass = mass * p.occupant[i].nestedPreyData.massMultiplier
					if world.entityExists(owner) and p.lounging[owner] ~= nil then
						location = p.lounging[owner].location
						p.occupant[i].nestedPreyData.ownerLocation = location

						p.resetTransformationGroup(seatname.."Position")
						p.translateTransformationGroup(seatname.."Position", p.globalToLocal(world.entityPosition(owner)))
					else
						if p.occupant[i].nestedPreyData.nestedPreyData ~= nil then
							p.occupant[i].nestedPreyData = p.occupant[i].nestedPreyData.nestedPreyData
						else
							location = p.occupant[i].nestedPreyData.ownerLocation
							p.occupant[i].location = location
						end
					end
				end

				if location ~= nil and p.sbqData.locations[location] ~= nil then
					p.occupants[location] = p.occupants[location] + 1

					massMultiplier = p.sbqData.locations[location].mass or 0

					p.occupants.mass = p.occupants.mass + mass * massMultiplier

					if p.sbqData.locations[location].transformGroups ~= nil then
						p.copyTransformationFromGroupsToGroup(p.sbqData.locations[location].transformGroups, seatname.."Position")
					end
				end

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
						"sbqOpenInterface", {"sbqIndicatorHud",
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
	p.setPartTag( "global", "totaloccupants", tostring(p.occupants.total) )
	for location, data in pairs(p.sbqData.locations) do
		if data.combine ~= nil then -- this doesn't work for sided stuff, but I don't think we'll ever need combine for sided stuff
			for _, combine in ipairs(data.combine) do
				p.occupants[location] = p.occupants[location] + p.occupants[combine]
				p.occupants[combine] = p.occupants[location]
			end
		end
		if data.sided then
			if p.direction >= 1 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
				p.setPartTag( "global", location.."FrontOccupants", tostring(p.occupants[location.."R"]) )
				p.setPartTag( "global", location.."BackOccupants", tostring(p.occupants[location.."L"]) )
			else
				p.setPartTag( "global", location.."BackOccupants", tostring(p.occupants[location.."R"]) )
				p.setPartTag( "global", location.."FrontOccupants", tostring(p.occupants[location.."L"]) )
			end
		else
			p.setPartTag( "global", location.."occupants", tostring(p.occupants[location]) )
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

	local bellyEffect = p.settings.bellyEffect or "sbqRemoveBellyEffects"
	local hungereffect = 0
	if (bellyEffect == "sbqDigest") or (bellyEffect == "sbqSoftDigest") then
		hungereffect = 1
	end
	if p.settings.displayDigest then
		if p.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
			bellyEffect = p.config.bellyDisplayStatusEffects[bellyEffect]
		end
	end

	local powerMultiplier = math.log(p.seats[p.driverSeat].controls.powerMultiplier) + 1

	for i = 0, p.occupantSlots do
		local eid = p.occupant[i].id
		if eid and world.entityExists(eid) and (not (i == 0 and not p.includeDriver)) then
			local health = world.entityHealth(eid)
			local light = p.sbqData.lights.prey
			light.position = world.entityPosition( eid )
			world.sendEntityMessage( eid, "sbqLight", light )

			if p.occupant[i].location == "nested" then -- to make nested prey use the belly effect of the one they're in
				local owner = p.occupant[i].nestedPreyData.owner
				local settings = p.lounging[owner].smolPreyData.settings or {}
				local status = settings.bellyEffect or "sbqRemoveBellyEffects"
				local powerMultiplier = math.log(p.lounging[owner].controls.powerMultiplier) + 1
				if p.occupant[i].nestedPreyData.digest then
					world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, owner)
				end
			elseif p.sbqData.locations[p.occupant[i].location].digest then
				if (p.settings.bellySounds == true) then p.randomTimer( "gurgle", 1.0, 8.0, function() animator.playSound( "digest" ) end ) end
				local hunger_change = (hungereffect * powerMultiplier * dt)/100
				if bellyEffect ~= nil and bellyEffect ~= "" then world.sendEntityMessage( eid, "applyStatusEffect", bellyEffect, powerMultiplier, entity.id() ) end
				if (p.settings.bellyEffect == "sbqSoftDigest") and health[1] <= 1 then hunger_change = 0 end
				if p.driver then
					world.sendEntityMessage( p.driver, "sbqAddHungerHealth", hunger_change)
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
			local struggling
			struggledata = p.stateconfig[p.state].struggle[p.occupant[struggler].location]
			if struggledata == nil or struggledata.directions == nil or struggledata.directions[movedir] == nil then
				movedir = nil
			else
				if struggledata.parts ~= nil then
					struggling = p.partsAreStruggling(struggledata.parts)
				end
				if (not struggling) and (struggledata.sided ~= nil) then
					local parts = struggledata.sided.rightParts
					if p.direction == -1 then
						parts = struggledata.sided.leftParts
					end
					struggling = p.partsAreStruggling(parts)
				end
			end
			if struggling then
				movedir = nil
			elseif config.getParameter("name") ~= "sbqEgg" then
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
		local prefix = struggledata.prefix or ""
		if struggledata.parts ~= nil then
			for _, part in ipairs(struggledata.parts) do
				animation[part] = prefix.."s_"..movedir
			end
		end
		if struggledata.sided ~= nil then
			local parts = struggledata.sided.rightParts
			if p.direction == -1 then
				parts = struggledata.sided.leftParts
			end
			for _, part in ipairs(parts) do
				animation[part] = prefix.."s_"..movedir
			end
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
	if chances ~= nil and chances.max == 0 then return true end
	return (p.settings.escapeModifier ~= "noEscape")
	and chances ~= nil and (chances.min ~= nil) and (chances.max ~= nil)
	and (math.random((chances.min + (p.settings.escapeDifficulty or 0)), (chances.min + (p.settings.escapeDifficulty or 0))) <= p.occupant[struggler].struggleCount)
	and ((not p.driving) or struggledata.directions[movedir].drivingEnabled)
end

function p.inedible(occupantId)
	return p.config.inedibleCreatures[world.entityType(occupantId)]
end

function p.removeOccupantsFromLocation(location)
	for i = 0, #p.occupant do
		if p.occupant[i].location == location then
			p.uneat(p.occupant[i].id)
		end
	end
end
