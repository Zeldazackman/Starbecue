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
	-egg lay
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
	vsoOnInteract( "state_sit", p.onInteraction )
	vsoOnInteract( "state_hug", p.onInteraction )

	vsoOnBegin( "state_crouch", begin_state_crouch )
	vsoOnEnd( "state_crouch", end_state_crouch )

	vsoOnBegin( "state_fly", begin_state_fly )
	vsoOnEnd( "state_fly", end_state_fly )

end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------

function p.whenFalling()
	if p.state ~= ("stand" or "fly") and mcontroller.yVelocity() < -5 then
		p.setState( "stand" )
		p.doAnims( p.stateconfig[p.state].control.animations.fall )
		p.movement.falling = true
		for i = 1, p.occupants.total do
			if p.occupantLocation[i] == "hug" then
				p.uneat(i)
			end
		end
	end
end

function checkEscapes(args)
	local location = p.occupantLocation[args.index]
	local returnval = {}
	local direction = "escapeoral"
	local status = {"vsoindicatemaw"}
	local monstercoords = {6, 1} -- same as last coords of escape anim
	local move = args.direction or "up"

	if p.smolpreyspecies[args.index] == "xeronious_egg"
	or vehicle.controlHeld(p.control.driver, "down") then
		move = "down"
	end

	if location == "tail" then
		direction = "escapetail"
		monstercoords = {-6, 0}
	elseif location == "belly" and move == "down" and p.stateconfig[p.state].transitions.escapeanalvore then
		status = {"vsoindicateout"}
		direction = "escapeanalvore"
		monstercoords = {-0.75, -3}
	end

	if not p.doTransition(direction, args) then return false end

	returnval[1], returnval[2] = doescape(args, location, monstercoords, status, {"droolsoaked", 5})

	returnval[3] = p.occupantArray( p.stateconfig[p.state].transitions[direction] )

	return returnval[1], returnval[2], returnval[3]
end

function extraBellyEffects()
	for i = 1, p.occupants.total do
		local eid = vsoGetTargetId( "occupant"..i )
		if eid and world.entityExists(eid) then
			local health = world.entityHealth(eid)
			if p.occupantLocation[i] == "belly" and health[1] == 1 and p.settings.bellyeffect == "softdigest" then
				p.smolpreyspecies[i] = "xeronious_egg"
				p.smolprey( i )
				if p.settings.autoegglay or not p.control.driving then p.doTransition("escape", {index=i, direction="down"}) end
				return
			end
		end
	end
end

function succ(args)
	local pos1 = p.localToGlobal({-5,-8})
	local pos2 = p.localToGlobal({30,8})
	if pos1[1] > pos2[1] then
		pos1[1], pos2[1] = pos2[1], pos1[1]
	end

	-- local pos1 = p.localToGlobal({9,0})

	local entities = world.entityQuery(pos1, pos2, {
		withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
		includedTypes = {"creature"}
	})

	-- local entities = world.entityQuery(pos1, 10, {
	-- 	withoutEntityId = vehicle.entityLoungingIn(p.control.driver),
	-- 	includedTypes = {"creature"}
	-- })

	local dest = p.localToGlobal({3, 2.5})

	for i = 1, #entities do
		local pos = world.distance(dest, world.entityPosition(entities[i]))
		local offset = math.floor(pos[2] + 0.5) * 1000 + math.floor(pos[1] + 500.5)
		world.sendEntityMessage( entities[i], "applyStatusEffect", "succ", 1, offset)
	end
	checkEatPosition( dest, "belly", "succeat", true)
end

-------------------------------------------------------------------------------

p.registerStateScript( "stand", "checkletout", function( args )
	return checkEscapes(args)
end)
p.registerStateScript( "stand", "bellytotail", function( args )
	return moveOccupantLocation(args, "belly", "tail")
end)
p.registerStateScript( "stand", "tailtobelly", function( args )
	return moveOccupantLocation(args, "tail", "belly")
end)
p.registerStateScript( "stand", "eat", function( args )
	return dovore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)
p.registerStateScript( "stand", "taileat", function( args )
	return dovore(args, "tail", {"vsoindicatemaw"}, "swallow")
end)

p.registerStateScript( "stand", "bapeat", function()
	if checkEatPosition(p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position ), "belly", "eat") then return end
	if checkEatPosition(p.localToGlobal({-5, -2}), "tail", "taileat") then return end
end)

p.registerStateScript( "stand", "succ", function( args )
	succ(args)
end)


function state_stand()

	p.idleStateChange()
	extraBellyEffects()
	p.handleBelly()
	local pos1 = p.localToGlobal({3.5, 4})
	local pos2 = p.localToGlobal({-3, 1})

	local pos3 = p.localToGlobal({3.5, -5})
	local pos4 = p.localToGlobal({-3, 0})

	if p.control.probablyOnGround()
	and world.rectCollision( {pos1[1], pos1[2], pos2[1], pos2[2]}, { "Null", "block", "slippery"} )
	and not world.rectCollision( {pos3[1], pos3[2], pos4[1], pos4[2] }, { "Null", "block", "slippery"} )
	then
		if (vehicle.controlHeld( p.control.driver, "left") or vehicle.controlHeld( p.control.driver, "right") )
		and vehicle.controlHeld( p.control.driver, "down") then
			p.doTransition( "crouch" )
			return
		elseif p.settings.autocrouch or not p.control.driving then
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

		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" ) then
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

p.registerStateScript( "sit", "checkletout", function( args )
	return checkEscapes(args)
end)
p.registerStateScript( "sit", "bellytotail", function( args )
	return moveOccupantLocation(args, "belly", "tail")
end)
p.registerStateScript( "sit", "tailtobelly", function( args )
	return moveOccupantLocation(args, "tail", "belly")
end)

p.registerStateScript( "sit", "eat", function( args )
	return dovore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)
p.registerStateScript( "sit", "taileat", function( args )
	return dovore(args, "tail", {"vsoindicatemaw"}, "swallow")
end)

p.registerStateScript( "sit", "hug", function( args )
	return dovore(args, "hug", {})
end)

function state_sit()
	p.standardState()

	if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" ) then
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

p.registerStateScript( "hug", "checkletout", function( args )
	return checkEscapes(args)
end)
p.registerStateScript( "hug", "bellytotail", function( args )
	return moveOccupantLocation(args, "belly", "tail")
end)
p.registerStateScript( "hug", "tailtobelly", function( args )
	return moveOccupantLocation(args, "tail", "belly")
end)
p.registerStateScript( "hug", "eat", function( args )
	return dovore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)
p.registerStateScript( "hug", "taileat", function( args )
	return dovore(args, "tail", {"vsoindicatemaw"}, "swallow")
end)


p.registerStateScript( "hug", "unhug", function( args )
	for i = 1, p.occupants.total do
		if p.occupantLocation[i] == "hug" then
			return doescape({index = i}, "hug", {2.5,0}, {}, {})
		end
	end
end)

state_hug = p.standardState

-------------------------------------------------------------------------------

p.registerStateScript( "crouch", "checkletout", function( args )
	return checkEscapes(args)
end)
p.registerStateScript( "crouch", "bellytotail", function( args )
	return moveOccupantLocation(args, "belly", "tail")
end)
p.registerStateScript( "crouch", "tailtobelly", function( args )
	return moveOccupantLocation(args, "tail", "belly")
end)
p.registerStateScript( "crouch", "taileat", function( args )
	return dovore(args, "tail", {"vsoindicatemaw"}, "swallow")
end)


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

	local pos1 = p.localToGlobal({3.5, 4})
	local pos2 = p.localToGlobal({-3, 1})

	if not world.rectCollision( {pos1[1], pos1[2], pos2[1], pos2[2]}, { "Null", "block", "slippery"} )
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

p.registerStateScript( "fly", "checkletout", function( args )
	return checkEscapes(args)
end)
p.registerStateScript( "fly", "bellytotail", function( args )
	return moveOccupantLocation(args, "belly", "tail")
end)
p.registerStateScript( "fly", "tailtobelly", function( args )
	return moveOccupantLocation(args, "tail", "belly")
end)

p.registerStateScript( "fly", "eat", function( args )
	return dovore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)
p.registerStateScript( "fly", "taileat", function( args )
	return dovore(args, "tail", {"vsoindicatemaw"}, "swallow")
end)
p.registerStateScript( "fly", "analvore", function( args )
	return dovore(args, "belly", {"vsoindicateout"}, "swallow")
end)

p.registerStateScript( "fly", "grabanalvore", function()
	if checkEatPosition(p.localToGlobal({0, -3}), "belly", "analvore") then return end
	if checkEatPosition(p.localToGlobal({-5, -2}), "tail", "taileat") then return end
end)

p.registerStateScript( "fly", "succ", function( args )
	succ(args)
end)



function state_fly()
	p.doAnims(p.stateconfig[p.state].control.animations.fly)

	p.idleStateChange()
	p.handleBelly()
	extraBellyEffects()

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

		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" ) then
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
