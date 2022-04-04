--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
}

-------------------------------------------------------------------------------

function sbq.letout(id)
	local id = id
	if id == nil then
		id = sbq.occupant[sbq.occupants.total].id
	end
	if not id then return end
	local location = sbq.lounging[id].location

	if location == "belly" then
		--if p.heldControl(p.driverSeat, "down") or p.lounging[id].species == "sbqEgg" then
		--	return p.doTransition("analEscape", {id = id})
		--else
			return sbq.doTransition("oralEscape", {id = id})
		--end
	elseif location == "shaft" then
		return sbq.doTransition("cockEscape", {id = id})

	elseif location == "ballsL" or location == "ballsR" then
		return ballsToShaft({id = id})
	end
end

function shaftToBalls(args)
	local side = "L"
	if math.random() > 0.5 then
		side = "R"
	end
	return sbq.moveOccupantLocation(args, "balls"..side)
end

function ballsToShaft(args)
	sbq.moveOccupantLocation(args, "shaft")
end

function oralVore(args)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "belly", {}, "swallow")
end

function checkOralVore()
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.oralVore.position ), 5, "belly", "oralVore")
end

function checkVore()
	if checkOralVore() then return true end
end

function oralEscape(args)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

-------------------------------------------------------------------------------

state.stand.oralVore = oralVore

state.stand.checkVore = checkVore
state.stand.checkOralVore = checkOralVore

state.stand.oralEscape = oralEscape

-------------------------------------------------------------------------------
