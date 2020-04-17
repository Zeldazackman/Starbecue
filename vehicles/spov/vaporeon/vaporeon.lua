--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")

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

function loadStoredData()
	vsoStorageSaveAndLoad( function()	--Get defaults from the item spawner itself
		if storage.colorReplaceMap ~= nil then
			vsoSetDirectives( vsoMakeColorReplaceDirectiveString( storage.colorReplaceMap ) );
		end
	end )
end

function showEmote( emotename )	--helper function to express a emotion particle	"emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if vsoTimeDelta( "emoteblock" ) > 0.2 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
	end
end

function escapePillChoice(list)
	if vsoPill( "easyescape" ) then return list[1] end
	if vsoPill( "antiescape" ) then return list[3] end
	return list[2]
end

local _qoccupants
function nextOccupants(occupants)
	_qoccupants = occupants
end

local _occupants = 0
function setOccupants(occupants)
	_occupants = occupants
	animator.setGlobalTag( "occupants", tostring(occupants) )
end

function getOccupants()
	return _occupants
end

local _qstate
function nextState(state, manual)
	_qstate = state
	vsoNext( "state_"..state )
end

local _qaction
function nextAction(func)
	_qaction = func
end

local _state
local _pstate
local _struggling
function updateState()
	if _struggling then
		_struggling = false
		vsoAnim( "bodyState", "look" )
		return false
	else
		vsoCounterReset( "struggleCount" )
	end
	if _qstate ~= nil then
		_pstate = _state
		_state = _qstate
		animator.setGlobalTag( "state", _qstate )
		_qstate = nil
	end
	if _qoccupants ~= nil then
		setOccupants(_qoccupants)
		_qoccupants = nil
	end
	if _qaction ~= nil then
		_qaction()
		_qaction = nil
	end
	return true
end

function resetState(state)
	_pstate = state
	_state = state
	animator.setGlobalTag( "state", state )
	vsoNext( "state_"..state )
end

function previousState()
	return _pstate
end

function stateQueued()
	return _struggling or _qstate ~= nil or _qoccupants ~= nil
end

local _controlmode = 0
function controlState()
	return _controlmode == 1
end
function controlSeat()
	return "firstOccupant"
end

function updateControlMode()
	if controlSeat() == "driver" then
		vsoVictimAnimSetStatus( "driver", { "breathprotectionvehicle" } )
		_controlmode = 1
		if vehicle.controlHeld( controlSeat(), "Special3" ) then
			world.sendEntityMessage( vehicle.entityLoungingIn( controlSeat() ), "openvappysettings", entity.id() )
		end
	elseif vsoGetTargetId( "food" ) ~= nil then
		if vehicle.controlHeld( controlSeat(), "Special1" ) then
			_controlmode = 1
		end
		if vehicle.controlHeld( controlSeat(), "Special2" ) then
			_controlmode = 0
		end
	else
		_controlmode = 0
	end
end

local bellyeffect = ""
function bellyEffects()
	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then
		vsoSound( "digest" )
	end
	vsoVictimAnimSetStatus( "firstOccupant", { "vsoindicatebelly", "breathprotectionvehicle" } )

	local effect = 0
	if bellyeffect == "digest" or bellyeffect == "softdigest" then
		effect = -1
	elseif bellyeffect == "heal" then
		effect = 1
	end
	if getOccupants() > 1 then
		vsoVictimAnimSetStatus( "firstOccupant", { "vsoindicatebelly", "breathprotectionvehicle" } )
			if effect ~= 0 then
			local health_change = effect * vsoDelta()
			local health = world.entityHealth( vsoGetTargetId("dessert") )
			if bellyeffect == "softdigest" and health[1]/health[2] <= -health_change then
				health_change = (1 - health[1]) / health[2]
			end
			vsoResourceAddPercent( vsoGetTargetId("dessert"), "health", health_change, function(still_alive)
				if not still_alive then
					vsoUneat( "secondOccupant" )

					vsoSetTarget( "dessert", nil )
					vsoUseLounge( false, "secondOccupant" )
					setOccupants(1)
				end
			end)
		end
	end
	if effect ~= 0 then
		local health_change = effect * vsoDelta()
		local health = world.entityHealth( vsoGetTargetId("food") )
		if bellyeffect == "softdigest" and health[1]/health[2] <= -health_change then
			health_change = (1 - health[1]) / health[2]
		end
		vsoResourceAddPercent( vsoGetTargetId("food"), "health", health_change, function(still_alive)
			if not still_alive then
				vsoUneat( "firstOccupant" )

				vsoSetTarget( "food", nil )
				vsoUseLounge( false, "firstOccupant" )
				setOccupants(0)
			end
		end)
	end
end

function handleStruggles(success_chances)
	local movetype, movedir = vso4DirectionInput( "firstOccupant" )
	local struggler = 1
	if movetype == 0 then
		movetype, movedir = vso4DirectionInput( "secondOccupant" )
		struggler = 2
		if movetype == 0 then return false end
	end

	if controlState() and struggler == 1 and controlSeat() == "firstOccupant" then
		return false -- control vappy instead of struggling
	end

	local chance
	if not controlState() then -- controller handles escape
		chance = escapePillChoice(success_chances)
	end
	if chance ~= nil
	and vsoCounterValue( "struggleCount" ) >= chance[1]
	and vsoCounterChance( "struggleCount", chance[1], chance[2] ) then
		vsoCounterReset( "struggleCount" )
		return true, struggler, movedir
	end

	local anim = nil
	if movedir == "B" then anim = "s_left" end
	if movedir == "F" then anim = "s_right" end
	if movedir == "U" then anim = "s_up" end
	if movedir == "D" then anim = "s_down" end

	if anim ~= nil then
		vsoAnim( "bodyState", anim )
		vsoSound( "struggle" )
		vsoCounterAdd( "struggleCount", 1 )
		_struggling = true
	end

	return false
end

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	vsoAnimSpeed( 1.0 );
	vsoVictimAnimVisible( "firstOccupant", false )
	vsoUseLounge( false, "firstOccupant" )
	vsoVictimAnimVisible( "secondOccupant", false )
	vsoUseLounge( false, "secondOccupant" )
	vsoUseSolid( false )

	setOccupants(0)
	resetState( "stand" )
	vsoAnim( "bodyState", "idle" )

	vsoMakeInteractive( true )

	vsoTimeDelta( "emoteblock" ) -- without this, the first call to showEmote() does nothing
end

function onBegin()	--This sets up the VSO ONCE.

	vsoEffectWarpIn();	--Play warp in effect
	if standaloneinit ~= nil then
		standaloneinit()
	end

	onForcedReset();	--Do a forced reset once.

	vsoStorageLoad( loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	vsoOnInteract( "state_stand", interact_state_stand )
	vsoOnInteract( "state_sit", interact_state_sit )
	vsoOnInteract( "state_lay", interact_state_lay )
	vsoOnInteract( "state_sleep", interact_state_sleep )
	vsoOnInteract( "state_back", interact_state_back )
	vsoOnInteract( "state_pinned", interact_state_pinned )
	vsoOnInteract( "state_pinned_sleep", interact_state_pinned_sleep )

	-- mMotionParametersSet( mParams() )

	if vsoPill( "heal" ) then bellyeffect = "heal" end
	if vsoPill( "digest" ) then bellyeffect = "digest" end
	if vsoPill( "softdigest" ) then bellyeffect = "softdigest" end

	message.setHandler( "settingsMenuGet", settingsMenuGet )
	message.setHandler( "settingsMenuSet", settingsMenuSet )
	message.setHandler( "despawn", _vsoOnDeath )
end

function onEnd()

	vsoEffectWarpOut();

end

-------------------------------------------------------------------------------

function settingsMenuGet()
	return {
		bellyeffect = bellyeffect,
		clickmode = "attack" -- todo
	}
end

function settingsMenuSet(_,_, key, val )
	if key == "bellyeffect" then
		bellyeffect = val
	elseif key == "clickmode" then
		-- todo
	end
end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

local movement = {
	jumps = 0,
	jumped = false,
	waswater = false,
	bapped = 0,
	downframes = 0,
	groundframes = 0,
	run = false
}
function probablyOnGround() -- check number of frames -> ceiling isn't ground
	local yvel = mcontroller.yVelocity()
	if yvel < 0.1 and yvel > -0.1 then
		movement.groundframes = movement.groundframes + 1
	else
		movement.groundframes = 0
	end
	return movement.groundframes > 2
end
function notMoving()
	local xvel = mcontroller.xVelocity()
	return xvel < 0.1 and xvel > -0.1
end
function underWater()
	return mcontroller.liquidPercentage() >= 0.2
end
function doPhysics()
	if not underWater() then
		mcontroller.setXVelocity( 0 )
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	else
		mcontroller.approachYVelocity( 0, 50 )
		mcontroller.approachYVelocity( -10, 50 )
	end
	if _state ~= "stand" and mcontroller.yVelocity() < -5 then
		sb.logInfo( "falling" )
		nextState( "stand" )
		updateState()
		vsoAnim( "bodyState", "fall" )
		if _state == "bed" or _state == "hug" or _state == "pinned" or _state == "pinned_sleep" then
			vsoUneat( "firstOccupant" )
			vsoSetTarget( "food", nil )
			vsoUseLounge( false, "firstOccupant" )
		end
	end
end

function eat( targetid )
	if targetid == vehicle.entityLoungingIn( controlSeat() ) then return end
	if targetid == vehicle.entityLoungingIn( "firstOccupant" ) then return end
	if targetid == vehicle.entityLoungingIn( "secondOccupant" ) then return end
	local food = "food"
	local occupant = "firstOccupant"
	local playereat = "playereat"
	local center = "center"
	if getOccupants() == 1 then
		food = "dessert"
		occupant = "secondOccupant"
		playereat = "playereat2"
		center = "center2"
	elseif getOccupants() == 2 then
		sb.logError("[Vappy] Can't eat more than two people!")
		return
	end
	vsoMakeInteractive( false )
	showEmote("emotehappy")
	vsoAnim( "bodyState", "eat" )
	vsoVictimAnimReplay( occupant, playereat, "bodyState")
	nextOccupants( getOccupants() + 1 )

	vsoSetTarget( food, targetid )
	vsoUseLounge( true, occupant )
	vsoEat( vsoGetTargetId( food ), occupant )
	vsoVictimAnimSetStatus( occupant, { "vsoindicatemaw" } );
	vsoSound( "swallow" )
	nextAction(function()
		vsoMakeInteractive( true )
		vsoVictimAnimReplay( occupant, center, "bodyState")
	end)
end
function swapOccupants()
	local food = vsoGetTargetId("food")
	vsoSetTarget( "food", vsoGetTargetId("dessert") )
	vsoSetTarget( "dessert", food )

	vsoUneat( "firstOccupant" )
	vsoUneat( "secondOccupant" )
	vsoEat( vsoGetTargetId("food"), "firstOccupant" )
	vsoEat( vsoGetTargetId("dessert"), "secondOccupant" )
end
function letout()
	local food = "food"
	local occupant = "firstOccupant"
	local escape = "escape"
	if getOccupants() == 2 then
		food = "dessert"
		occupant = "secondOccupant"
		escape = "escape2"
	elseif getOccupants() == 0 then
		sb.logError( "[Vappy] No one to let out!" )
	end
	vsoMakeInteractive( false )
	vsoVictimAnimSetStatus( occupant, { "vsoindicatemaw" } );
	if vsoGetTargetId( food ) ~= nil then
		vsoApplyStatus( food, "droolsoaked", 5.0 );
	end
	vsoAnim( "bodyState", "escape" )
	vsoVictimAnimReplay( occupant, escape, "bodyState")
	nextOccupants( getOccupants() - 1 )
	nextAction(function()
		vsoMakeInteractive( true )
		vsoUneat( occupant )
		vsoSetTarget( food, nil )
		vsoUseLounge( false, occupant )
	end)
end

function state_stand()

	local anim = vsoAnimCurr( "bodyState" );

	if probablyOnGround() then
		if vsoAnimEnd( "bodyState" ) and updateState() then
			local idle = false
			if controlState() then
				idle = true
			else
				local percent = vsoRand(100)
				if percent < 5 then -- and previousState() ~= "sit" then -- needs a timer
					vsoAnim( "bodyState", "sitdown" )
					nextState( "sit" )
				else
					idle = true
				end
			end
			if idle then
				local percent = vsoRand(100)
				if percent < 15 then
					vsoAnim( "bodyState", "tail_flick" )
				elseif percent < 15+15 then
					vsoAnim( "bodyState", "blink" )
				else
					vsoAnim( "bodyState", "idle" )
				end
			end
		end
	elseif vsoAnimEnd( "bodyState" ) then
		if mcontroller.yVelocity() > 0 then
			vsoAnim( "bodyState", "jumpcont" )
		else
			vsoAnim( "bodyState", "fallcont" )
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() and probablyOnGround() and notMoving() then
			local escape, who = handleStruggles{ {2, 5}, {5, 15}, {10, 20} }
			-- local escape, who = handleStruggles{ {1, 1}, {1, 1}, {1, 1} } -- guarantee escape for testing
			if escape then
				if getOccupants() == 1 then
					letout( 1 )
				else
					if who == 1 then
						swapOccupants()
					end
					letout( 2 )
				end
			end
		end
	end

	if controlState() then
		local dx = 0
		local speed = 20
		if getOccupants() == 2 then
			speed = 10
		end
		if probablyOnGround() or underWater() then
			movement.jumps = 0
		end
		if not stateQueued() then
			if vehicle.controlHeld( controlSeat(), "down" ) then
				movement.downframes = movement.downframes + 1
			else
				if movement.downframes > 0 and movement.downframes < 10 and notMoving() and probablyOnGround() then
					vsoAnim( "bodyState", "sitdown" )
					nextState( "sit" )
				end
				movement.downframes = 0
			end
			if controlSeat() == "driver" and vehicle.controlHeld( controlSeat(), "Special2" ) then
				if getOccupants() > 0 then
					letout( getOccupants() ) -- last eaten
				end
			end
			if vehicle.controlHeld( controlSeat(), "PrimaryFire" ) then
				if movement.bapped < 1 then
					local mposition = mcontroller.position()
					local direction = self.vsoCurrentDirection
					local position = { mposition[1] + 3 * direction, mposition[2] - 2.5 }
					world.spawnProjectile(
						"vapbap",
						position,
						entity.id(),
						{ direction, 0 }
					)
					vsoAnim( "bodyState", "bap" )
					if getOccupants() < 2 then
						local prey = world.playerQuery( position, 2 )
						if #prey > 0 then
							eat( prey[1] )
						elseif controlSeat() == "driver" then
							prey = world.npcQuery( position, 2 )
							if #prey > 0 then
								eat( prey[1] )
							end
						end
					end
					movement.bapped = 30
					world.entityQuery( position, 2,
						{
							withoutEntityId = entity.id(), -- don't interact with self
							callScript = "onInteraction",
							callScriptArgs = { {
								source = { 0, 0 },
								sourceId = vehicle.entityLoungingIn( controlSeat() )
							} }
						}
					)
				end
			end
			movement.bapped = movement.bapped - 1
		end
		if not stateQueued() then
			-- movement controls, use vanilla methods because they need to be held
			if vehicle.controlHeld( controlSeat(), "left" ) then
				dx = dx - 1
			end
			if vehicle.controlHeld( controlSeat(), "right" ) then
				dx = dx + 1
			end
			if dx ~= 0 then
				vsoFaceDirection( dx )
			end
			if not underWater() then
				if vehicle.controlHeld( controlSeat(), "down" ) then
					speed = 10
					if not probablyOnGround() then
						mcontroller.applyParameters{ ignorePlatformCollision = true }
					end
				else
					mcontroller.applyParameters{ ignorePlatformCollision = false }
				end
				if vehicle.controlHeld( controlSeat(), "jump" ) then
					if not vehicle.controlHeld( controlSeat(), "down" ) then
						if movement.jumps < 2 and not movement.jumped then
							movement.jumps = 1
							if not probablyOnGround() and not movement.waswater then
								movement.jumps = 2
								-- particles from effects/multiJump.effectsource
								animator.burstParticleEmitter( "doublejump" )
								for i = 1,6 do -- 2x because we big
									animator.burstParticleEmitter( "defaultblue" )
									animator.burstParticleEmitter( "defaultlightblue" )
								end
								vsoSound( "doublejump" )
							end
							vsoAnim( "bodyState", "jump" )
							if getOccupants() < 2 then
								mcontroller.setYVelocity( 50 )
							else
								mcontroller.setYVelocity( 20 )
							end
						end
						movement.jumped = true
					else
						mcontroller.applyParameters{ ignorePlatformCollision = true }
					end
				else
					movement.jumped = false
				end
			else
				movement.jumped = false
				if getOccupants() == 2 then
					speed = 10
				end
				if vehicle.controlHeld( controlSeat(), "jump" ) then
					mcontroller.approachYVelocity( 10, 50 )
				else
					mcontroller.approachYVelocity( -10, 50 )
				end
			end
			if not vsoAnimIs( "bodyState", "bap" ) then
				if probablyOnGround() then
					if dx ~= 0 then
						if speed == 10 and not vsoAnimIs( "bodyState", "walk" ) then
							vsoAnim( "bodyState", "walk" )
						elseif speed == 20 and not vsoAnimIs( "bodyState", "run" ) then
							vsoAnim( "bodyState", "run" )
						end
					else
						vsoAnim( "bodyState", "idle" )
					end
				elseif underWater() then
					if vehicle.controlHeld( controlSeat(), "jump" )
					or vehicle.controlHeld( controlSeat(), "down" )
					or vehicle.controlHeld( controlSeat(), "left" )
					or vehicle.controlHeld( controlSeat(), "right" ) then
						vsoAnim( "bodyState", "swim" )
					else
						vsoAnim( "bodyState", "swimidle" )
					end
				else
					if mcontroller.yVelocity() < -30 and not vsoAnimIs( "bodyState", "fall" ) and not vsoAnimIs( "bodyState", "fallcont" ) then
						vsoAnim( "bodyState", "fall" )
					end
				end
			end
		end
		if not underWater() then
			movement.waswater = false
			mcontroller.setXVelocity( dx * speed )
			if mcontroller.yVelocity() > 0 and vehicle.controlHeld( controlSeat(), "jump" )  then
				mcontroller.approachYVelocity( -100, world.gravity(mcontroller.position()) )
			else
				mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
			end
		else
			movement.waswater = true
			mcontroller.approachXVelocity( dx * speed, 50 )
		end
		if vehicle.controlHeld( controlSeat(), "AltFire" ) then
			local aiming = vehicle.aimPosition( controlSeat() )
			local mposition = mcontroller.position()
			local direction = -1
			if aiming[1] > mposition[1] then direction = 1 end
			vsoFaceDirection( direction )
			local position = { mposition[1] + direction * 2.75, mposition[2] - 0.125 }
			world.spawnProjectile(
				"vapwatergun",
				position,
				entity.id(),
				{ aiming[1] - position[1], aiming[2] - position[2] + 0.2*direction*(aiming[1] - position[1]) }
			)
		end
	else

		doPhysics()
	end
	updateControlMode()
end

function interact_state_stand( targetid )
	if not stateQueued() and mcontroller.yVelocity() > -5 then

		-- vsoAnim( "bodyState", "idle_back" )
		-- vsoNext( "state_idle_back" ) -- jump to currently worked on state to test
		-- return

		if getOccupants() < 2 and not controlState() then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 2 then -- target in front
				eat( targetid )
			else
				if vsoChance(20) then
					vsoAnim( "bodyState", "sitdown" )
					nextState( "sit" )
				else
					showEmote("emotehappy")
					vsoAnim( "bodyState", "pet" )
				end
			end
		else
			if vsoChance(20) and not controlState() then
				vsoAnim( "bodyState", "sitdown" )
				nextState( "sit" )
			else
				showEmote("emotehappy")
				vsoAnim( "bodyState", "pet" )
			end
		end

	end
end

-------------------------------------------------------------------------------

function sitPin( targetid )
	vsoUseLounge( true, "firstOccupant" )
	vsoSetTarget( "food", targetid )
	vsoEat( vsoGetTargetId("food"), "firstOccupant" )
	vsoVictimAnimSetStatus( "firstOccupant", {} )
	vsoAnim( "bodyState", "pin" )
	vsoVictimAnimReplay( "firstOccupant", "sitpinned", "bodyState")
	nextState( "pinned" )
end

function state_sit()

	local pin_bounds = vsoRelativeRect( 2.75, -4, 3.5, -3.5 )
	vsoDebugRect( pin_bounds[1][1], pin_bounds[1][2], pin_bounds[2][1], pin_bounds[2][2] )

	if vsoAnimEnd( "bodyState" ) and updateState() then

		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "standup" )
				nextState( "stand" )
			elseif percent < 5+7 then
				local pinnable = {}
				if getOccupants() == 0 then
					pinnable = world.playerQuery( pin_bounds[1], pin_bounds[2] )
				end
				if #pinnable == 1 then
					sitPin( pinnable[1] )
				else
					vsoAnim( "bodyState", "laydown" )
					nextState( "lay" )
				end
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if handleStruggles{ {2, 5}, {5, 15}, {10, 20} } then
				vsoAnim( "bodyState", "standup" )
				nextState( "stand" )
			end
		end
	end

	if controlState() and not stateQueued() then
		local movetype, movedir = vso4DirectionInput( controlSeat() )
		if movetype > 0 then
			if movedir == "U" or movedir == "F" or movedir == "B" or movedir == "J" then
				vsoAnim( "bodyState", "standup" )
				nextState( "stand" )
			end
			if movedir == "D" then
				local pinnable = {}
				if getOccupants() == 0 then
					pinnable = world.playerQuery( pin_bounds[1], pin_bounds[2] )
				end
				if #pinnable == 1 then
					sitPin( pinnable[1] )
				else
					vsoAnim( "bodyState", "laydown" )
					nextState( "lay" )
				end
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_sit( targetid )
	if not stateQueued() then

		if vsoChance(20) and not controlState() then
			local relative = {0}
			if getOccupants() == 0 then
				local position = world.entityPosition( targetid )
				relative = vsoRelativePoint( position[1], position[2] )
			end
			if relative[1] > 2 then -- target in front
				sitPin( targetid )
			else
				vsoAnim( "bodyState", "standup" )
				nextState( "stand" )
			end
		else
			showEmote("emotehappy");
			vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_lay()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "situp" )
				nextState( "sit" )
			elseif percent < 5+5 then
				vsoAnim( "bodyState", "fallasleep" )
				nextState( "sleep" )
			elseif percent < 5+5+10 and getOccupants() < 2 then
				vsoAnim( "bodyState", "rollover" )
				nextState( "back" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if handleStruggles{ {2, 10}, {10, 20}, {20, 40} } then
				vsoAnim( "bodyState", "situp" )
				nextState( "sit" )
			end
		end
	end

	if controlState() and not stateQueued() then
		local movetype, movedir = vso4DirectionInput( controlSeat() )
		if movetype > 0 then
			if movedir == "U" then
				vsoAnim( "bodyState", "situp" )
				nextState( "sit" )
			end
			if movedir == "F" or movedir == "B" and getOccupants() < 2 then
				vsoAnim( "bodyState", "rollover" )
				nextState( "back" )
			end
			if movedir == "D" then
				vsoAnim( "bodyState", "fallasleep" )
				nextState( "sleep" )
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_lay( targetid )
	if not stateQueued() then

		local percent = vsoRand(100)
		if percent < 10 and not controlState() then
			vsoAnim( "bodyState", "situp" )
			nextState( "sit" )
		elseif percent < 10+10 and getOccupants() < 2 and not controlState() then
			vsoAnim( "bodyState", "rollover" )
			nextState( "back" )
		else
			showEmote("emotehappy");
			vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "lay" )
			else
				idle = true
			end
		end
		if idle then
			-- local percent = vsoRand(100)
			-- if percent < 15 then
			-- 	vsoAnim( "bodyState", "tail_flick" )
			-- elseif percent < 15+15 then
			-- 	vsoAnim( "bodyState", "blink" )
			-- else
				vsoAnim( "bodyState", "idle" )
			-- end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if handleStruggles{ {5, 15}, {20, 40}, nil } then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "lay" )
			end
		end
	end

	if controlState() and not stateQueued() then
		local movetype, movedir = vso4DirectionInput( controlSeat() )
		if movetype > 0 then
			if movedir == "U" then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "lay" )
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_sleep( targetid )
	if not stateQueued() then

		local percent = vsoRand(100)
		if percent < 15 and not controlState() then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "lay" )
		else
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_back()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "rollover" )
				nextState( "lay" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if handleStruggles{ {5, 15}, {20, 40}, nil } then
				vsoAnim( "bodyState", "rollover" )
				nextState( "lay" )
			end
		end
	end

	if controlState() and not stateQueued() then
		local movetype, movedir = vso4DirectionInput( controlSeat() )
		if movetype > 0 then
			if movedir == "F" or movedir == "B" then
				vsoAnim( "bodyState", "rollover" )
				nextState( "lay" )
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_back( targetid )
	if not stateQueued() then

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 3 then -- target in front
				showEmote("emotehappy");
				vsoAnim( "bodyState", "pet" )
			else
				nextState( "bed" )
				updateState()
				vsoAnim( "bodyState", "idle" )
				vsoUseLounge( true, "firstOccupant" )
				vsoSetTarget( "food", targetid )
				vsoEat( targetid, "firstOccupant" )
				vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
				vsoVictimAnimSetStatus( "firstOccupant", {} );
			end
		else
			showEmote("emotehappy");
			vsoAnim( "bodyState", "pet" )
		end

	end
end

-------------------------------------------------------------------------------

function state_bed() -- only accessible with no occupants

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			local hugChance = escapePillChoice{5, 5, 20}
			if percent < hugChance then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellyhug", "bodyState")
				nextState( "hug" )
			elseif percent < hugChance+hugChance then
				vsoAnim( "bodyState", "rollover" )
				vsoVictimAnimReplay( "firstOccupant", "pinned", "bodyState")
				nextState( "pinned" )
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	updateControlMode()
	if not stateQueued() then
		if not controlState() or controlSeat() == "driver" then
			if vsoHasAnySPOInputs( "firstOccupant" ) then
				nextState( "back" )
				updateState()
				vsoAnim( "bodyState", "idle" )
				vsoUneat( "firstOccupant" )
				vsoSetTarget( "food", nil )
				vsoUseLounge( false, "firstOccupant" )
			end
		end
		if controlState() then
			local movetype, movedir = vso4DirectionInput( controlSeat() )
			if movetype > 0 then
				if movedir == "D" then
					vsoAnim( "bodyState", "grab" )
					vsoVictimAnimReplay( "firstOccupant", "bellyhug", "bodyState")
					nextState( "hug" )
				end
				if movedir == "F" or movedir == "B" then
					vsoAnim( "bodyState", "rollover" )
					vsoVictimAnimReplay( "firstOccupant", "pinned", "bodyState")
					nextState( "pinned" )
				end
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_bed( targetid )
	if not stateQueued() then

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 3 then -- target in front
				showEmote("emotehappy");
				vsoAnim( "bodyState", "pet" )
			end
		end

	end
end

-------------------------------------------------------------------------------

function hugAbsorb()
	vsoSound( "slurp" )
	vsoAnim( "bodyState", "absorb" )
	vsoVictimAnimReplay( "firstOccupant", "absorbback", "bodyState")
	nextOccupants( 1 )
	nextState( "back" )
	nextAction(function()
		vsoVictimAnimReplay( "firstOccupant", "center", "bodyState")
	end)
end

function state_hug()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			local unhugChance = escapePillChoice{10, 5, 1}
			local absorbChance = escapePillChoice{1, 5, 10}
			if percent < unhugChance then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
				nextState( "bed" )
			elseif percent < unhugChance+absorbChance then
				hugAbsorb()
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			-- elseif percent < 15+15 then
			-- 	vsoAnim( "bodyState", "blink" )
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	updateControlMode()
	if not stateQueued() then
		if not controlState() then
			if vsoHasAnySPOInputs( "firstOccupant" ) and vsoPill( "easyescape" ) then
				vsoAnim( "bodyState", "grab" )
				vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
				nextState( "bed" )
			end
		else
			local movetype, movedir = vso4DirectionInput( controlSeat() )
			if movetype > 0 then
				if movedir == "U" then
					vsoAnim( "bodyState", "grab" )
					vsoVictimAnimReplay( "firstOccupant", "bellybed", "bodyState")
					nextState( "bed" )
				end
				if movedir == "J" then
					hugAbsorb()
				end
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_hug( targetid )
	if not stateQueued() then

		if getOccupants() == 0 then
			local position = world.entityPosition( targetid )
			local relative = vsoRelativePoint( position[1], position[2] )
			if relative[1] > 3 then -- target in front
				showEmote("emotehappy");
				-- vsoAnim( "bodyState", "pet" )
			end
		end

	end
end

-------------------------------------------------------------------------------

function unpin()
	vsoAnim( "bodyState", "situp" )
	vsoVictimAnimReplay( "firstOccupant", "situnpin", "bodyState")
	nextState( "sit" )
	nextAction(function()
		vsoUneat( "firstOccupant" )
		vsoSetTarget( "food", nil )
		vsoUseLounge( false, "firstOccupant" )
	end)
end
function pinAbsorb()
	vsoSound( "slurp" )
	vsoAnim( "bodyState", "absorb" )
	vsoVictimAnimReplay( "firstOccupant", "absorbpinned", "bodyState")
	nextOccupants( 1 )
	nextState( "lay" )
	nextAction(function()
		vsoVictimAnimReplay( "firstOccupant", "center", "bodyState")
	end)
end

function state_pinned()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			local unpinChance = escapePillChoice{5, 3, 1}
			local absorbChance = escapePillChoice{1, 3, 5}
			if percent < unpinChance then
				vsoAnim( "bodyState", "rollover" )
				vsoVictimAnimReplay( "firstOccupant", "unpin", "bodyState")
				nextState( "bed" )
			elseif percent < unpinChance+absorbChance then
				pinAbsorb()
			elseif percent < unpinChance+absorbChance+3 then
				vsoAnim( "bodyState", "fallasleep")
				nextState( "pinned_sleep")
			elseif percent < unpinChance+absorbChance+3+40+3 then
				unpin()
			else
				idle = true
			end
		end
		if idle then
			local percent = vsoRand(100)
			if percent < 15 then
				vsoAnim( "bodyState", "tail_flick" )
			elseif percent < 15+15 then
				vsoAnim( "bodyState", "blink" )
			elseif percent < 15+15+50 then
				vsoAnim( "bodyState", "lick")
			else
				vsoAnim( "bodyState", "idle" )
			end
		end
	end

	updateControlMode()
	if not stateQueued() then
		if not controlState() then
			if vsoHasAnySPOInputs( "firstOccupant" ) and vsoPill( "easyescape" ) then
				vsoAnim( "bodyState", "situp" )
				vsoVictimAnimReplay( "firstOccupant", "situnpin", "bodyState")
				nextState( "sit" )
			end
		else
			local movetype, movedir = vso4DirectionInput( controlSeat() )
			if movetype > 0 then
				if movedir == "U" then
					unpin()
				end
				if movedir == "D" then
					vsoAnim( "bodyState", "fallasleep")
					nextState( "pinned_sleep")
				end
				if movedir == "F" or movedir == "B" then
					vsoAnim( "bodyState", "rollover" )
					vsoVictimAnimReplay( "firstOccupant", "unpin", "bodyState")
					nextState( "bed" )
				end
				if movedir == "J" then
					pinAbsorb()
				end
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_pinned( targetid )
	if not stateQueued() then

		showEmote("emotehappy");
		vsoAnim( "bodyState", "pet" )

	end
end

-------------------------------------------------------------------------------

function state_pinned_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local idle = false
		if controlState() then
			idle = true
		else
			local percent = vsoRand(100)
			if percent < 5 then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "pinned" )
			else
				idle = true
			end
		end
		if idle then
			-- local percent = vsoRand(100)
			-- if percent < 15 then
			-- 	vsoAnim( "bodyState", "tail_flick" )
			-- elseif percent < 15+15 then
			-- 	vsoAnim( "bodyState", "blink" )
			-- else
				vsoAnim( "bodyState", "idle" )
			-- end
		end
	end

	updateControlMode()
	if not stateQueued() then
		if not controlState() then
			if vsoHasAnySPOInputs( "firstOccupant" ) and vsoPill( "easyescape" ) then
				vsoAnim( "bodyState", "wakeup" )
				nextState( "pinned" )
			end
		else
			local movetype, movedir = vso4DirectionInput( controlSeat() )
			if movetype > 0 then
				if movedir == "U" then
					vsoAnim( "bodyState", "wakeup" )
					nextState( "pinned" )
				end
			end
		end
	end

	doPhysics()
	updateControlMode()
end

function interact_state_pinned_sleep( targetid )
	if not stateQueued() then

		local percent = vsoRand(100)
		if percent < 15 then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "pinned" )
		else
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		end

	end
end