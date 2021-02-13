--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------

p.openSettingsHandler = "openvappysettings"

p.buildMaterial = "slime"
p.buildHue = 75

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.

	p.onBegin()

	vsoOnInteract( "state_stand", interact_state_stand )

	vsoOnInteract( "state_sit", p.onInteraction )
end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( args )
	if p.entityLounging( args.id ) then return end
	if p.occupants == 2 then
		sb.logError("[Xeronious] Can't eat more than two people!")
		return false
	end
	local i = p.occupants + 1
	vsoSetTarget( i, args.id )
	if p.eat( vsoGetTargetId( i ), i ) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );
		return true, function()
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( "occupant"..i, "center", "bodyState")
			vsoSound( "swallow" )
		end
	else
		vsoSetTarget( i, nil )
		return false
	end
end)
p.registerStateScript( "stand", "letout", function( args )
	if p.occupants == 0 then
		sb.logError( "[Xeronious] No one to let out!" )
		return false
	end
	local i = args.index
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( i )
		vsoSetTarget( i, nil )
		if vsoGetTargetId( i ) ~= nil then
			vsoApplyStatus( i, "droolsoaked", 5.0 );
		end
	end
end)
p.registerStateScript( "stand", "bapeat", function()
	local position = p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position )
	if p.visualOccupants < 2 then
		local prey = world.playerQuery( position, 2 )
		if #prey < 1 and p.control.standalone then
			prey = world.npcQuery( position, 2 )
		end
		if #prey > 0 then
			--animator.setGlobalTag( "bap", "" )
			--vsoAnim( "bapState", "none" )
			p.doTransition( "eat", {id=prey[1]} )
		end
	end
end)

function state_stand()

	p.idleStateChange()
	p.handleBelly()

	if p.control.driving then
		if vehicle.controlHeld( p.control.driver, "down" ) then
			p.movement.downframes = p.movement.downframes + 1
		else
			if p.movement.downframes > 0 and p.movement.downframes < 10 and p.control.notMoving() and p.control.probablyOnGround() then
				p.doTransition( "down" )
			end
			p.movement.downframes = 0
		end
		if p.movement.wasspecial1 ~= true and p.movement.wasspecial1 ~= false and p.movement.wasspecial1 > 0 then
			-- a bit of a hack, prevents the special1 press from activating xeronious from also doing this by adding a 10 frame delay before checking if you're pressing it
			p.movement.wasspecial1 = p.movement.wasspecial1 - 1
		else
			p.movement.wasspecial1 = false
		end
		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" )  then
			if p.occupants > 0 then
				p.doTransition( "escape", {index=p.occupants} ) -- last eaten
			end
		end
		p.control.drive()
	else
		p.control.doPhysics()
	end

	p.control.updateDriving()

end

function interact_state_stand( targetid )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( targetid )
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "sit", "eat", function( args )
	if p.entityLounging( args.id ) then return end
	if p.occupants == 2 then
		sb.logError("[Xeronious] Can't eat more than two people!")
		return false
	end
	local i = p.occupants + 1
	vsoSetTarget( i, args.id )
	if p.eat( vsoGetTargetId( i ), i ) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );
		return true, function()
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( "occupant"..i, "center", "bodyState")
			vsoSound( "swallow" )
		end
	else
		vsoSetTarget( i, nil )
		return false
	end
end)
p.registerStateScript( "sit", "letout", function( args )
	if p.occupants == 0 then
		sb.logError( "[Xeronious] No one to let out!" )
		return false
	end
	local i = args.index
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( i )
		vsoSetTarget( i, nil )
		if vsoGetTargetId( i ) ~= nil then
			vsoApplyStatus( i, "droolsoaked", 5.0 );
		end
	end
end)

function interact_state_sit( targetid )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( targetid )
	end
end


state_sit = p.standardState

-------------------------------------------------------------------------------
