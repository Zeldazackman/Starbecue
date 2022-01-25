--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
}

-------------------------------------------------------------------------------

function sbq.init()
end

-------------------------------------------------------------------------------

function sbq.update(dt)
	sbq.whenFalling()
	sbq.changeSize()
end

function sbq.whenFalling()
	if sbq.state == "stand" or sbq.state == "smol" or sbq.state == "chonk_ball" then return end
	if not mcontroller.onGround() and sbq.totalTimeAlive > 1 then
		sbq.setState( "stand" )
		sbq.doAnims( sbq.stateconfig[sbq.state].control.animations.fall )
		sbq.movement.falling = true
		sbq.uneat(sbq.findFirstOccupantIdForLocation("hug"))
	end
end

function analEscape(args)
	return sbq.doEscape(args, {}, {} )
end

function eatAnal(args)
	return sbq.doVore(args, "belly", {}, "swallow")
end

function checkAnalVore()
	return sbq.checkEatPosition(sbq.localToGlobal({-5, -3}), 3, "belly", "eatAnal")
end

-------------------------------------------------------------------------------
