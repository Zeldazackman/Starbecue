--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

p.vso.menuName = "avian"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

end

function onBegin()	--This sets up the VSO ONCE.

end

function onEnd()

end

-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)

function state.stand()

	p.idleStateChange()
	p.handleBelly()

	if p.driving then
		if p.standalone then
			if vehicle.controlHeld( p.driverSeat, "Special2" ) then
				if p.occupants.total > 0 then
					--p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
				end
			end

			if vehicle.controlHeld( p.driverSeat, "Special1" ) then
				if not p.movement.wasspecial1 then
					-- p.doAnim( "bodyState", "unsmolify" )
					vsoEffectWarpIn()
					p.setState( "smol" )
					p.doAnims( p.stateconfig.smol.idle, true )
				end
				p.movement.wasspecial1 = true
			else
				p.movement.wasspecial1 = false
			end
		end

		p.drive()
	else
		p.doPhysics()
	end

	p.updateDriving()

end

function state.interact.stand( occupantId )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( occupantId )
	end
end

-------------------------------------------------------------------------------

function state.begin.smol()
	p.setMovementParams( "smol" )
end

function state.smol()

	p.idleStateChange()
	p.handleBelly()

	if p.standalone and vehicle.controlHeld( p.driverSeat, "Special1" ) then
		if not p.movement.wasspecial1 then
			-- p.doAnim( "bodyState", "unsmolify" )
			vsoEffectWarpIn()
			p.setState( "stand" )
			p.doAnims( p.stateconfig.stand.idle, true )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
	p.drive()

	p.updateDriving()

end

function state.ending.smol()
	p.setMovementParams( "default" )
end

-------------------------------------------------------------------------------
