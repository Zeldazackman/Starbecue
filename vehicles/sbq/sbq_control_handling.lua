function sbq.pressControl(seat, control)
	if sbq.seats[seat].controls[control.."Pressed"] then
		return true
	end
end

function sbq.tapControl(seat, control)
	return (( sbq.seats[seat].controls[control.."Released"] > 0 ) and ( sbq.seats[seat].controls[control.."Released"] < 0.19 ))
end

function sbq.heldControl(seat, control, min)
	return sbq.seats[seat].controls[control] > (min or 0)
end

function sbq.heldControlMax(seat, control, max)
	return sbq.seats[seat].controls[control] < (max or 1)
end

function sbq.heldControlMinMax(seat, control, min, max)
	return sbq.heldControl(seat, control, min) and sbq.heldControlMax(seat, control, max)
end

function sbq.heldControls(seat, controlList, time)
	for _, control in pairs(controlList) do
		if sbq.seats[seat].controls[control] <= (time or 0) then
			return false
		end
	end
	return true
end

function sbq.updateControl(seatname, control, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		if sbq.seats[seatname].controls[control] == 0 then
			sbq.seats[seatname].controls[control.."Pressed"] = true
		else
			sbq.seats[seatname].controls[control.."Pressed"] = false
		end
		sbq.seats[seatname].controls[control] = sbq.seats[seatname].controls[control] + dt
		sbq.seats[seatname].controls[control.."Released"] = 0
	else
		sbq.seats[seatname].controls[control.."Released"] = sbq.seats[seatname].controls[control]
		sbq.seats[seatname].controls[control] = 0
	end
end

function sbq.updateDirectionControl(seatname, control, direction, val, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		sbq.seats[seatname].controls[control] = sbq.seats[seatname].controls[control] + dt
		sbq.seats[seatname].controls[direction] = sbq.seats[seatname].controls[direction] + val
		sbq.seats[seatname].controls[control.."Released"] = 0
	else
		sbq.seats[seatname].controls[control.."Released"] = sbq.seats[seatname].controls[control]
		sbq.seats[seatname].controls[control] = 0
	end
end

function sbq.updateControls(dt)
	for i = 0, sbq.occupants.total do
		local seatname = sbq.occupant[i].seatname
		local eid = sbq.occupant[i].id
		if type(eid) == "number" and world.entityExists(eid) and not (seatname == sbq.driverSeat and sbq.isPathfinding) then
			sbq.occupant[i].controls.dx = 0
			sbq.occupant[i].controls.dy = 0
			sbq.updateDirectionControl(seatname, "left", "dx", -1, dt)
			sbq.updateDirectionControl(seatname, "right", "dx", 1, dt)
			sbq.updateDirectionControl(seatname, "down", "dy", -1, dt)
			sbq.updateDirectionControl(seatname, "up", "dy", 1, dt)
			sbq.updateControl(seatname, "jump", dt)
			sbq.updateControl(seatname, "special1", dt)
			sbq.updateControl(seatname, "special2", dt)
			sbq.updateControl(seatname, "special3", dt)
			sbq.updateControl(seatname, "primaryFire", dt)
			sbq.updateControl(seatname, "altFire", dt)

			sbq.occupant[i].controls.aim = vehicle.aimPosition( seatname ) or {0,0}
			sbq.occupant[i].controls.species = world.entitySpecies(eid) or world.monsterType(eid)
			sbq.occupant[i].controls.primaryHandItem = world.entityHandItem(eid, "primary")
			sbq.occupant[i].controls.altHandItem = world.entityHandItem(eid, "alt")
			sbq.occupant[i].controls.primaryHandItemDescriptor = world.entityHandItemDescriptor(eid, "primary")
			sbq.occupant[i].controls.altHandItemDescriptor = world.entityHandItemDescriptor(eid, "alt")

			sbq.getSeatData(i, seatname, eid)
		end
	end
end

function sbq.getSeatData(i, seatname, eid)
	local seatType
	local data
	if (seatname == sbq.driverSeat) then
		if sbq.driving then
			seatType = "driver"
		else
			seatType = "prey"
		end
		data = {
			species = world.entityName(entity.id()),
			layer = sbq.occupant[i].smolPreyData,
			state = sbq.state,
			edible = sbq.stateconfig[sbq.state].edible,
			totalOccupants = sbq.occupants.total,
			hitbox = sbq.movementParams.collisionPoly,
			id = entity.id()
		}
	else
		seatType = "prey"
		data = sbq.occupant[i].smolPreyData
	end
	data.type = seatType

	if sbq.occupant[i].controls.primaryHandItem ~= nil and sbq.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage ~= nil and sbq.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage.seatdata ~= nil then
		sbq.occupant[i].controls = sb.jsonMerge(sbq.occupant[i].controls, sbq.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage.seatdata)
	elseif sbq.occupant[i].controls.altHandItem ~= nil and sbq.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage ~= nil and sbq.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage.seatdata ~= nil then
		sbq.occupant[i].controls = sb.jsonMerge(sbq.occupant[i].controls, sbq.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage.seatdata)
	else
		sbq.occupant[i].controls.shiftReleased = sbq.occupant[i].controls.shift
		sbq.occupant[i].controls.shift = 0

		sbq.loopedMessage(seatname .. "Info", eid, "sbqGetSeatInformation", { seatType }, function(seatdata)
			sbq.occupant[i].controls = sb.jsonMerge(sbq.occupant[i].controls, seatdata)
		end)
	end
	sbq.loopedMessage(seatname .. "Equips", eid, "sbqGetSeatEquips", { data }, function(seatdata)
		sbq.occupant[i].controls = sb.jsonMerge(sbq.occupant[i].controls, seatdata)
	end)
end

sbq.monsterstrugglecooldown = {}

function sbq.getSeatDirections(seatname)
	local occupantId = sbq.seats[seatname].id
	if not occupantId or not world.entityExists(occupantId) then return end

	if world.entityType( occupantId ) ~= "player" then
		if not sbq.monsterstrugglecooldown[seatname] or sbq.monsterstrugglecooldown[seatname] <= 0 then
			local randomDirections = { "back", "front", "up", "down", "jump", nil}
			sbq.monsterstrugglecooldown[seatname] = (math.random(10, 300)/100)
			return randomDirections[math.random(1,6)]
		else
			sbq.monsterstrugglecooldown[seatname] = sbq.monsterstrugglecooldown[seatname] - sbq.dt
			return
		end
	else
		local direction = sbq.relativeDirectionName(sbq.seats[seatname].controls.dx, sbq.seats[seatname].controls.dy)
		if direction then return direction end
		if sbq.seats[seatname].controls.jump > 0 then
			return "jump"
		end
	end
end

function sbq.relativeDirectionName(dx, dy)
	local dx = dx * sbq.direction
	if dx ~= 0 then
		if dx >= 1 then
			return "front"
		else
			return "back"
		end
	end
	if dy ~= 0 then
		if dy >= 1 then
			return "up"
		else
			return "down"
		end
	end
end
