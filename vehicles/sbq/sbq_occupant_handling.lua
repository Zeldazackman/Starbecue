function sbq.forceSeat( occupantId, seatindex )
	if occupantId then
		vehicle.setLoungeEnabled("occupant"..seatindex, true)
		world.sendEntityMessage( occupantId, "sbqForceSit", {index=seatindex, source=entity.id()})
	end
end

function sbq.unForceSeat(occupantId)
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "sbqRemoveForceSit", 1, entity.id())
	end
end

function sbq.eat( occupantId, location, size, voreType, force )
	local seatindex = sbq.occupants.total + sbq.startSlot
	local emptyslots = sbq.occupantSlots - sbq.occupants.total - sbq.startSlot
	if seatindex > sbq.occupantSlots then return false end
	local full, locationslots = sbq.locationFull(location)

	if (not occupantId) or (not world.entityExists(occupantId))
	or ((full or ((size or 1) > locationslots) or sbq.entityLounging(occupantId) or sbq.inedible(occupantId)) and not force)
	then return false end -- don't eat self

	local loungeables = world.entityQuery( world.entityPosition(occupantId), 5, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "sbq.entityLounging", callScriptArgs = { occupantId }
	} )

	local edibles = world.entityQuery( world.entityPosition(occupantId), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "sbq.edible", callScriptArgs = { occupantId, seatindex, entity.id(), emptyslots, sbq.sbqData.locations[location].maxNested or locationslots}
	} )
	if edibles[1] == nil then
		if loungeables[1] == nil then -- now just making sure the prey doesn't belong to another loungable now
			sbq.occupant[seatindex].id = occupantId
			sbq.occupant[seatindex].location = location
			sbq.occupant[seatindex].size = size or 1
			sbq.occupant[seatindex].entryType = voreType
			world.sendEntityMessage( occupantId, "sbqMakeNonHostile")
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
	sbq.occupant[seatindex].size = size or 1
	sbq.occupant[seatindex].entryType = voreType
	world.sendEntityMessage( occupantId, "sbqMakeNonHostile")
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

	if occupantData.species ~= nil and occupantData.smolPreyData ~= nil then
		if type(occupantData.smolPreyData.id) == "number" and world.entityExists(occupantData.smolPreyData.id) then
			world.sendEntityMessage(occupantData.smolPreyData.id, "uneaten")
		else
			world.spawnVehicle( occupantData.species, sbq.localToGlobal({ occupantData.victimAnim.last.x or 0, occupantData.victimAnim.last.y or 0}), { driver = occupantId, settings = occupantData.smolPreyData.settings, uneaten = true, startState = occupantData.smolPreyData.state, layer = occupantData.smolPreyData.layer })
		end
	else
		world.sendEntityMessage( occupantId, "sbqRemoveStatusEffects", sbq.config.predStatusEffects)
		world.sendEntityMessage( occupantId, "sbqPredatorDespawned", true ) -- to clear the current data for players
	end
	sbq.refreshList = true
	sbq.lounging[occupantId] = nil
	sbq.occupant[seatindex] = sbq.clearOccupant(seatindex)
	world.sendEntityMessage(entity.id(), "sbqRestoreDamageTeam")
	sbq.updateOccupants(0)
	return true
end

function sbq.edible( occupantId, seatindex, source, emptyslots, locationslots )
	if sbq.driver ~= occupantId then return false end

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
		sbq.isNested = true
		sbq.scaleTransformationGroup("globalScale", {0,0})
		return true
	end
end

sbq.sendAllPreyTo = nil
function sbq.sendAllPrey()
	if type(sbq.sendAllPreyTo) == "number" and world.entityExists(sbq.sendAllPreyTo) then
		for i = sbq.startSlot, sbq.occupantSlots do
			if type(sbq.occupant[i].id) == "number" then
				sbq.occupant[i].visible = false
				if sbq.digestSendPrey then
					world.sendEntityMessage(sbq.sendAllPreyTo, "addDigestPrey", sbq.occupant[i], sbq.driver)
				else
					world.sendEntityMessage(sbq.sendAllPreyTo, "addPrey", sbq.occupant[i])
				end
				sbq.occupant[i] = sbq.clearOccupant(i)
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
	local full, locationslots = sbq.locationFull(location)
	if not args.id or full then return false end

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
	if sbq.occupants.total >= sbq.occupants.maximum then
		return true, 0
	else
		local emptyslots = sbq.occupants.maximum - sbq.occupants.total

		if sbq.settings.hammerspace and sbq.sbqData.locations[location].hammerspace
		and not sbq.settings[location.."HammerspaceDisabled"] then
			return false, emptyslots
		end
		if (sbq.sbqData.locations[location].combined or sbq.sbqData.locations[location].combine)
		and ((sbq.actualOccupants[location]+(sbq.settings[location.."VisualMin"] or 0)) < (sbq.settings[location.."VisualMax"] or sbq.sbqData.locations[location].max))
		and (sbq.occupants[location] < sbq.sbqData.locations[location].max)
		then
			return false, math.min(emptyslots,(sbq.settings[location.."VisualMax"] or sbq.sbqData.locations[location].max) - (sbq.actualOccupants[location]+(sbq.settings[location.."VisualMin"] or 0)))
		end

		return (sbq.occupants[location] >= (sbq.settings[location.."VisualMax"] or sbq.sbqData.locations[location].max)), math.min(emptyslots,(sbq.settings[location.."VisualMax"] or sbq.sbqData.locations[location].max) - (sbq.occupants[location]))
	end
end

function sbq.locationEmpty(location)
	if sbq.occupants.total == 0 then
		return true
	else
		return sbq.occupants[location] == 0
	end
end

function sbq.doVore(args, location, statuses, sound, voreType )
	if sbq.isNested then return false end
	local location = location
	if sbq.sbqData.locations[location].sided then
		if sbq.direction > 0 then
			if not sbq.locationFull(location.."L") then
				location = location.."L"
			elseif not sbq.locationFull(location.."R") then
				location = location.."R"
			else
				return false
			end
		else
			if not sbq.locationFull(location.."R") then
				location = location.."R"
			elseif not sbq.locationFull(location.."L") then
				location = location.."L"
			else
				return false
			end
		end
	end
	if sbq.eat( args.id, location, args.size, voreType ) then
		sbq.justAte = args.id
		vehicle.setInteractive( false )
		sbq.showEmote("emotehappy")
		sbq.transitionLock = true
		world.sendEntityMessage( args.id, "sbqApplyStatusEffects", statuses )

		local settings = {
			voreType = voreType or "default",
			predator = sbq.species,
			location = location,
			entryType = voreType
		}
		local entityType = world.entityType(args.id)
		local sayLine = entityType == "npc" or entityType == "player" and type(sbq.driver) == "number" and world.entityExists(sbq.driver)

		if sayLine then world.sendEntityMessage( args.id, "sbqSayRandomLine", sbq.driver, sb.jsonMerge(sbq.settings, settings), {"vored"}, true ) end

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

function sbq.doEscape(args, statuses, afterstatuses, voreType )
	if sbq.isNested then return false end

	local victim = args.id
	if not victim then return false end -- could be part of above but no need to log an error here
	local location = sbq.lounging[victim].location

	local settings = sb.jsonMerge(sbq.lounging[victim].visited,{
		voreType = voreType or "default",
		struggleTrigger = args.struggleTrigger,
		location = location,
		digesting = sbq.lounging[victim].digesting,
		digested = sbq.lounging[victim].digested,
		cumDigesting = sbq.lounging[victim].cumDigesting,
		egged = sbq.lounging[victim].egged,
		transformed = sbq.lounging[victim].transformed,
		progressBarType = sbq.lounging[victim].progressBarType
	})
	local entityType = world.entityType(args.id)
	local sayLine = entityType == "npc" or entityType == "player" and type(sbq.driver) == "number" and world.entityExists(sbq.driver)

	if sayLine then world.sendEntityMessage( sbq.driver, "sbqSayRandomLine", args.id, settings, {"letout"}, true ) end
	sbq.lounging[victim].location = "escaping"

	vehicle.setInteractive( false )
	world.sendEntityMessage( victim, "sbqApplyStatusEffects", statuses )
	sbq.transitionLock = true
	return true, function()
		if sayLine then world.sendEntityMessage( args.id, "sbqSayRandomLine", sbq.driver, sb.jsonMerge(sbq.settings, settings), {"escape"}, false) end
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
	sbq.occupants.totalSize = 0
	for location, data in pairs(sbq.sbqData.locations) do
		sbq.occupants[location] = sbq.settings[location.."VisualMin"] or 0
	end
	sbq.occupants.mass = 0
end

sbq.addPreyQueue = {}
function sbq.recievePrey()
	for i, prey in ipairs(sbq.addPreyQueue) do
		local seatindex = sbq.occupants.total + sbq.startSlot + i - 1
		if seatindex > sbq.occupantSlots then break end
		sbq.occupant[seatindex] = prey
	end
	sbq.addPreyQueue = {}
end

sbq.actualOccupants = {}
function sbq.updateOccupants(dt)
	sbq.resetOccupantCount()

	local lastFilled = true

	for i = sbq.startSlot, sbq.occupantSlots do
		if type(sbq.occupant[i].id) == "number" and world.entityExists(sbq.occupant[i].id) then
			sbq.occupants.total = sbq.occupants.total + 1
			if not lastFilled and sbq.swapCooldown <= 0 then
				sbq.swapOccupants(i - 1, i)
				i = i - 1
			end

			sbq.occupant[i].index = i
			local seatname = "occupant" .. i
			sbq.occupant[i].seatname = seatname
			sbq.lounging[sbq.occupant[i].id] = sbq.occupant[i]
			sbq.seats[sbq.occupant[i].seatname] = sbq.occupant[i]
			sbq.occupant[i].occupantTime = sbq.occupant[i].occupantTime + dt

			local massMultiplier = 0
			local mass = sbq.occupant[i].controls.mass
			local location = sbq.occupant[i].location

			if location == "digesting" or location == "escaping" then
			elseif (location == nil) or (sbq.sbqData.locations[location] == nil) or
				((sbq.sbqData.locations[location].max or 0) == 0) then
				sbq.uneat(sbq.occupant[i].id)
				return
			else
				sbq.occupant[i].visited[location .. "Visited"] = true
				sbq.occupant[i].visited[location .. "Time"] = (sbq.occupant[i].visited[location .. "Time"] or 0) + dt

				sbq.occupants[location] = sbq.occupants[location] + (sbq.occupant[i].size * sbq.occupant[i].sizeMultiplier)
				sbq.occupants.totalSize = sbq.occupants.totalSize + sbq.occupants[location]
				massMultiplier = sbq.sbqData.locations[location].mass or 0

				sbq.occupants.mass = sbq.occupants.mass + mass * massMultiplier

				if sbq.sbqData.locations[location].transformGroups ~= nil then
					sbq.copyTransformationFromGroupsToGroup(sbq.sbqData.locations[location].transformGroups, seatname .. "Position")
				end
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
	sbq.swapCooldown = math.max(0, sbq.swapCooldown - 1)

	mcontroller.applyParameters({mass = sbq.movementParams.mass + sbq.occupants.mass})

	for location, occupancy in pairs(sbq.occupants) do
		sbq.actualOccupants[location] = math.floor(occupancy+0.4)
	end

	sbq.setOccupantTags()
end

sbq.expandQueue = {}
sbq.shrinkQueue = {}

function sbq.setOccupantTags()
	if sbq.occupants.total ~= sbq.occupantsPrev.total then sbq.setPartTag( "global", "totalOccupants", tostring(sbq.occupants.total) ) end
	-- because of the fact that pairs feeds things in a random ass order we need to make sure these have tripped on every location *before* setting the occupancy tags or checking the expand/shrink queue
	for location, data in pairs(sbq.sbqData.locations) do
		local max = sbq.settings[location.."VisualMax"] or data.max
		local min = sbq.settings[location.."VisualMin"] or data.minVisual
		if type(max) == "number" and sbq.occupants[location] > max then
			sbq.occupants[location] = max
		elseif type(min) == "number" and sbq.occupants[location] < min then
			sbq.occupants[location] = min
		end
	end
	for location, data in pairs(sbq.sbqData.locations) do
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
		sbq.occupants[location] = math.floor((sbq.occupants[location] or 0)+0.4)
	end

	for location, data in pairs(sbq.sbqData.locations) do
		if data.sided then
			local amount = math.min(data.max, math.max(sbq.occupants[location.."R"], sbq.occupants[location.."L"]))
			sbq.occupants[location] = amount
			if data.symmetrical then -- for when people want their balls and boobs to be the same size
				if sbq.occupants[location] ~= sbq.occupantsPrev[location] then
					sbq.setPartTag( "global", location.."FrontOccupants", tostring(amount) )
					sbq.setPartTag( "global", location.."BackOccupants", tostring(amount) )
				end

				if sbq.occupants[location] > sbq.occupantsPrev[location] then
					sbq.doAnims(sbq.expandQueue[location] or (sbq.stateconfig[sbq.state].expandAnims or {})[location])
				elseif sbq.occupants[location] < sbq.occupantsPrev[location] then
					sbq.doAnims(sbq.shrinkQueue[location] or (sbq.stateconfig[sbq.state].shrinkAnims or {})[location])
				end

			else
				if sbq.direction > 0 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
					if sbq.occupants[location.."R"] ~= sbq.occupantsPrev[location.."R"] or sbq.direction ~= sbq.prevDirection then sbq.setPartTag( "global", location.."FrontOccupants", tostring(sbq.occupants[location.."R"]) ) end
					if sbq.occupants[location.."L"] ~= sbq.occupantsPrev[location.."L"] or sbq.direction ~= sbq.prevDirection then sbq.setPartTag( "global", location.."BackOccupants", tostring(sbq.occupants[location.."L"]) ) end

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
					if sbq.occupants[location.."R"] ~= sbq.occupantsPrev[location.."R"] or sbq.direction ~= sbq.prevDirection then sbq.setPartTag( "global", location.."BackOccupants", tostring(sbq.occupants[location.."R"]) ) end
					if sbq.occupants[location.."L"] ~= sbq.occupantsPrev[location.."L"] or sbq.direction ~= sbq.prevDirection then sbq.setPartTag( "global", location.."FrontOccupants", tostring(sbq.occupants[location.."L"]) ) end

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
			if sbq.occupants[location] ~= sbq.occupantsPrev[location] then sbq.setPartTag( "global", location.."Occupants", tostring(math.min(sbq.occupants[location], sbq.sbqData.locations[location].max or sbq.occupants[location])) ) end

			if sbq.totalTimeAlive > 0.5 or config.getParameter("doExpandAnim") then
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
	sbq.prevDirection = sbq.direction
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

	local powerMultiplier = math.max(math.log(sbq.seats[sbq.driverSeat].controls.powerMultiplier) + 1, 1)

	for i = sbq.startSlot, sbq.occupantSlots do

		local eid = sbq.occupant[i].id
		if type(eid) == "number" and world.entityExists(eid) then
			local location = sbq.occupant[i].location
			local locationEffect = sbq.settings[(location or "").."Effect"] or "sbqRemoveBellyEffects"
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

			if location == "digesting" then
				locationEffect = "sbqDigest"
			end
			if sbq.occupant[i].cumDigesting then
				locationEffect = "sbqCumDigest"
			end

			local status = (sbq.settings.displayDigest and sbq.config.bellyDisplayStatusEffects[locationEffect] ) or locationEffect

			if (sbq.settings.bellySounds == true) and (not sbq.occupant[i].digested) and sbq.config.bellyGurgleEffects[locationEffect] then
				sbq.randomTimer( "gurgle", 1.0, 8.0, function() animator.playSound( "digest" ) end )
			end
			world.sendEntityMessage( eid, "sbqApplyDigestEffect", status, powerMultiplier, sbq.driver or entity.id())

			if sbq.settings[location.."Compression"] and not sbq.occupant[i].digested and sbq.occupant[i].bellySettleDownTimer <= 0 then
				sbq.occupant[i].sizeMultiplier = math.min(1, math.max(0.1, sbq.occupant[i].sizeMultiplier - (powerMultiplier * dt)/100 ))
			end

			local progressbarDx = 0
			if sbq.occupant[i].progressBarActive == true then
				progressbarDx = (sbq.occupant[i].progressBarLocations[location] and (powerMultiplier * sbq.occupant[i].progressBarMultiplier)) or (-(powerMultiplier * sbq.occupant[i].progressBarMultiplier))
				sbq.occupant[i].progressBar = sbq.occupant[i].progressBar + dt * progressbarDx

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
			elseif sbq.settings[location.."Eggify"] and sbq.sbqData.locations[location].eggify and not (sbq.occupant[i].egged or sbq.occupant[i][location.."EggifyImmune"]) then
				sbq.loopedMessage(location.."Eggify"..eid, eid, "sbqIsPreyEnabled", {sbq.sbqData.locations[location].eggify.immunity or "eggImmunity"}, function (enabled)
					if enabled and not enabled.enabled then
						sbq.transformMessageHandler(eid, sbq.sbqData.locations[location].eggify, "eggify")
					else
						sbq.occupant[i][location.."EggifyImmune"] = true
					end
				end, function ()
					sbq.occupant[i][location.."EggifyImmune"] = true
				end)
			elseif sbq.settings[location.."TF"] and sbq.sbqData.locations[location].TF and not (sbq.occupant[i].transformed or sbq.occupant[i][location.."TFImmune"]) then
				sbq.loopedMessage(location.."TF"..eid, eid, "sbqIsPreyEnabled", {sbq.sbqData.locations[location].TF.immunity or "transformImmunity"}, function (enabled)
					if enabled and not enabled.enabled then
						sbq.transformMessageHandler(eid)
					else
						sbq.occupant[i][location.."TFImmune"] = true
					end
				end, function ()
					sbq.occupant[i][location.."TFImmune"] = true
				end)
			end

			sbq.occupant[i].indicatorCooldown = sbq.occupant[i].indicatorCooldown - dt

			if world.entityType(sbq.occupant[i].id) == "player" and sbq.occupant[i].indicatorCooldown <= 0 then
				-- p.occupant[i].indicatorCooldown = 0.5
				local struggledata = (sbq.stateconfig[sbq.state].struggle or {})[location] or {}
				local directions = {}
				local icon
				if not sbq.transitionLock and sbq.occupant[i].species ~= "sbqEgg" then
					for dir, data in pairs(struggledata.directions or {}) do
						if data and (not sbq.driving or data.drivingEnabled) and ((data.settings == nil) or sbq.checkSettings(data.settings)) then
							if dir == "front" then dir = ({"left","","right"})[sbq.direction+2] end
							if dir == "back" then dir = ({"right","","left"})[sbq.direction+2] end
							if sbq.isNested and data.indicate == "red" then
								directions[dir] = "default"
							else
								directions[dir] = data.indicate or "default"
							end
						elseif data then
							if dir == "front" then dir = ({"left","","right"})[sbq.direction+2] end
							if dir == "back" then dir = ({"right","","left"})[sbq.direction+2] end
							directions[dir] = "default"
						end
					end
				end
				if sbq.occupant[i].species and sbq.occupant[i].species ~= "sbqOccupantHolder" then
					icon = "/vehicles/sbq/"..sbq.occupant[i].species.."/skins/"..((sbq.occupant[i].smolPreyData.settings.skinNames or {}).head or "default").."/icon.png"..(sbq.occupant[i].smolPreyData.settings.directives or "")
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
							dx = progressbarDx
						},
						icon = icon,
						time = sbq.occupant[i].occupantTime,
						location = (sbq.sbqData.locations[location] or {}).name
					}
				})
			end

			sbq.otherLocationEffects(i, eid, health, locationEffect, status, location, powerMultiplier )

		end
	end
end

function sbq.validStruggle(struggler, dt)
	sbq.occupant[struggler].bellySettleDownTimer = math.max( 0, sbq.occupant[struggler].bellySettleDownTimer - dt)
	if (sbq.occupant[struggler].seatname == sbq.driverSeat) then return end


	if sbq.heldControl(sbq.occupant[struggler].seatname, "left") and sbq.heldControl(sbq.occupant[struggler].seatname, "right")
	and sbq.pressControl(sbq.occupant[struggler].seatname, "jump") then
		sbq.escapeScript(struggler)
		return
	end


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

	if not sbq.config.speciesStrugglesDisabled[config.getParameter("name")] then
		if (sbq.occupant[struggler].species ~= nil and sbq.config.speciesStrugglesDisabled[sbq.occupant[struggler].species]) or sbq.occupant[struggler].digested then
			if not sbq.driving or world.entityType(sbq.driver) == "npc" then
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

	if movedir == nil or struggledata == nil then return end -- invalid struggle

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
		sbq.doTransition( struggledata.directions[movedir].transition, {direction = movedir, id = strugglerId, struggleTrigger = true} )
	else
		local location = sbq.occupant[struggler].location

		if (struggledata.directions[movedir].indicate == "red" or struggledata.directions[movedir].indicate == "green") and ( struggledata.directions[movedir].settings == nil or sbq.checkSettings(struggledata.directions[movedir].settings) ) then
			sbq.occupant[struggler].controls.favorDirection = movedir
		elseif not struggledata.directions[movedir].indicate then
			sbq.occupant[struggler].controls.disfavorDirection = movedir
		end

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

		if sbq.settings[location.."Compression"] and not sbq.occupant[struggler].digested then
			sbq.occupant[struggler].sizeMultiplier = sbq.occupant[struggler].sizeMultiplier + (time * 2)/100
		end

		if not sbq.movement.animating then
			sbq.doAnims( struggledata.directions[movedir].animation or struggledata.animation )
		else
			sbq.doAnims( struggledata.directions[movedir].animationWhenMoving or struggledata.animationWhenMoving )
		end

		sbq.struggleMessages(strugglerId)

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
		if sound ~= false then
			animator.playSound( sound or "struggle" )
		end
	end
end

function sbq.struggleChance(struggledata, struggler, movedir)
	if not ((struggledata.directions[movedir].settings == nil) or sbq.checkSettings(struggledata.directions[movedir].settings) ) then return false end

	local chances = struggledata.chances
	if struggledata.directions[movedir].chances ~= nil then
		chances = struggledata.directions[movedir].chances
	end
	if chances ~= nil and chances.max == 0 then return true end
	if sbq.settings.impossibleEscape then return false end
	if sbq.driving and not struggledata.directions[movedir].drivingEnabled then return false end

	return chances ~= nil and (chances.min ~= nil) and (chances.max ~= nil)
	and (math.random(math.floor(chances.min * 2^((sbq.settings.escapeDifficulty or 0)/5)), math.ceil(chances.max * 2^((sbq.settings.escapeDifficulty or 0)/5))) <= (sbq.occupant[struggler].struggleTime or 0))
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
