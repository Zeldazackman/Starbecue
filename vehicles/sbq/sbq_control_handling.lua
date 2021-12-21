function p.pressControl(seat, control)
	if p.seats[seat].controls[control.."Pressed"] then
		p.seats[seat].controls[control.."Pressed"] = false
		return true
	end
end

function p.tapControl(seat, control)
	return (( p.seats[seat].controls[control.."Released"] > 0 ) and ( p.seats[seat].controls[control.."Released"] < 0.19 ))
end

function p.heldControl(seat, control, min)
	return p.seats[seat].controls[control] > (min or 0)
end

function p.heldControlMax(seat, control, max)
	return p.seats[seat].controls[control] < (max or 1)
end

function p.heldControlMinMax(seat, control, min, max)
	return p.heldControl(seat, control, min) and p.heldControlMax(seat, control, max)
end

function p.heldControls(seat, controlList, time)
	for _, control in pairs(controlList) do
		if p.seats[seat].controls[control] <= (time or 0) then
			return false
		end
	end
	return true
end

function p.updateControl(seatname, control, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		if p.seats[seatname].controls[control] == 0 then
			p.seats[seatname].controls[control.."Pressed"] = true
		else
			p.seats[seatname].controls[control.."Pressed"] = false
		end
		p.seats[seatname].controls[control] = p.seats[seatname].controls[control] + dt
		p.seats[seatname].controls[control.."Released"] = 0
	else
		p.seats[seatname].controls[control.."Released"] = p.seats[seatname].controls[control]
		p.seats[seatname].controls[control] = 0
	end
end

function p.updateDirectionControl(seatname, control, direction, val, dt, forceHold)
	if vehicle.controlHeld(seatname, control) or forceHold then
		p.seats[seatname].controls[control] = p.seats[seatname].controls[control] + dt
		p.seats[seatname].controls[direction] = p.seats[seatname].controls[direction] + val
		p.seats[seatname].controls[control.."Released"] = 0
	else
		p.seats[seatname].controls[control.."Released"] = p.seats[seatname].controls[control]
		p.seats[seatname].controls[control] = 0
	end
end

function p.updateControls(dt)
	for i = 0, p.occupants.total do
		local seatname = p.occupant[i].seatname
		local eid = p.occupant[i].id
		if eid ~= nil and world.entityExists(eid) and not (seatname == p.driverSeat and p.isPathfinding) then
			p.occupant[i].controls.dx = 0
			p.occupant[i].controls.dy = 0
			p.updateDirectionControl(seatname, "left", "dx", -1, dt)
			p.updateDirectionControl(seatname, "right", "dx", 1, dt)
			p.updateDirectionControl(seatname, "down", "dy", -1, dt)
			p.updateDirectionControl(seatname, "up", "dy", 1, dt)
			p.updateControl(seatname, "jump", dt)
			p.updateControl(seatname, "special1", dt)
			p.updateControl(seatname, "special2", dt)
			p.updateControl(seatname, "special3", dt)
			p.updateControl(seatname, "primaryFire", dt)
			p.updateControl(seatname, "altFire", dt)

			p.occupant[i].controls.aim = vehicle.aimPosition( seatname ) or {0,0}
			p.occupant[i].controls.species = world.entitySpecies(eid) or world.monsterType(eid)
			p.occupant[i].controls.primaryHandItem = world.entityHandItem(eid, "primary")
			p.occupant[i].controls.altHandItem = world.entityHandItem(eid, "alt")
			p.occupant[i].controls.primaryHandItemDescriptor = world.entityHandItemDescriptor(eid, "primary")
			p.occupant[i].controls.altHandItemDescriptor = world.entityHandItemDescriptor(eid, "alt")

			local type
			local data
			if (seatname == p.driverSeat) then
				if p.driving then
					type = "driver"
				else
					type = "prey"
				end
				data = {
					species = world.entityName(entity.id()),
					layer = p.occupant[i].smolPreyData,
					state = p.state
				}
			else
				type = "prey"
				data = p.occupant[i].smolPreyData
			end
			data.type = type

			if p.occupant[i].controls.primaryHandItem ~= nil and p.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage ~= nil and p.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage.seatdata ~= nil then
				p.occupant[i].controls = sb.jsonMerge(p.occupant[i].controls, p.occupant[i].controls.primaryHandItemDescriptor.parameters.scriptStorage.seatdata)
			elseif p.occupant[i].controls.altHandItem ~= nil and p.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage ~= nil and p.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage.seatdata ~= nil then
				p.occupant[i].controls = sb.jsonMerge(p.occupant[i].controls, p.occupant[i].controls.altHandItemDescriptor.parameters.scriptStorage.seatdata)
			else
				p.occupant[i].controls.shiftReleased = p.occupant[i].controls.shift
				p.occupant[i].controls.shift = 0

				p.loopedMessage(seatname.."Info", eid, "sbqGetSeatInformation", {type}, function(seatdata)
					p.occupant[i].controls = sb.jsonMerge(p.occupant[i].controls, seatdata)
				end)
			end
			p.loopedMessage(seatname.."Equips", eid, "sbqGetSeatEquips", {data}, function(seatdata)
				p.occupant[i].controls = sb.jsonMerge(p.occupant[i].controls, seatdata)
			end)
		end
	end
end

p.monsterstrugglecooldown = {}

function p.getSeatDirections(seatname)
	local occupantId = p.seats[seatname].id
	if not occupantId or not world.entityExists(occupantId) then return end

	if world.entityType( occupantId ) ~= "player" then
		if not p.monsterstrugglecooldown[seatname] or p.monsterstrugglecooldown[seatname] <= 0 then
			local randomDirections = { "back", "front", "up", "down", "jump", nil}
			p.monsterstrugglecooldown[seatname] = (math.random(10, 300)/100)
			return randomDirections[math.random(1,6)]
		else
			p.monsterstrugglecooldown[seatname] = p.monsterstrugglecooldown[seatname] - p.dt
			return
		end
	else
		local direction = p.relativeDirectionName(p.seats[seatname].controls.dx, p.seats[seatname].controls.dy)
		if direction then return direction end
		if p.seats[seatname].controls.jump > 0 then
			return "jump"
		end
	end
end

function p.relativeDirectionName(dx, dy)
	local dx = dx * p.direction
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
