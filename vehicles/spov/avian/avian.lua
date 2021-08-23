--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

p.vsoMenuName = "avian"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.

	vsoOnInteract( "state_stand", interact_state_stand )

	vsoOnBegin( "state_smol", begin_state_smol )
	vsoOnEnd( "state_smol", end_state_smol )
end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)

function state_stand()

	p.idleStateChange()
	p.handleBelly()

	if p.control.driving then
		if p.control.standalone then
			if vehicle.controlHeld( p.control.driver, "Special2" ) then
				if p.occupants.total > 0 then
					--p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
				end
			end

			if vehicle.controlHeld( p.control.driver, "Special1" ) then
				if not p.movement.wasspecial1 then
					-- vsoAnim( "bodyState", "unsmolify" )
					vsoEffectWarpIn()
					p.setState( "smol" )
					p.doAnims( p.stateconfig.smol.idle, true )
				end
				p.movement.wasspecial1 = true
			else
				p.movement.wasspecial1 = false
			end
		end

		p.control.drive()
	else
		p.doPhysics()
	end

	p.updateDriving()

end

function interact_state_stand( occupantId )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( occupantId )
	end
end

-------------------------------------------------------------------------------

function begin_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.smol )
	--fixOccupantCenters("belly", "smolbellycenter", "body")
end

function state_smol()

	p.idleStateChange()
	p.handleBelly()

	if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special1" ) then
		if not p.movement.wasspecial1 then
			-- vsoAnim( "bodyState", "unsmolify" )
			vsoEffectWarpIn()
			p.setState( "stand" )
			p.doAnims( p.stateconfig.stand.idle, true )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
	p.control.drive()

	p.updateDriving()

end

function end_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end

-------------------------------------------------------------------------------
