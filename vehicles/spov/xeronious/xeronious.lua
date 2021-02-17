--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------
--[[

Commissioned by:
    -xeronious#8891			https://www.furaffinity.net/user/xeronious/

Sprites created by:
    -Wasabi_Raptor#1533		https://www.furaffinity.net/user/lokithevulpix/

Scripts created by:
    Zygan#0404 				<-did like 99% of the scripts
    Wasabi_Raptor#1533 		<-did debugs and copied scripts around for things

TODO:
	-Third belly slot sprites
	-roaming behavior
	-settings menu
		-auto crouch option

Pending features:

	Vertical movement
	-jump
	-fly
	-leg grab
	-anal vore

	Extra functions
	-digest anim
	-egg lay
	-tail vore
	-ranged inhale

]]--
-------------------------------------------------------------------------------

p.openSettingsHandler = "openVSOsettings"
p.vsoMenuName = "xeronious"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.

	p.onBegin()

	vsoOnInteract( "state_stand", interact_state_stand )
	vsoOnInteract( "state_crouch", p.onInteraction )
	vsoOnInteract( "state_sit", p.onInteraction )
	vsoOnInteract( "state_hug", p.onInteraction )

	vsoOnBegin( "state_crouch", begin_state_crouch )
	vsoOnEnd( "state_crouch", end_state_crouch )

end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( args )
	if p.entityLounging( args.id ) then return end
	if p.occupants == 3 then
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
	if p.visualOccupants < 3 then
		local prey = world.playerQuery( position, 2 )
		if #prey < 1 and p.control.standalone then
			prey = world.npcQuery( position, 2 )
		end
		if #prey > 0 then
			p.doTransition( "eat", {id=prey[1]} )
		end
	end
end)

function state_stand()

	p.idleStateChange()
	p.handleBelly()

	local position = mcontroller.position()
	if world.rectCollision( {position[1]-3.5, position[2]+3, position[1]+3.5, position[2] }, { "Null", "block", "slippery"} )
	and not world.rectCollision( {position[1]-3.5, position[2]-6, position[1]+3.5, position[2]-1 }, { "Null", "block", "slippery"} )
	then
		if (vehicle.controlHeld( p.control.driver, "left") or vehicle.controlHeld( p.control.driver, "right") )
		and vehicle.controlHeld( p.control.driver, "down") then
			p.doTransition( "crouch" )
		elseif not p.control.driving then
			p.doTransition( "crouch" )
		end
	end

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
	if p.occupants == 3 then
		sb.logError("[Xeronious] Can't eat more than three people!")
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

p.registerStateScript( "sit", "hug", function( args )
	vsoSetTarget( 1, args.id )
	if p.eat( vsoGetTargetId( 1 ), 1 ) then
		vsoVictimAnimSetStatus( "occupant1", {} );
		return true
	else
		vsoSetTarget( 1, nil )
		return false
	end
end)

function state_sit()
	p.standardState()

	-- simulate npc interaction when nearby
	if p.occupants == 0 and p.control.standalone then
		if vsoChance(0.1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "hug", {id=npcs[1]} )
			end
		end
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "hug", "unhug", function()
	vsoSetTarget( 1, nil )
	p.uneat( 1 )
	return true
end)

state_hug = p.standardState

-------------------------------------------------------------------------------

function begin_state_crouch()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.crouch )
end

function state_crouch()

	p.idleStateChange()
	p.handleBelly()

	if p.control.driving then
		p.control.drive()
	else
		p.control.doPhysics()
	end

	p.control.updateDriving()

	local position = mcontroller.position()
	if not world.rectCollision( {position[1]-3.5, position[2]+3, position[1]+3.5, position[2]+0 }, { "Null", "block", "dynamic", "slippery"} )
	and not vehicle.controlHeld( p.control.driver, "down")
	then
		--[[
		if not p.control.probablyOnGround() then
			p.setState( "stand" )
		else
		]]--
			p.doTransition( "uncrouch" )
		--end
	end

end

function end_state_crouch()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
	p.movement.downframes = 11

end

-------------------------------------------------------------------------------
