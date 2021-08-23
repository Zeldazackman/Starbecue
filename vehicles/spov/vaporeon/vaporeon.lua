--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")
--[[

vaporeon plan:

	state chart:
		0	 *			sleep
		|	 V			|
		0	idle - sit - lay - back
		|	 :		 \		:
		0	 :	 sleep - pin - bed - hug
		·	 :			V		 L
		1	idle - sit - lay - back
		|	 :			|
		1	 :			sleep
		·	 :
		2	idle - sit - lay - sleep

	(struggling not included in chart, everything in full has it)

	todo:
	- pills to control the chance of entering/leaving a desired state (and states leading toward it)


	eventually if I can figure out how:
	- walk around
	- follow nearby player
	- eat automatically if low health, to protect (and heal w/ pill)
	- attack enemies
	- ride on back to control
		- shlorp in from back -> control from inside?

]]--

-------------------------------------------------------------------------------

p.vsoMenuName = "vappy"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.

	vsoOnBegin( "state_stand", begin_state_stand )
	vsoOnInteract( "state_stand", interact_state_stand )

	vsoOnBegin( "state_sit", begin_state_sit )
	vsoOnInteract( "state_sit", p.onInteraction )

	vsoOnBegin( "state_lay", begin_state_lay )
	vsoOnInteract( "state_lay", p.onInteraction )

	vsoOnInteract( "state_sleep", p.onInteraction )
	vsoOnInteract( "state_back", p.onInteraction )
	vsoOnInteract( "state_hug", p.onInteraction )
	vsoOnInteract( "state_pinned_sleep", p.onInteraction )

	vsoOnBegin( "state_smol", begin_state_smol )
	vsoOnEnd( "state_smol", end_state_smol )

	vsoOnBegin( "state_chonk_ball", begin_state_chonk_ball )
	vsoOnEnd( "state_chonk_ball", end_state_chonk_ball )

end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function p.whenFalling()
	if p.state ~= ("stand" or "smol" or "chonk_ball") and mcontroller.yVelocity() < -5 then
		p.setState( "stand" )
		p.doAnims( p.stateconfig[p.state].control.animations.fall )
		p.movement.falling = true
		for i = 1, p.occupants.total do
			if p.occupant[i].location == "hug" then
				p.uneat(i)
			end
		end
	end
end

function fixOccupantCenters(location, anim, part)
	for i = 1, p.occupants.total do
		if p.occupant[i].location == location then
			vsoVictimAnimReplay( "occupant"..i, anim, part.."State")
		end
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end)

p.registerStateScript( "stand", "letout", function( args )
	return p.doEscape(args, "belly", {3.5, -1.875}, {"vsoindicatemaw"}, {"droolsoaked", 5} )
end)

p.registerStateScript( "stand", "bapeat", function()
	if p.checkEatPosition(p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position ), "belly", "eat") then return end
end)

function begin_state_stand()
	fixOccupantCenters("belly", "bellycenter", "body")
end

function state_stand()

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
			-- a bit of a hack, prevents the special1 press from activating vappy from also doing this by adding a 10 frame delay before checking if you're pressing it
			p.movement.wasspecial1 = p.movement.wasspecial1 - 1
		elseif p.control.standalone and vehicle.controlHeld( p.control.driver, "Special1" ) then
			if not p.movement.wasspecial1 then
				p.movement.wasspecial1 = true
				vsoEffectWarpOut()
				if p.occupants.belly < 2 then
					p.setState( "smol" )
					p.doAnims( p.stateconfig.smol.idle, true )
				else
					p.setState( "chonk_ball" )
					p.doAnims( p.stateconfig.chonk_ball.idle, true )
				end
				return
			end
		else
			p.movement.wasspecial1 = false
		end
		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" ) then
			if p.occupants.belly > 0 then
				p.doTransition( "escape", {index=p.occupants.belly} ) -- last eaten
			end
		end
		p.control.drive()
	end

end

function interact_state_stand( occupantId )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( occupantId )
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "sit", "pin", function( args )
	local pinnable = { args.id }
	-- if not interact target or target isn't in front
	if args.id == nil or p.globalToLocal( world.entityPosition( args.id ) )[1] < 3 then
		local pinbounds = vsoRelativeRect( 2.75, -4, 3.5, -3.5 )
		pinnable = world.playerQuery( pinbounds[1], pinbounds[2] )
		if #pinnable == 0 and p.control.driving then
			pinnable = world.npcQuery( pinbounds[1], pinbounds[2] )
		end
	end
	local index = p.occupants.total + 1
	if #pinnable >= 1 and p.eat( pinnable[1], index, "hug" ) then
		--vsoVictimAnimSetStatus( "occupant"..index , {} )
	end
	return true
end)

function begin_state_sit()
	fixOccupantCenters("belly", "bellycentersit", "body")
end

state_sit = p.standardState

-------------------------------------------------------------------------------

p.registerStateScript( "lay", "unpin", function(args)
	local returnval = {}
	returnval[1], returnval[2], returnval[3] = p.doEscape({index = p.findFirstIndexForLocation("hug")}, "hug", {1.3125, -2.0}, {}, {})
	return true, returnval[2], returnval[3]
end)

p.registerStateScript( "lay", "absorb", function(args)
	return LayAbsorb()
end)

function LayAbsorb()
	local index = p.findFirstIndexForLocation("hug")
	if not index then return false end

	animator.playSound( "slurp" )
	return true, function()
		p.occupant[index].location = "belly"
		vsoVictimAnimReplay( "occupant"..index, "bellycenterlay", "bodyState")
	end
end

function begin_state_lay()
	fixOccupantCenters("belly", "bellycenterlay", "body")
end

function state_lay()
	p.standardState()

	if p.control.driving then
		p.control.primaryAction() -- lick
	end

	if p.control.driving and vehicle.controlHeld( p.control.driver, "jump" ) then
		p.doTransition( "absorb" )
	end

end

-------------------------------------------------------------------------------

p.registerStateScript( "sleep", "absorb", function(args)
	return LayAbsorb()
end)

function state_sleep()
	p.standardState()

	if p.control.driving and vehicle.controlHeld( p.control.driver, "jump" ) then
		p.doTransition( "absorb" )
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "back", "bed", function( args )
	local index = p.occupants.total + 1

	if p.eat( args.id, index, "hug" ) then
		--vsoVictimAnimSetStatus( "occupant"..index, {} );
		return true
	else
		return false
	end
end)

function state_back()
	p.standardState()

	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and p.control.standalone then
		if p.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

p.registerStateScript( "back", "unbed", function(args)
	return p.doEscapeNoDelay({index = p.findFirstIndexForLocation("hug")}, "hug", {1.3125, -2.0}, {})
end)

-------------------------------------------------------------------------------

p.registerStateScript( "hug", "absorb", function(args)
	local index = p.findFirstIndexForLocation("hug")
	if not index then return false end

	animator.playSound( "slurp" )
	return true, function()
		p.occupant[index].location = "belly"
		vsoVictimAnimReplay( "occupant"..index, "bellycenterlay", "bodyState")
	end
end)

function state_hug()

	p.standardState()

	if p.control.driving and vehicle.controlHeld( p.control.driver, "jump" ) then
		p.doTransition( "absorb" )
	end

end

-------------------------------------------------------------------------------

state_pinnedsleep = p.standardState

-------------------------------------------------------------------------------

function begin_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.smol )
	fixOccupantCenters("belly", "smolbellycenter", "body")
end

function state_smol()

	p.idleStateChange()
	p.handleBelly()

	if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special1" ) then
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
	p.control.drive()

	p.updateDriving()

end

function end_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end

-------------------------------------------------------------------------------

local CurBallFrame = 0
function roll_chonk_ball(dx, control)
	mcontroller.setXVelocity( dx * control.walkSpeed)
	if dx ~= 0 and vsoAnimEnd( "bodyState" ) then
		CurBallFrame = CurBallFrame + dx
		if CurBallFrame > 11 then
			CurBallFrame = 0
		elseif CurBallFrame < 0 then
			CurBallFrame = 11
		end
		animator.setGlobalTag("rotationFrame", CurBallFrame)
		p.doAnim( "bodyState", "chonk_ball" )
	end
end

function begin_state_chonk_ball()
	animator.setGlobalTag("rotationFlip", self.vsoCurrentDirection)

	mcontroller.applyParameters( self.cfgVSO.movementSettings.chonk_ball )
	CurBallFrame = 0
	BallLastPosition = mcontroller.position()

	fixOccupantCenters("belly", "center", "body")
end

function state_chonk_ball()
	p.handleBelly()
	p.doPhysics()
	if p.occupants.belly < 2 then
		vsoEffectWarpIn()
		p.setState( "smol" )
		p.doAnims( p.stateconfig.smol.idle, true )
	end

	local control = p.stateconfig[p.state].control

	local dx = 0
	local dy = 0

	if p.control.driving then
		if vehicle.controlHeld( p.control.driver, "Special1" ) then
			if not p.movement.wasspecial1 then
				p.movement.wasspecial1 = true
				vsoEffectWarpIn()
				p.setState( "stand" )
				p.doAnims( p.stateconfig.stand.idle, true )
				return
			end
		else
			p.movement.wasspecial1 = false
		end
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
			p.movement.jumped = true
		end
	end

	if dy == -1 and p.movement.jumped then
		mcontroller.applyParameters{ ignorePlatformCollision = true }
	else
		mcontroller.applyParameters{ ignorePlatformCollision = false }
	end

	if p.control.underWater() then
		mcontroller.approachYVelocity( 11, 50 ) --this should make ball vappy float on the surface of water haha
	end

	roll_chonk_ball(dx, control)

	p.updateDriving()
end

function end_state_chonk_ball()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end
