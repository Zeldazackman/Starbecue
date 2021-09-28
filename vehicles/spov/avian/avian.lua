--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

state = {
	stand = {},
	smol = {}
}
-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

end

function onBegin()	--This sets up the VSO ONCE.

end

function onEnd()
end

function p.update(dt)
	p.changeSize()
end

function p.changeSize()
	if p.tapControl( p.driverSeat, "special1" ) and p.totalTimeAlive > 0.5 and not p.transitionLock then
		local changeSize = "smol"
		if p.state == changeSize then
			changeSize = "stand"
		end
		world.spawnProjectile( "vsowarpineffect", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect
		p.setState( changeSize )
	end
end

-------------------------------------------------------------------------------
function state.stand.begin()
	p.setMovementParams( "default" )
	p.resolvePosition(5)
end

function state.stand.eat( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

-------------------------------------------------------------------------------

function state.smol.begin()
	p.setMovementParams( "smol" )
	p.resolvePosition(3)
end

-------------------------------------------------------------------------------
