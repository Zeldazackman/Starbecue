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
	-roaming behavior
	-leg grab

Pending features:
	Extra functions
	-digest anim
	-egg lay
	-tail vore
	-ranged inhale

]]--
-------------------------------------------------------------------------------

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

	vsoOnInteract( "state_fly", p.onInteraction )

	vsoOnBegin( "state_crouch", begin_state_crouch )
	vsoOnEnd( "state_crouch", end_state_crouch )

	vsoOnBegin( "state_fly", begin_state_fly )
	vsoOnEnd( "state_fly", end_state_fly )

end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------

function oralvore(args)
	if p.entityLounging( args.id ) then return false end
	local location = "belly"
	if LocationFull(location) then return false end

	local i = p.occupants.total + 1
	if p.eat( args.id, i, location ) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );
		return true, function()
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( "occupant"..i, "center", "bodyState")
			vsoSound( "swallow" )
		end
	else
		return false
	end
end

function escapeoralvore( args )
	position = mcontroller.position()
	p.monstercoords = {position[1]+6, position[2]+1}--same as last bit of escape anim
	if locationEmpty("belly") then return false end
	local i = args.index
	local victim = vsoGetTargetId( "occupant"..i )

	if not victim then -- could be part of above but no need to log an error here
		return false
	end
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicatemaw" } );

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( i )
		vsoApplyStatus( victim, "droolsoaked", 5.0 );
	end
end

function analvore(args)
	if p.entityLounging( args.id ) then return false end
	local location = "belly"
	if LocationFull(location) then return false end
	local i = p.occupants.total + 1
	if p.eat( args.id, i, location) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicateout" } );
		return true, function()
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( "occupant"..i, "center", "bodyState")
			vsoSound( "swallow" )
		end
	else
		return false
	end
end

function escapeanalvore(args)
	position = mcontroller.position()
	p.monstercoords = {position[1]-0.75, position[2]-5}--same as last bit of escape anim

	if locationEmpty("belly") then return false end
	local i = args.index
	local victim = vsoGetTargetId( "occupant"..i )

	if not victim then -- could be part of above but no need to log an error here
		return false
	end
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( "occupant"..i, { "vsoindicateout" } );

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( i )
		vsoApplyStatus( victim, "droolsoaked", 5.0 );
	end
end
-------------------------------------------------------------------------------


p.registerStateScript( "stand", "eat", function( args )
	return oralvore(args)
end)
p.registerStateScript( "stand", "letout", function( args )
	return escapeoralvore(args)
end)

p.registerStateScript( "stand", "bapeat", function()
	local position = p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position )

	if not locationFull("belly") then
		local prey = world.entityQuery(position, 5, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local entityaimed = world.entityQuery(vehicle.aimPosition(p.control.driver), 2, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local aimednotlounging = checkAimed(entityaimed)

		if #prey > 0 then
			for i = 1, #prey do
				if prey[i] == entityaimed[aimednotlounging] and not p.entityLounging(prey[i]) then
					animator.setGlobalTag( "bap", "" )
					p.doTransition( "eat", {id=prey[i]} )
					return
				end
			end
		end
	end
end)

function checkAimed(entityaimed)
	for i = 1, #entityaimed do
		if not p.entityLounging(entityaimed[i]) then
			return i
		end
	end
end

function state_stand()

	p.idleStateChange()
	p.handleBelly()

	local position = mcontroller.position()
	if p.control.probablyOnGround()
	and world.rectCollision( {position[1]-3.5, position[2]+4, position[1]+3.5, position[2]+1 }, { "Null", "block", "slippery"} )
	and not world.rectCollision( {position[1]-3.5, position[2]-5, position[1]+3.5, position[2] }, { "Null", "block", "slippery"} )
	then
		if (vehicle.controlHeld( p.control.driver, "left") or vehicle.controlHeld( p.control.driver, "right") )
		and vehicle.controlHeld( p.control.driver, "down") then
			p.doTransition( "crouch" )
			return
		elseif p.autocrouch or not p.control.driving then
			p.doTransition( "crouch" )
			return
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

		if vehicle.controlHeld( p.control.driver, "jump" ) and p.movement.airframes > 10 and not p.movement.jumped then
			p.setState( "fly" )
			return
		end

		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" )  then
			if p.occupants.total > 0 then
				p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
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
	return oralvore(args)
end)
p.registerStateScript( "sit", "letout", function( args )
	return escapeoralvore(args)
end)

p.registerStateScript( "sit", "hug", function( args )
	if p.eat( args.id, 1, "hug") then
		vsoVictimAnimSetStatus( "occupant1", {} );
		return true
	else
		return false
	end
end)

function state_sit()
	p.standardState()

	if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" )  then
		if p.occupants.total > 0 then
			p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
		end
	end

	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and p.control.standalone then
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
	p.uneat( "Occupant1" )
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
	if not world.rectCollision( {position[1]-3.5, position[2]+4, position[1]+3.5, position[2]+1 }, { "Null", "block", "slippery"} )
	and not vehicle.controlHeld( p.control.driver, "down")
	then
		if not p.control.probablyOnGround() then
			p.setState( "stand" )
			return
		else
			p.doTransition( "uncrouch" )
			return
		end
	end

end

function end_state_crouch()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
	p.movement.downframes = 11

end

-------------------------------------------------------------------------------

function begin_state_fly()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.fly )
	p.movement.jumped = true
end

p.registerStateScript( "fly", "letout", function( args )
	return escapeoralvore(args)
end)

p.registerStateScript( "fly", "analvore", function( args )
	return analvore(args)
end)

p.registerStateScript( "fly", "escapeanalvore", function( args )
	return escapeanalvore(args)
end)

p.registerStateScript( "fly", "grabanalvore", function()
	local position = mcontroller.position()
	position = {position[1], position[2]-3}

	if not locationFull("belly") then
		local prey = world.entityQuery(position, 3, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local entityaimed = world.entityQuery(vehicle.aimPosition(p.control.driver), 2, {
			withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
			includedTypes = {"creature"}
		})
		local aimednotlounging = checkAimed(entityaimed)

		if #prey > 0 then
			for i = 1, #prey do
				if prey[i] == entityaimed[aimednotlounging] and not p.entityLounging(prey[i]) then
					animator.setGlobalTag( "bap", "" )
					p.doTransition( "analvore", {id=prey[i]} )
					return
				end
			end
		end
	end
end)


function state_fly()
	p.doAnims(p.stateconfig[p.state].control.animations.fly)

	p.idleStateChange()
	p.handleBelly()

	p.control.primaryAction()
	p.control.altAction()
	p.control.interact()

	local control = p.stateconfig[p.state].control

	if p.occupants.total >= control.fullThreshold and p.control.probablyOnGround() then
		p.setState( "stand" )
		return
	end

	local dx = 0
	local dy = 0
	local controlForce = 100

	if p.control.driving then
		if vehicle.controlHeld( p.control.driver, "left" ) then
			dx = dx - 1
		end
		if vehicle.controlHeld( p.control.driver, "right" ) then
			dx = dx + 1
		end
		if vehicle.controlHeld( p.control.driver, "up" ) then
			dy = dy + 1
		end
		if vehicle.controlHeld( p.control.driver, "down" ) then
			dy = dy - 1
		end

		if vehicle.controlHeld( p.control.driver, "jump" ) then
			if not p.movement.jumped then
				p.setState( "stand" )
				return
			end
		else
			p.movement.jumped = false
		end

		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" )  then
			if p.occupants.total > 0 then
				p.doTransition( "escape", {index=p.occupants.total} ) -- last eaten
			end
		end
	end

	local running = false
	if (p.occupants.total + p.fattenBelly) < control.fullThreshold then --add walk control here when we have more controls
		running = true
	end
	if dx ~= 0 then
		vsoFaceDirection( dx )
	end
	if running then
		mcontroller.approachXVelocity( dx * control.runSpeed, controlForce )
		mcontroller.approachYVelocity( dy * control.runSpeed -control.fullWeights[(p.occupants.total + p.fattenBelly) +1], controlForce )
	else
		mcontroller.approachXVelocity( dx * control.walkSpeed, controlForce )
		mcontroller.approachYVelocity( dy * control.walkSpeed -control.fullWeights[(p.occupants.total + p.fattenBelly) +1], controlForce )
	end

	p.control.updateDriving()
end

function end_state_fly()
	p.movement.jumped = true
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end

-------------------------------------------------------------------------------
