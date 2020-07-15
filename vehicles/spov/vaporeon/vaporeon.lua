--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")
--[[

vaporeon plan:

	state chart:
		0   *          sleep
		|   V            |
		0  idle - sit - lay - back
		|   :         \        :
		0   :   sleep - pin - bed - hug
		·   :            V         L
		1  idle - sit - lay - back
		|   :            |
		1   :          sleep
		·   :
		2  idle - sit - lay - sleep

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
	vsoOnInteract( "state_lay", p.onInteraction )
	vsoOnInteract( "state_sleep", p.onInteraction )
	vsoOnInteract( "state_back", p.onInteraction )
	vsoOnInteract( "state_bed", p.onInteraction )
	vsoOnInteract( "state_hug", p.onInteraction )
	vsoOnInteract( "state_pinned", p.onInteraction )
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
-------------------------------------------------------------------------------

p.registerStateScript( "stand", "eat", function( targetid )
	if p.entityLounging( targetid ) then return end
	local food = "food"
	local occupant = "firstOccupant"
	local center = "center"
	if p.occupants == 1 then
		food = "dessert"
		occupant = "secondOccupant"
		center = "center2"
	elseif p.occupants == 2 then
		sb.logError("[Vappy] Can't eat more than two people!")
		return false
	end
	vsoSetTarget( food, targetid )
	if p.eat( vsoGetTargetId( food ), occupant ) then
		vsoMakeInteractive( false )
		p.showEmote("emotehappy")
		vsoVictimAnimSetStatus( occupant, { "vsoindicatemaw" } );
		return true, function()
			p.smolprey() -- clear
			vsoMakeInteractive( true )
			vsoVictimAnimReplay( occupant, center, "bodyState")
			p.setOccupants( p.occupants + 1 )
			vsoSound( "swallow" )
		end
	else
		vsoSetTarget( food, nil )
		return false
	end
end)
p.registerStateScript( "stand", "letout", function( who )
	local food = "food"
	local occupant = "firstOccupant"
	local escape = "escape"
	if who == 2 or (who == nil and p.occupants == 2) then
		food = "dessert"
		occupant = "secondOccupant"
		escape = "escape2"
	elseif p.occupants == 0 then
		sb.logError( "[Vappy] No one to let out!" )
		return false
	end
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( occupant, { "vsoindicatemaw" } );
	p.smolprey( occupant )

	return true, function()
		vsoMakeInteractive( true )
		p.uneat( occupant )
		vsoSetTarget( food, nil )
		vsoUseLounge( false, occupant )
		if vsoGetTargetId( food ) ~= nil then
			vsoApplyStatus( food, "droolsoaked", 5.0 );
		end
		p.setOccupants( p.occupants - 1 )
	end
end)
p.registerStateScript( "stand", "bapeat", function()
	local position = p.localToGlobal( p.stateconfig.stand.control.primaryAction.projectile.position )
	if p.occupants < 2 then
		local prey = world.playerQuery( position, 2 )
		if #prey < 1 and p.control.standalone then
			prey = world.npcQuery( position, 2 )
		end
		if #prey > 0 then
			p.doTransition( "eat", prey[1] )
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
			-- a bit of a hack, prevents the special1 press from activating vappy from also doing this by adding a 10 frame delay before checking if you're pressing it
			p.movement.wasspecial1 = p.movement.wasspecial1 - 1 
		elseif p.control.standalone and vehicle.controlHeld( p.control.driver, "Special1" ) then
			if not p.movement.wasspecial1 then
				-- vsoAnim( "bodyState", "smolify" )
				vsoEffectWarpOut()
				if p.occupants < 2 then
					p.setState( "smol" )
				else
					vsoNext( "state_chonk_ball" )
				end
			end
			p.movement.wasspecial1 = true
		else
			p.movement.wasspecial1 = false
		end
		if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special2" )  then
			if p.occupants > 0 then
				p.doTransition( "escape", p.occupants ) -- last eaten
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

p.registerStateScript( "sit", "pin", function( targetid )
	local pinnable = { targetid }
	-- if not interact target or target isn't in front
	if targetid == nil or p.globalToLocal( world.entityPosition( targetid ) )[1] < 3 then
		local pinbounds = vsoRelativeRect( 2.75, -4, 3.5, -3.5 )
		pinnable = world.playerQuery( pinbounds[1], pinbounds[2] )
		if #pinnable == 0 and p.control.driving then
			pinnable = world.npcQuery( pinbounds[1], pinbounds[2] )
		end
	end
	vsoSetTarget( "food", pinnable[1] )
	if #pinnable >= 1 and p.eat( vsoGetTargetId( "food" ), "firstOccupant" ) then
		vsoVictimAnimSetStatus( "firstOccupant", {} )
		return true
	else
		return true, nil, { -- override transition
			state = "lay",
			animation = "laydown"
		}
	end
end)

state_sit = p.standardState

-----------------------------------------------------------------------------

state_lay = p.standardState

-------------------------------------------------------------------------------

state_sleep = p.standardState

-------------------------------------------------------------------------------

p.registerStateScript( "back", "bed", function( targetid )
	vsoSetTarget( "food", targetid )
	if p.eat( vsoGetTargetId( "food" ), "firstOccupant" ) then
		vsoVictimAnimSetStatus( "firstOccupant", {} );
		return true
	else
		vsoSetTarget( "food", nil )
		return false
	end
end)

function state_back()
	p.standardState()

	-- simulate npc interaction when nearby
	if p.occupants == 0 and p.control.standalone then
		if vsoChance(0.1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", npcs[1] )
			end
		end
	end
end

-------------------------------------------------------------------------------

p.registerStateScript( "bed", "unbed", function()
	vsoSetTarget( "food", nil )
	p.uneat( "firstOccupant" )
	return true
end)

state_bed = p.standardState

-------------------------------------------------------------------------------

p.registerStateScript( "hug", "absorb", function()
	vsoSound( "slurp" )
	return true, function()
		p.setOccupants( 1 )
		p.smolprey() -- clear
		vsoVictimAnimReplay( "firstOccupant", "center", "bodyState")
	end
end)

function state_hug()

	p.standardState()

	if p.control.driving and vehicle.controlHeld( p.control.driver, "jump" ) then
		p.doTransition( "absorb" )
	end

end

-------------------------------------------------------------------------------

p.registerStateScript( "pinned", "unpin", function()
	return true, function()
		vsoSetTarget( "food", nil )
		p.uneat( "firstOccupant" )
	end
end)
p.registerStateScript( "pinned", "absorb", function()
	vsoSound( "slurp" )
	return true, function()
		p.setOccupants( 1 )
		p.smolprey() -- clear
		vsoVictimAnimReplay( "firstOccupant", "center", "bodyState")
	end
end)

function state_pinned()

	p.standardState()
	if p.control.driving then
		p.control.primaryAction() -- lick
	end

	if p.control.driving and vehicle.controlHeld( p.control.driver, "jump" ) then
		p.doTransition( "absorb" )
	end

end

-------------------------------------------------------------------------------

state_pinnedsleep = p.standardState

-------------------------------------------------------------------------------

-- stuff after this point hasn't been migrated yet, only the bare minimum to make things not completely break

function begin_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.smol )
	vsoAnim( "headState", "smol.idle" )
end

function state_smol()

	-- p.handleBelly()
	if p.occupants > 0 then
		p.bellyEffects()
	end
	-- if p.control.probablyOnGround() and p.control.notMoving() then
	-- 	p.handleStruggles()
	-- end

	if p.control.standalone and vehicle.controlHeld( p.control.driver, "Special1" ) then
		if not p.movement.wasspecial1 then
			-- vsoAnim( "bodyState", "unsmolify" )
			vsoEffectWarpIn()
			p.setState( "stand" )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
	p.control.drive()

	p.control.updateDriving()

end

function end_state_smol()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
	vsoAnim( "headState", "idle" )
end

-------------------------------------------------------------------------------

local CurBallFrame
function roll_chonk_ball()
	if CurBallFrame > 11 then
		CurBallFrame = 0
	elseif CurBallFrame < 0 then
		CurBallFrame = 11
	end
	animator.setGlobalTag("rotationFrame", CurBallFrame)
	vsoAnim( "bodyState", "chonk_ball" )
end


function begin_state_chonk_ball()
	animator.setGlobalTag("rotationFlip", self.vsoCurrentDirection)

	mcontroller.applyParameters( self.cfgVSO.movementSettings.chonk_ball )
	CurBallFrame = 0
	BallLastPosition = mcontroller.position()
	vsoAnim( "bodyState", "chonk_ball" )
	--initCommonParameters()
end

function state_chonk_ball()

	if p.occupants > 0 then
		p.bellyEffects()
		-- if not stateQueued() and probablyOnGround() and notMoving() then
		-- 	local escape, who = handleStruggles{ {2, 5}, {5, 15}, {10, 20} }
		-- 	-- local escape, who = handleStruggles{ {1, 1}, {1, 1}, {1, 1} } -- guarantee escape for testing
		-- 	if escape then
		-- 		if p.occupants == 1 then
		-- 			letout( 1 )
		-- 		else
		-- 			if who == 1 then
		-- 				swapOccupants()
		-- 			end
		-- 			letout( 2 )
		-- 		end
		-- 	end
		-- end
	end

	local dx = 0
	local speed = 20
	if p.occupants > 0 then
		speed = 10
	end
	if vehicle.controlHeld( p.control.driver, "down" ) then
		p.movement.downframes = p.movement.downframes + 1
	else
		-- if p.movement.downframes > 0 and p.movement.downframes < 10 and notMoving() and probablyOnGround() then
		-- 	vsoAnim( "bodyState", "sitdown" )
		-- 	nextState( "sit" )
		-- end
		p.movement.downframes = 0
	end
	if vehicle.controlHeld( p.control.driver, "Special1" ) then
		if not p.movement.wasspecial1 then
			-- vsoAnim( "bodyState", "unsmolify" )
			vsoEffectWarpIn()
			vsoNext( "state_stand" )
		end
		p.movement.wasspecial1 = true
	else
		p.movement.wasspecial1 = false
	end
	if vehicle.controlHeld( p.control.driver, "Special2" ) then
		if p.occupants > 0 then
			-- letout( p.occupants ) -- last eaten
		end
	end
	
	-- p.movement controls, use vanilla methods because they need to be held
	if vehicle.controlHeld( p.control.driver, "left" ) then
		dx = dx - 1
		if vsoAnimEnd( "bodyState" ) then
			CurBallFrame = CurBallFrame - 1
			roll_chonk_ball()
		end
	end
	if vehicle.controlHeld( p.control.driver, "right" ) then
		dx = dx + 1
		if vsoAnimEnd( "bodyState" ) then
			CurBallFrame = CurBallFrame + 1
			roll_chonk_ball()
		end
	end

	if not p.control.underWater() then
		if vehicle.controlHeld( p.control.driver, "down" ) then
			speed = 10
			if not probablyOnGround() then
				mcontroller.applyParameters{ ignorePlatformCollision = true }
			end
		else
			mcontroller.applyParameters{ ignorePlatformCollision = false }
		end
	else
		p.movement.jumped = false
		if p.occupants == 2 then
			speed = 10
		end
		if vehicle.controlHeld( p.control.driver, "jump" ) then
			mcontroller.approachYVelocity( 10, 50 )
		else
			mcontroller.approachYVelocity( -10, 50 )
		end
	end
	if not p.control.underWater() then
		p.movement.waswater = false
		mcontroller.setXVelocity( dx * speed )
		if mcontroller.yVelocity() > 0 and vehicle.controlHeld( p.control.driver, "jump" )  then
			mcontroller.approachYVelocity( -100, world.gravity(mcontroller.position()) )
		else
			mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
		end
	else
		p.movement.waswater = true
		mcontroller.approachXVelocity( dx * speed, 50 )
	end
	p.control.updateDriving()
end

function end_state_chonk_ball()
	mcontroller.applyParameters( self.cfgVSO.movementSettings.default )
end
