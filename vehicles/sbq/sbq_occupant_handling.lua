function sbq.forceSeat( occupantId, seatindex )
	if occupantId then
		vehicle.setLoungeEnabled("occupant"..seatindex, true)
		world.sendEntityMessage(occupantId, "sbqMakeNonHostile")
		world.sendEntityMessage( occupantId, "sbqForceSit", {index=seatindex, source=entity.id()})
	end
end

function sbq.unForceSeat(occupantId)
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "sbqRemoveForceSit", 1, entity.id())
	end
end

function sbq.eat( occupantId, location, force )
	local seatindex = sbq.occupants.total
	local emptyslots = sbq.occupantSlots - sbq.occupants.total
	if not sbq.includeDriver then
		seatindex = seatindex + 1
		emptyslots = emptyslots - 1
	end
	if seatindex > sbq.occupantSlots then return false end

	if not force and (occupantId == nil or sbq.entityLounging(occupantId) or sbq.inedible(occupantId) or sbq.locationFull(location)) then return false end -- don't eat self

	local loungeables = world.entityQuery( world.entityPosition(occupantId), 5, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "sbq.entityLounging", callScriptArgs = { occupantId }
	} )

	local edibles = world.entityQuery( world.entityPosition(occupantId), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "sbq.edible", callScriptArgs = { occupantId, seatindex, entity.id(), emptyslots, sbq.sbqData.locations[location].maxNested or sbq.sbqData.locations[location].max or 0, (sbq.settings.hammerspace and sbq.sbqData.locations[location].hammerspace and not sbq.settings.hammerspaceDisabled[location]) }
	} )
	if edibles[1] == nil then
		if loungeables[1] == nil then -- now just making sure the prey doesn't belong to another loungable now
			sbq.occupant[seatindex].id = occupantId
			sbq.occupant[seatindex].location = location
			sbq.forceSeat( occupantId, seatindex)
			sbq.refreshList = true
			sbq.updateOccupants(0)
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] )
	sbq.occupant[seatindex].id = occupantId
	sbq.occupant[seatindex].species = species
	sbq.occupant[seatindex].location = location
	sbq.forceSeat( occupantId, seatindex )
	sbq.refreshList = true
	sbq.updateOccupants(0)
	return true
end

function sbq.uneat( occupantId )
	if occupantId == nil or not world.entityExists(occupantId) then return end
	world.sendEntityMessage( occupantId, "sbqClearDrawables")
	world.sendEntityMessage( occupantId, "applyStatusEffect", "sbqRemoveBellyEffects")
	world.sendEntityMessage( occupantId, "primaryItemLock", false)
	world.sendEntityMessage( occupantId, "altItemLock", false)
	world.sendEntityMessage( occupantId, "sbqLight", nil )
	sbq.unForceSeat( occupantId )
	if not sbq.lounging[occupantId] then return end

	local seatindex = sbq.lounging[occupantId].index
	local occupantData = sbq.lounging[occupantId]
	if world.entityType(occupantId) == "player" then
		world.sendEntityMessage(occupantId, "sbqOpenInterface", "sbqClose")
	end

	if occupantData.species ~= nil then
		table.insert(sbq.preyRecepients, {
			vehicle = world.spawnVehicle( occupantData.species, sbq.localToGlobal({ occupantData.victimAnim.last.x or 0, occupantData.victimAnim.last.y or 0}), { driver = occupantId, settings = occupantData.smolPreyData.settings, uneaten = true, startState = occupantData.smolPreyData.state, layer = occupantData.smolPreyData.layer } ),
			owner = occupantId
		})
	else
		world.sendEntityMessage( occupantId, "sbqRemoveStatusEffects", sbq.config.predStatusEffects)
		world.sendEntityMessage( occupantId, "sbqPredatorDespawned", true ) -- to clear the current data for players
	end

	sbq.refreshList = true
	sbq.lounging[occupantId] = nil
	sbq.occupant[seatindex] = sbq.clearOccupant(seatindex)
	sbq.updateOccupants(0)
	return true
end

function sbq.edible( occupantId, seatindex, source, emptyslots, locationslots, hammerspace )
	if sbq.driver ~= occupantId then return false end
	local total = sbq.occupants.total
	if not sbq.includeDriver then
		total = total + 1
	end
	if total > emptyslots or (locationslots and total > locationslots and locationslots ~= -1 and not hammerspace) then return false end
	if sbq.stateconfig[sbq.state].edible then
		world.sendEntityMessage(source, "sbqSmolPreyData", seatindex,
			sbq.getSmolPreyData(
				sbq.settings,
				world.entityName( entity.id() ),
				sbq.state,
				sbq.partTags,
				sbq.seats[sbq.driverSeat].smolPreyData
			),
			entity.id()
		)

		local nextSlot = 1
		for i = 1, sbq.occupantSlots do
			if type(sbq.occupant[i].id) == "number" then
				local location = sbq.occupant[i].location
				local massMultiplier = 0

				if location == "nested" then
					location = sbq.occupant[i].nestedPreyData.ownerLocation
				end
				massMultiplier = sbq.sbqData.locations[location].mass or 0

				if sbq.occupant[i].location == "nested" then
					massMultiplier = massMultiplier * sbq.occupant[i].nestedPreyData.massMultiplier
				end

				local occupantData = sb.jsonMerge(sbq.occupant[i], {
					location = "nested",
					visible = false,
					nestedPreyData = {
						owner = sbq.driver,
						location = sbq.occupant[i].location,
						massMultiplier = massMultiplier,
						digest = sbq.sbqData.locations[location].digest,
						nestedPreyData = sbq.occupant[i].nestedPreyData
					}
				})
				world.sendEntityMessage( source, "addPrey", seatindex + nextSlot, occupantData)
				nextSlot = nextSlot+1
			end
		end
		return true
	end
end

sbq.preyRecepients = {}

function sbq.sendPreyTo()
	for j, recepient in ipairs(sbq.preyRecepients) do
		local nextSlot = 1
		if world.entityExists(recepient.vehicle) then
			for i = 0, sbq.occupantSlots do
				if type(sbq.occupant[i].id) == "number" and sbq.occupant[i].location == "nested" and sbq.occupant[i].nestedPreyData.owner == recepient.owner then
					local occupantData = sb.jsonMerge(sbq.occupant[i], {})

					occupantData.location = sbq.occupant[i].nestedPreyData.location
					occupantData.visible = false
					occupantData.nestedPreyData = sbq.occupant[i].nestedPreyData.nestedPreyData

					world.sendEntityMessage( recepient.vehicle, "addPrey", nextSlot, occupantData)

					sbq.occupant[i] = sbq.clearOccupant(i)
					nextSlot = nextSlot+1
				end
			end
			table.remove(sbq.preyRecepients, j)
		end
	end
end

sbq.sendAllPreyTo = nil
function sbq.sendAllPrey()
	if type(sbq.sendAllPreyTo) == "number" and world.entityExists(sbq.sendAllPreyTo) then
		local nextSlot = 1
		local i = 1
		if sbq.includeDriver then
			i = 0
		end
		for i = i, sbq.occupantSlots do
			if type(sbq.occupant[i].id) == "number" then
				sbq.occupant[i].visible = false
				world.sendEntityMessage(sbq.sendAllPreyTo, "addPrey", nextSlot, sbq.occupant[i])
				sbq.occupant[i] = sbq.clearOccupant(i)
				nextSlot = nextSlot + 1
			end
		end
		sbq.updateOccupants(0)
		sbq.onDeath()
	end
end

function sbq.firstNotLounging(entityaimed)
	for _, eid in ipairs(entityaimed) do
		if not sbq.entityLounging(eid) then
			return eid
		end
	end
end

function sbq.moveOccupantLocation(args, location)
	if not args.id or sbq.locationFull(location) then return false end
	local maxNested = sbq.sbqData.locations[location].maxNested or ( sbq.sbqData.locations[location].max - 1 )
	local nestCount = 0
	for i = 0, sbq.occupantSlots do
		if sbq.occupant[i].location == "nested" and sbq.occupant[i].nestedPreyData.owner == args.id then
			nestCount = nestCount + 1
		end
	end
	if (nestCount > maxNested and (not maxNested == -1)) and not (sbq.settings.hammerspace and sbq.sbqData.locations[location].hammerspace and not sbq.settings.hammerspaceDisabled[location]) then return false end
	sbq.lounging[args.id].location = location
	return true
end

function sbq.findFirstOccupantIdForLocation(location)
	for i = 0, sbq.occupantSlots do
		if sbq.occupant[i].location == location and type(sbq.occupant[i].id) == "number" and world.entityExists(sbq.occupant[i].id) then
			return sbq.occupant[i].id, i
		end
	end
end


function sbq.locationFull(location)
	if sbq.occupants.total == sbq.occupants.maximum then
		return true
	else
		if sbq.settings.hammerspace and sbq.sbqData.locations[location].hammerspace and not sbq.settings.hammerspaceDisabled[location] then return false end

		return sbq.occupants[location] >= sbq.sbqData.locations[location].max
	end
end

function sbq.locationEmpty(location)
	if sbq.occupants.total == 0 then
		return true
	else
		return sbq.occupants[location] == 0
	end
end

function sbq.doVore(args, location, statuses, sound )
	if sbq.eat( args.id, location ) then
		sbq.justAte = args.id
		vehicle.setInteractive( false )
		sbq.showEmote("emotehappy")
		sbq.transitionLock = true
		world.sendEntityMessage( args.id, "sbqApplyStatusEffects", statuses )
		return true, function()
			sbq.justAte = nil
			sbq.transitionLock = false
			sbq.checkDrivingInteract()
			if sound then animator.playSound( sound ) end
		end
	else
		return false
	end
end

function sbq.doEscape(args, statuses, afterstatuses )
	local victim = args.id
	if not victim then return false end -- could be part of above but no need to log an error here
	sbq.lounging[victim].location = "escaping"

	vehicle.setInteractive( false )
	world.sendEntityMessage( victim, "sbqApplyStatusEffects", statuses )
	sbq.transitionLock = true
	return true, function()
		sbq.transitionLock = false
		sbq.checkDrivingInteract()
		sbq.uneat( victim )
		world.sendEntityMessage( victim, "sbqApplyStatusEffects", afterstatuses )
	end
end

function sbq.applyStatusLists()
	for i = 0, sbq.occupantSlots do
		if type(sbq.occupant[i].id) == "number" and world.entityExists(sbq.occupant[i].id) then
			if not sbq.weirdFixFrame then
				vehicle.setLoungeEnabled(sbq.occupant[i].seatname, true)
			end
			sbq.loopedMessage( sbq.occupant[i].seatname.."NonHostile", sbq.occupant[i].id, "sbqMakeNonHostile")
			sbq.loopedMessage( sbq.occupant[i].seatname.."StatusEffects", sbq.occupant[i].id, "sbqApplyStatusEffects", {sbq.occupant[i].statList} )
			sbq.loopedMessage( sbq.occupant[i].seatname.."ForceSeat", sbq.occupant[i].id, "sbqForceSit", {{index=i, source=entity.id()}})
		else
			vehicle.setLoungeEnabled(sbq.occupant[i].seatname, false)
		end
	end
	sbq.weirdFixFrame = nil
end

function sbq.addStatusToList(index, status, power, source)
	sbq.occupant[index].statList[status] = {
		power = power or 1,
		source = source or entity.id()
	}
end

function sbq.removeStatusFromList(index, status)
	sbq.occupant[index].statList[status] = nil
end

function sbq.resetOccupantCount()
	sbq.occupantsPrev = sb.jsonMerge(sbq.occupants, {})
	sbq.occupants.total = 0
	for location, data in pairs(sbq.sbqData.locations) do
		sbq.occupants[location] = 0
	end
	sbq.occupants.fatten = sbq.settings.fatten or 0
	sbq.occupants.mass = 0
end

function sbq.updateOccupants(dt)
	sbq.sendPreyTo()
	sbq.resetOccupantCount()

	local lastFilled = true

	for i = 0, sbq.occupantSlots do
		if not (i == 0 and not sbq.includeDriver) then
			if type(sbq.occupant[i].id) == "number" and world.entityExists(sbq.occupant[i].id) then
				sbq.occupants.total = sbq.occupants.total + 1
				if not lastFilled and sbq.swapCooldown <= 0 then
					sbq.swapOccupants( i-1, i )
					i = i - 1
				end

				sbq.occupant[i].index = i
				local seatname = "occupant"..i
				sbq.occupant[i].seatname = seatname
				sbq.lounging[sbq.occupant[i].id] = sbq.occupant[i]
				sbq.seats[sbq.occupant[i].seatname] = sbq.occupant[i]
				sbq.occupant[i].occupantTime = sbq.occupant[i].occupantTime + dt

				local massMultiplier = 0
				local mass = sbq.occupant[i].controls.mass
				local location = sbq.occupant[i].location

				if location == "nested" then
					local owner = sbq.occupant[i].nestedPreyData.owner
					mass = mass * sbq.occupant[i].nestedPreyData.massMultiplier
					if world.entityExists(owner) and sbq.lounging[owner] ~= nil then
						location = sbq.lounging[owner].location
						sbq.occupant[i].nestedPreyData.ownerLocation = location

						sbq.resetTransformationGroup(seatname.."Position")
						sbq.translateTransformationGroup(seatname.."Position", sbq.globalToLocal(world.entityPosition(owner)))
					else
						if sbq.occupant[i].nestedPreyData.nestedPreyData ~= nil then
							sbq.occupant[i].nestedPreyData = sbq.occupant[i].nestedPreyData.nestedPreyData
						else
							location = sbq.occupant[i].nestedPreyData.ownerLocation
							sbq.occupant[i].location = location
						end
					end
				elseif location == "digesting" or location == "escaping" then
				elseif (location == nil) or (sbq.sbqData.locations[location] == nil) or ((sbq.sbqData.locations[location].max or 0) == 0) then
					sbq.uneat(sbq.occupant[i].id)
					return
				else
					sbq.occupants[location] = sbq.occupants[location] + 1

					massMultiplier = sbq.sbqData.locations[location].mass or 0

					if not sbq.settings.hammerspace then
						sbq.occupants.mass = sbq.occupants.mass + mass * massMultiplier
					end

					if sbq.sbqData.locations[location].transformGroups ~= nil then
						sbq.copyTransformationFromGroupsToGroup(sbq.sbqData.locations[location].transformGroups, seatname.."Position")
					end
				end

				if sbq.occupant[i].progressBarActive == true then
					sbq.occupant[i].progressBar = sbq.occupant[i].progressBar + (((math.log(sbq.occupant[i].controls.powerMultiplier)+1) * dt) * sbq.occupant[i].progressBarMultiplier)
					if sbq.occupant[i].progressBarMultiplier > 0 then
						sbq.occupant[i].progressBar = math.min(100, sbq.occupant[i].progressBar)
						if sbq.occupant[i].progressBar >= 100 and sbq.occupant[i].progressBarFinishFuncName ~= nil then
							sbq[sbq.occupant[i].progressBarFinishFuncName](i)
							sbq.occupant[i].progressBarActive = false
						end
					else
						sbq.occupant[i].progressBar = math.max(0, sbq.occupant[i].progressBar)
						if sbq.occupant[i].progressBar <= 0 and sbq.occupant[i].progressBarFinishFuncName ~= nil then
							sbq[sbq.occupant[i].progressBarFinishFuncName](i)
							sbq.occupant[i].progressBarActive = false
						end
					end
				end

				sbq.occupant[i].indicatorCooldown = sbq.occupant[i].indicatorCooldown - dt

				if world.entityType(sbq.occupant[i].id) == "player" and sbq.occupant[i].indicatorCooldown <= 0 then
					-- p.occupant[i].indicatorCooldown = 0.5
					local struggledata = (sbq.stateconfig[sbq.state].struggle or {})[location] or {}
					local directions = {}
					if not sbq.transitionLock and sbq.occupant[i].species ~= "sbqEgg" and sbq.occupant[i].location ~= "nested" then
						for dir, data in pairs(struggledata.directions or {}) do
							if data and (not sbq.driving or data.drivingEnabled) and ((data.settings == nil) or sbq.checkSettings(data.settings) ) then
								if dir == "front" then dir = ({"left","","right"})[sbq.direction+2] end
								if dir == "back" then dir = ({"right","","left"})[sbq.direction+2] end
								directions[dir] = data.indicate or "default"
							end
						end
					end
					local nested
					if sbq.occupant[i].location == "nested" then
						nested = "Nested"
					end

					sbq.loopedMessage(sbq.occupant[i].id.."-indicator", sbq.occupant[i].id, -- update quickly but minimize spam
						"sbqOpenInterface", {"sbqIndicatorHud",
						{
							owner = entity.id(),
							directions = directions,
							progress = {
								active = sbq.occupant[i].progressBarActive,
								color = sbq.occupant[i].progressBarColor,
								percent = sbq.occupant[i].progressBar,
								dx = (math.log(sbq.occupant[i].controls.powerMultiplier)+1) * sbq.occupant[i].progressBarMultiplier,
							},
							time = sbq.occupant[i].occupantTime,
							location = (sbq.sbqData.locations[location] or {}).name or nested or ""
						}
					})
				end

				lastFilled = true
			elseif type(sbq.occupant[i].id) == "number" and not world.entityExists(sbq.occupant[i].id) then
				sbq.occupant[i] = sbq.clearOccupant(i)
				sbq.refreshList = true
				lastFilled = false
			else
				lastFilled = false
				sbq.occupant[i] = sbq.clearOccupant(i)
			end
		end
	end
	sbq.swapCooldown = math.max(0, sbq.swapCooldown - 1)

	mcontroller.applyParameters({mass = sbq.movementParams.mass + sbq.occupants.mass})

	sbq.setOccupantTags()
end

sbq.expandQueue = {}
sbq.shrinkQueue = {}

function sbq.setOccupantTags()
	sbq.setPartTag( "global", "totalOccupants", tostring(sbq.occupants.total) )
	-- because of the fact that pairs feeds things in a random ass order we need to make sure these have tripped on every location *before* setting the occupancy tags or checking the expand/shrink queue
	for location, data in pairs(sbq.sbqData.locations) do
		if data.hammerspace and sbq.settings.hammerspace and not sbq.settings.hammerspaceDisabled[location] then
			if sbq.occupants[location] > (sbq.settings.hammerspaceLimits[location] or 1) then
				sbq.occupants[location] = (sbq.settings.hammerspaceLimits[location] or 1)
			end
		end

		if data.combine then
			for _, combine in ipairs(data.combine) do
				sbq.occupants[location] = sbq.occupants[location] + sbq.occupants[combine]
				sbq.occupants[combine] = sbq.occupants[location]
			end
		end

		if data.copy then
			local copyTable = {0}
			for _, copy in ipairs(data.copy) do
				table.insert(copyTable, sbq.occupants[copy])
			end
			sbq.occupants[location] = math.max(table.unpack(copyTable))
		end
	end

	for location, data in pairs(sbq.sbqData.locations) do
		if data.max ~= nil and sbq.occupants[location] > data.max then
			sbq.occupants[location] = data.max
		end

		if data.sided then
			local amount = math.min(data.max, math.max(sbq.occupants[location.."R"], sbq.occupants[location.."L"]))
			sbq.occupants[location] = amount
			if data.symmetrical then -- for when people want their balls and boobs to be the same size
				sbq.setPartTag( "global", location.."FrontOccupants", tostring(amount) )
				sbq.setPartTag( "global", location.."BackOccupants", tostring(amount) )

				if sbq.occupants[location] > sbq.occupantsPrev[location] then
					sbq.doAnims(sbq.expandQueue[location] or (sbq.stateconfig[sbq.state].expandAnims or {})[location])
				elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
					sbq.doAnims(sbq.shrinkQueue[location] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location])
				end

			else
				if sbq.direction > 0 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
					sbq.setPartTag( "global", location.."FrontOccupants", tostring(sbq.occupants[location.."R"]) )
					sbq.setPartTag( "global", location.."BackOccupants", tostring(sbq.occupants[location.."L"]) )

					if sbq.occupants[location.."R"] > sbq.occupantsPrev[location.."R"] then
						sbq.doAnims(sbq.expandQueue[location.."Front"] or (sbq.stateconfig[sbq.state].expandAnims or {})[location.."Front"])
					elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
						sbq.doAnims(sbq.shrinkQueue[location.."Front"] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location.."Front"])
					end

					if sbq.occupants[location.."L"] > sbq.occupantsPrev[location.."L"] then
						sbq.doAnims(sbq.expandQueue[location.."Back"] or (sbq.stateconfig[sbq.state].expandAnims or {})[location.."Back"])
					elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
						sbq.doAnims(sbq.shrinkQueue[location.."Back"] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location.."Back"])
					end
				else
					sbq.setPartTag( "global", location.."BackOccupants", tostring(sbq.occupants[location.."R"]) )
					sbq.setPartTag( "global", location.."FrontOccupants", tostring(sbq.occupants[location.."L"]) )

					if sbq.occupants[location.."L"] > sbq.occupantsPrev[location.."L"] then
						sbq.doAnims(sbq.expandQueue[location.."Front"] or (sbq.stateconfig[sbq.state].expandAnims or {})[location.."Front"])
					elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
						sbq.doAnims(sbq.shrinkQueue[location.."Front"] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location.."Front"])
					end

					if sbq.occupants[location.."R"] > sbq.occupantsPrev[location.."R"] then
						sbq.doAnims(sbq.expandQueue[location.."Back"] or (sbq.stateconfig[sbq.state].expandAnims or {})[location.."Back"])
					elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
						sbq.doAnims(sbq.shrinkQueue[location.."Back"] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location.."Back"])
					end
				end
			end
		else
			sbq.setPartTag( "global", location.."Occupants", tostring(math.min(sbq.occupants[location], sbq.sbqData.locations[location].max or sbq.occupants[location])) )

			if sbq.totalTimeAlive > 0.5 then
				if sbq.occupants[location] > sbq.occupantsPrev[location] then
					sbq.doAnims(sbq.expandQueue[location] or (sbq.stateconfig[sbq.state].expandAnims or {})[location])
				elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
					sbq.doAnims(sbq.shrinkQueue[location] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location])
				end
			end
		end

		sbq.expandQueue[location] = nil
		sbq.shrinkQueue[location] = nil
	end
end

function sbq.swapOccupants(a, b)
	local A = sbq.occupant[a]
	local B = sbq.occupant[b]
	sbq.occupant[a] = B
	sbq.occupant[b] = A

	sbq.swapCooldown = 10 -- p.unForceSeat and p.forceSeat are asynchronous, without some cooldown it'll try to swap multiple times and bad things will happen
end

function sbq.entityLounging( entity )
	for i = 0, sbq.occupantSlots do
		if entity == sbq.occupant[i].id then return true end
	end
	return false
end

function sbq.doBellyEffects(dt)
	if sbq.occupants.total <= 0 then return end

	local bellyEffect = sbq.settings.bellyEffect or "sbqRemoveBellyEffects"
	local hungereffect = 0
	if (bellyEffect == "sbqDigest") or (bellyEffect == "sbqSoftDigest") then
		hungereffect = 1
	end
	if sbq.settings.displayDigest then
		if sbq.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
			bellyEffect = sbq.config.bellyDisplayStatusEffects[bellyEffect]
		end
	end

	local powerMultiplier = math.log(sbq.seats[sbq.driverSeat].controls.powerMultiplier) + 1

	for i = 0, sbq.occupantSlots do
		local eid = sbq.occupant[i].id
		if type(eid) == "number" and world.entityExists(eid) and (not (i == 0 and not sbq.includeDriver)) then
			local health = world.entityHealth(eid)
			local light = sbq.sbqData.lights.prey
			if light ~= nil then
				local lightPosition
				if light.position ~= nil then
					lightPosition = sbq.localToGlobal(light.position)
				else
					lightPosition = world.entityPosition( eid )
				end
				world.sendEntityMessage( eid, "sbqLight", sb.jsonMerge(light, {position = lightPosition}) )
			end

			if sbq.occupant[i].location == "nested" then -- to make nested prey use the belly effect of the one they're in
				local owner = sbq.occupant[i].nestedPreyData.owner
				local settings = sbq.lounging[owner].smolPreyData.settings or {}
				local status = settings.bellyEffect or "sbqRemoveBellyEffects"
				local powerMultiplier = math.log(sbq.lounging[owner].controls.powerMultiplier) + 1
				if sbq.occupant[i].nestedPreyData.digest then
					world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, owner)
				end
			elseif sbq.occupant[i].location == "digesting" or (sbq.sbqData.locations[sbq.occupant[i].location] or {}).digest then
				if (sbq.settings.bellySounds == true) then sbq.randomTimer( "gurgle", 1.0, 8.0, function() animator.playSound( "digest" ) end ) end
				local hunger_change = (hungereffect * powerMultiplier * dt)/100
				if bellyEffect ~= nil and bellyEffect ~= "" then world.sendEntityMessage( eid, "applyStatusEffect", bellyEffect, powerMultiplier, entity.id() ) end
				if (sbq.settings.bellyEffect == "sbqSoftDigest") and health[1] <= 1 then hunger_change = 0 end
				if sbq.driver then
					world.sendEntityMessage( sbq.driver, "sbqAddHungerHealth", hunger_change)
				end
				sbq.hunger = math.min(100, sbq.hunger + hunger_change)

				sbq.extraBellyEffects(i, eid, health, bellyEffect)
			else
				sbq.otherLocationEffects(i, eid, health, bellyEffect, sbq.occupant[i].location, powerMultiplier )
			end
		end
	end
end

function sbq.validStruggle(struggler, dt)
	sbq.occupant[struggler].bellySettleDownTimer = math.max( 0, sbq.occupant[struggler].bellySettleDownTimer - dt)
	if (sbq.occupant[struggler].seatname == sbq.driverSeat) and not sbq.includeDriver then return end
	local movedir = sbq.getSeatDirections( sbq.occupant[struggler].seatname )
	if not (sbq.occupant[struggler].bellySettleDownTimer <= 0) then return end
	if not movedir then sbq.occupant[struggler].struggleTime = math.max( 0, sbq.occupant[struggler].struggleTime - dt) return end

	local struggling
	struggledata = sbq.stateconfig[sbq.state].struggle[sbq.occupant[struggler].location]

	if (struggledata == nil or struggledata.directions == nil or struggledata.directions[movedir] == nil) then return end

	if struggledata.parts ~= nil then
		struggling = sbq.partsAreStruggling(struggledata.parts)
	end
	if (not struggling) and (struggledata.sided ~= nil) then
		local parts = struggledata.sided.rightParts
		if sbq.direction == -1 then
			parts = struggledata.sided.leftParts
		end
		struggling = sbq.partsAreStruggling(parts)
	end

	if struggling then return end

	if config.getParameter("name") ~= "sbqEgg" then
		if sbq.occupant[struggler].species ~= nil and sbq.config.speciesStrugglesDisabled[sbq.occupant[struggler].species] then
			if not sbq.driving then
				sbq.occupant[struggler].struggleTime = math.max(0, sbq.occupant[struggler].struggleTime + dt)
				if sbq.occupant[struggler].struggleTime > 1 then
					sbq.letout(sbq.occupant[struggler].id)
				end
			end
			return
		end
	end

	return movedir, struggledata
end

function sbq.handleStruggles(dt)
	if sbq.transitionLock then return end
	local struggler = -1
	local struggledata
	local movedir = nil

	while (movedir == nil) and struggler < sbq.occupantSlots do
		struggler = struggler + 1
		movedir, struggledata = sbq.validStruggle(struggler, dt)
	end

	if movedir == nil then return end -- invalid struggle

	local strugglerId = sbq.occupant[struggler].id

	if struggledata.script ~= nil then
		local statescript = state[sbq.state][struggledata.script]
		if statescript ~= nil then
			statescript({id = strugglerId, direction = movedir})
		else
			sb.logError("no script named: ["..struggledata.script.."] in state: ["..sbq.state.."]")
		end
	end

	if sbq.struggleChance(struggledata, struggler, movedir) then
		sbq.occupant[struggler].struggleTime = 0
		sbq.doTransition( struggledata.directions[movedir].transition, {direction = movedir, id = strugglerId} )
	else

		local animation = {offset = struggledata.directions[movedir].offset}
		local prefix = struggledata.prefix or ""
		local parts = struggledata.parts
		if struggledata.sided ~= nil then
			parts = struggledata.sided.rightParts
			if sbq.direction == -1 then
				parts = struggledata.sided.leftParts
			end
		end

		local time = dt
		if parts ~= nil then
			for _, part in ipairs(parts) do
				animation[part] = prefix.."s_"..movedir
			end
			for _, part in ipairs(struggledata.additionalParts or {}) do -- these are parts that it doesn't matter if it struggles or not, meant for multiple parts triggering the animation but never conflicting since it doesn't check if its struggling already or not
				animation[part] = prefix.."s_"..movedir
			end
			sbq.doAnims(animation)
			for _, part in ipairs(parts) do
				local newtime = sbq.animStateData[part.."State"].animationState.cycle
				if newtime > time then
					time = newtime
				end
			end
		end
		sbq.occupant[struggler].bellySettleDownTimer = time
		sbq.occupant[struggler].struggleTime = sbq.occupant[struggler].struggleTime + time

		if not sbq.movement.animating then
			sbq.doAnims( struggledata.directions[movedir].animation or struggledata.animation )
		else
			sbq.doAnims( struggledata.directions[movedir].animationWhenMoving or struggledata.animationWhenMoving )
		end

		if struggledata.directions[movedir].victimAnimation then
			local id = strugglerId
			if struggledata.directions[movedir].victimAnimLocation ~= nil then
				id = sbq.findFirstOccupantIdForLocation(struggledata.directions[movedir].victimAnimLocation)
			end
			sbq.doVictimAnim( id, struggledata.directions[movedir].victimAnimation, (struggledata.parts[1] or "body").."State" )
		end

		local sound = struggledata.sound
		if struggledata.directions[movedir].sound ~= nil then
			sound = struggledata.directions[movedir].sound
		end
		animator.playSound( sound or "struggle" )
	end
end

function sbq.struggleChance(struggledata, struggler, movedir)
	local chances = struggledata.chances
	if struggledata.directions[movedir].chances ~= nil then
		chances = struggledata.directions[movedir].chances
	end
	if chances ~= nil and chances.max == 0 then return true end
	return (not sbq.settings.impossibleEscape)
	and chances ~= nil and (chances.min ~= nil) and (chances.max ~= nil)
	and (math.random(math.floor(chances.min * 2^((sbq.settings.escapeDifficulty or 0)/5)), math.ceil(chances.max * 2^((sbq.settings.escapeDifficulty or 0)/5))) <= (sbq.occupant[struggler].struggleTime or 0))
	and ((not sbq.driving) or struggledata.directions[movedir].drivingEnabled)
end

function sbq.inedible(occupantId)
	return sbq.config.inedibleCreatures[world.entityType(occupantId)]
end

function sbq.removeOccupantsFromLocation(location)
	for i = 0, #sbq.occupant do
		if sbq.occupant[i].location == location then
			sbq.uneat(sbq.occupant[i].id)
		end
	end
end
