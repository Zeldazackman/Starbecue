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

-------------------------------------------------------------------------------

function state.stand.eat( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function state.stand.update()
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
					world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect

					p.setState( "smol" )
					p.doAnims( p.stateconfig.smol.idle, true )
				end
				p.movement.wasspecial1 = true
			else
				p.movement.wasspecial1 = false
			end
		end
	end
end

-------------------------------------------------------------------------------

function state.smol.begin()
	p.setMovementParams( "smol" )
end

function state.smol.update()
	if p.standalone and vehicle.controlHeld( p.driverSeat, "Special1" ) then
		if not p.movement.wasspecial1 then
			-- p.doAnim( "bodyState", "unsmolify" )
			world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect

			p.setState( "stand" )
			p.doAnims( p.stateconfig.stand.idle, true )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
end

function state.smol.ending()
	p.setMovementParams( "default" )
end

-------------------------------------------------------------------------------
