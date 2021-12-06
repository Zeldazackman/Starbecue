--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
	smol = {}
}
-------------------------------------------------------------------------------

function onBegin()	--This sets up the VSO ONCE.

end

function onEnd()
end

function p.update(dt)
	p.changeSize()
	p.armRotationUpdate()
	p.setGrabTarget()
end

function p.changeSize()
	if p.tapControl( p.driverSeat, "special1" ) and p.totalTimeAlive > 0.5 and not p.transitionLock then
		local changeSize = "smol"
		if p.state == changeSize then
			changeSize = "stand"
		end
		p.warpInEffect() --Play warp in effect
		p.setState( changeSize )
	end
end

function grab()
	p.grab("hug")
end

function cockVore(args)
	return p.doVore(args, "shaft", {}, "swallow")
end

function cockEscape(args)
	return p.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function oralVore(args)
	return p.doVore(args, "belly", {}, "swallow")
end

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
end

function checkOralVore()
	return p.checkEatPosition(p.localToGlobal( {0, 0} ), 5, "belly", "eat")
end

function checkCockVore()
	return p.checkEatPosition(p.localToGlobal( {0, -3} ), 4, "shaft", "cockVore")
end


-------------------------------------------------------------------------------
function state.stand.begin()
	p.setMovementParams( "default" )
	p.resolvePosition(5)
end

state.stand.eat = oralVore
state.stand.cockVore = cockVore
state.stand.cockEscape = cockEscape

state.stand.checkCockVore = checkCockVore
state.stand.checkOralVore = checkOralVore

-------------------------------------------------------------------------------

function state.smol.begin()
	p.setMovementParams( "smol" )
	p.resolvePosition(3)
end

-------------------------------------------------------------------------------
