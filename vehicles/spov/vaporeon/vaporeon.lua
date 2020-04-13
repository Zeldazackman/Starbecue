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
		|                |
		1              sleep

	(struggling not included in chart, everything in full has it)

	todo:
	- multiple prey?
	  - 2 max
	  - 2 bulges? struggle independently?
	    - split the sprite up into multiple components

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
	if vsoTimeDelta( "emoteblock" ) > 1 then
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
function nextState(state)
	_qstate = state
	vsoNext( "state_"..state )
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
		if _qoccupants < _occupants then -- TODO: I don't like how this is handled, maybe replace it with a _qfunc or something
			vsoUneat( "drivingSeat" )
			vsoSetTarget( "food", nil )
			vsoUseLounge( false, "drivingSeat" )
		end
		setOccupants(_qoccupants)
		_qoccupants = nil
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

function bellyEffects()
	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then
		vsoSound( "digest" )
	end
	vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatebelly" } )
	local effect = 0
	if vsoPill( "digest" ) or vsoPill( "softdigest" ) then
		effect = -1
	elseif vsoPill( "heal" ) then
		effect = 1
	end
	if effect ~= 0 then
		effect = effect * vsoDelta()
		local health = world.entityHealth( vsoGetTargetId("food") )
		if vsoPill("softdigest") and health[1]/health[2] <= -effect then
			effect = (1 - health[1]) / health[2]
		end
		vsoResourceAddPercent( vsoGetTargetId("food"), "health", effect, function(still_alive)
			if not still_alive then
				vsoUneat( "drivingSeat" )

				vsoSetTarget( "food", nil )
				vsoUseLounge( false, "drivingSeat" )
				setOccupants(0)
			end
		end)
	end
end

function stateQueued()
	return _struggling or _qstate ~= nil
end

function handleStruggles(success_chances)
	local movetype, movedir = vso4DirectionInput( "drivingSeat" )
	if movetype == 0 then return false end

	local chance = escapePillChoice(success_chances)
	if chance ~= nil
	and vsoCounterValue( "struggleCount" ) >= chance[1]
	and vsoCounterChance( "struggleCount", chance[1], chance[2] ) then
		vsoCounterReset( "struggleCount" )
		return true
	end

	local direction_name = nil
	if movedir == "B" then direction_name = "_left" end
	if movedir == "F" then direction_name = "_right" end
	if movedir == "U" then direction_name = "_up" end
	if movedir == "D" then direction_name = "_down" end

	if direction_name ~= nil then
		vsoAnim( "bodyState", "struggle"..direction_name )
		vsoSound( "struggle" )
		vsoCounterAdd( "struggleCount", 1 )
		_struggling = true
	end

	return false
end

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	vsoAnimSpeed( 1.0 );
	vsoVictimAnimVisible( "drivingSeat", false )
	vsoUseLounge( false, "drivingSeat" )
	vsoUseSolid( false )

	setOccupants(0)
	resetState( "stand" )
	vsoAnim( "bodyState", "idle" )

	vsoMakeInteractive( true )
end

function onBegin()	--This sets up the VSO ONCE.

	vsoEffectWarpIn();	--Play warp in effect

	onForcedReset();	--Do a forced reset once.

	vsoStorageLoad( loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	vsoOnInteract( "state_stand", interact_state_stand )
	vsoOnInteract( "state_sit", interact_state_sit )
	vsoOnInteract( "state_lay", interact_state_lay )
	vsoOnInteract( "state_sleep", interact_state_sleep )
	vsoOnInteract( "state_back", interact_state_back )
	vsoOnInteract( "state_pinned", interact_state_pinned )
	vsoOnInteract( "state_pinned_sleep", interact_state_pinned_sleep )

end

function onEnd()

	vsoEffectWarpOut();

end

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

function state_stand()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		vsoMakeInteractive( true )
		local percent = vsoRand(100)
		if percent < 5 then -- and previousState() ~= "sit" then -- needs a timer
			vsoAnim( "bodyState", "sitdown" )
			nextState( "sit" )
		elseif percent < 5+15 then
			vsoAnim( "bodyState", "tail_flick" )
		elseif percent < 5+15+15 then
			vsoAnim( "bodyState", "blink" )
		else
			vsoAnim( "bodyState", "idle" )
		end
	end

	if getOccupants() > 0 then
		bellyEffects()
		if not stateQueued() then
			if handleStruggles{ {2, 5}, {5, 15}, {10, 20} } then
				vsoMakeInteractive( false )
				vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatemaw" } );
				vsoApplyStatus( "food", "droolsoaked", 5.0 );
				vsoAnim( "bodyState", "escape" )
				vsoVictimAnimReplay( "drivingSeat", "escape", "bodyState")
				nextOccupants( 0 )
			end
		end
	end
end

function interact_state_stand( targetid )

	-- vsoAnim( "bodyState", "idle_back" )
	-- vsoNext( "state_idle_back" ) -- jump to currently worked on state to test
	-- return

	if getOccupants() == 0 then
		local position = world.entityPosition( targetid )
		local relative = vsoRelativePoint( position[1], position[2] )
		if relative[1] > 3 then -- target in front
			vsoMakeInteractive( false )
			showEmote("emotehappy")
			vsoAnim( "bodyState", "eat" )
			vsoVictimAnimReplay( "drivingSeat", "playereat", "bodyState")
			nextOccupants( 1 )

			vsoSetTarget( "food", targetid )
			vsoUseLounge( true, "drivingSeat" )
			vsoEat( vsoGetTargetId( "food" ), "drivingSeat" )
			vsoVictimAnimSetStatus( "drivingSeat", { "vsoindicatemaw" } );
			vsoSound( "swallow" )
		else
			showEmote("emotehappy")
			vsoAnim( "bodyState", "pet" )
		end
	else
		showEmote("emotehappy")
		vsoAnim( "bodyState", "pet" )
	end

end

-------------------------------------------------------------------------------

function state_sit()

	local pin_bounds = vsoRelativeRect( 2.75, -4, 3.5, -3.5 )
	vsoDebugRect( pin_bounds[1][1], pin_bounds[1][2], pin_bounds[2][1], pin_bounds[2][2] )

	if vsoAnimEnd( "bodyState" ) and updateState() then
		sb.logInfo(previousState())
		if previousState() == "pinned" then
			vsoUneat( "drivingSeat" )
			vsoSetTarget( "food", nil )
			vsoUseLounge( false, "drivingSeat" )
		end

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
				vsoUseLounge( true, "drivingSeat" )
				vsoEat( pinnable[1], "drivingSeat" )
				vsoVictimAnimSetStatus( "drivingSeat", {} )
				vsoAnim( "bodyState", "pin" )
				vsoVictimAnimReplay( "drivingSeat", "sitpinned", "bodyState")
				nextState( "pinned" )
			else
				vsoAnim( "bodyState", "laydown" )
				nextState( "lay" )
			end
		elseif percent < 5+7+15 then
			vsoAnim( "bodyState", "tail_flick" )
		elseif percent < 5+7+15+15 then
			vsoAnim( "bodyState", "blink" )

		else
			vsoAnim( "bodyState", "idle" )
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
end

function interact_state_sit( targetid )

	if vsoChance(20) then
		vsoAnim( "bodyState", "standup" )
		nextState( "stand" )
	else
		showEmote("emotehappy");
		vsoAnim( "bodyState", "pet" )
	end

end

-------------------------------------------------------------------------------

function state_lay()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "situp" )
			nextState( "sit" )
		elseif percent < 5+5 then
			vsoAnim( "bodyState", "fallasleep" )
			nextState( "sleep" )
		elseif percent < 5+5+10 then
			vsoAnim( "bodyState", "rollover" )
			nextState( "back" )
		elseif percent < 5+5+10+15 then
			vsoAnim( "bodyState", "tail_flick" )
		elseif percent < 5+5+10+15+15 then
			vsoAnim( "bodyState", "blink" )
		else
			vsoAnim( "bodyState", "idle" )
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
end

function interact_state_lay( targetid )

	local percent = vsoRand(100)
	if percent < 10 then
		vsoAnim( "bodyState", "situp" )
		nextState( "sit" )
	elseif percent < 10+10 then
		vsoAnim( "bodyState", "rollover" )
		nextState( "back" )
	else
		showEmote("emotehappy");
		vsoAnim( "bodyState", "pet" )
	end

end

-------------------------------------------------------------------------------

function state_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "lay" )
		else
			vsoAnim( "bodyState", "idle" )
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
end

function interact_state_sleep( targetid )

	local percent = vsoRand(100)
	if percent < 15 then
		vsoAnim( "bodyState", "wakeup" )
		nextState( "lay" )
	else
		showEmote("emotehappy");
		-- vsoAnim( "bodyState", "pet" )
	end

end

-------------------------------------------------------------------------------

function state_back()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "rollover" )
			nextState( "lay" )
		else
			vsoAnim( "bodyState", "idle" )
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
end

function interact_state_back( targetid )

	if getOccupants() == 0 then
		local position = world.entityPosition( targetid )
		local relative = vsoRelativePoint( position[1], position[2] )
		if relative[1] > 3 then -- target in front
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		else
			vsoUseLounge( true, "drivingSeat" )
			vsoEat( targetid, "drivingSeat" )
			vsoVictimAnimReplay( "drivingSeat", "bellybed", "bodyState")
			vsoVictimAnimSetStatus( "drivingSeat", {} );
			vsoNext( "state_bed" ) -- no transition animation
		end
	else
		showEmote("emotehappy");
		-- vsoAnim( "bodyState", "pet" )
	end

end

-------------------------------------------------------------------------------

function state_bed() -- only accessible with no occupants

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		local hugChance = escapePillChoice{5, 5, 20}
		if percent < hugChance then
			vsoAnim( "bodyState", "grab" )
			vsoVictimAnimReplay( "drivingSeat", "bellyhug", "bodyState")
			nextState( "hug" )
		elseif percent < hugChance+hugChance then
			vsoAnim( "bodyState", "rollover" )
			vsoVictimAnimReplay( "drivingSeat", "pinned", "bodyState")
			nextState( "pinned" )
		else
			vsoAnim( "bodyState", "idle" )
		end
	end

	if vsoHasAnySPOInputs( "drivingSeat" ) then
		vsoUneat( "drivingSeat" )
		vsoUseLounge( false, "drivingSeat" )
		vsoNext( "state_back" ) -- no transition animation
	end
end

function interact_state_bed( targetid )

	if getOccupants() == 0 then
		local position = world.entityPosition( targetid )
		local relative = vsoRelativePoint( position[1], position[2] )
		if relative[1] > 3 then -- target in front
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		end
	end
end

-------------------------------------------------------------------------------

function state_hug()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		local unhugChance = escapePillChoice{10, 5, 1}
		local absorbChance = escapePillChoice{1, 5, 10}
		if percent < unhugChance then
			vsoAnim( "bodyState", "grab" )
			vsoVictimAnimReplay( "drivingSeat", "bellybed", "bodyState")
			nextState( "bed" )
		elseif percent < unhugChance+absorbChance then
			vsoSound( "slurp" )
			vsoAnim( "bodyState", "absorb" )
			vsoVictimAnimReplay( "drivingSeat", "absorbback", "bodyState")
			nextOccupants( 1 )
			nextState( "back" )
		else
			vsoAnim( "bodyState", "idle" )
		end
	end

	if vsoHasAnySPOInputs( "drivingSeat" ) and vsoPill( "easyescape" ) then
		vsoAnim( "bodyState", "grab" )
		vsoVictimAnimReplay( "drivingSeat", "bellybed", "bodyState")
		nextState( "bed" )
	end
end

function interact_state_hug( targetid )

	if getOccupants() == 0 then
		local position = world.entityPosition( targetid )
		local relative = vsoRelativePoint( position[1], position[2] )
		if relative[1] > 3 then -- target in front
			showEmote("emotehappy");
			-- vsoAnim( "bodyState", "pet" )
		end
	end
end

-------------------------------------------------------------------------------

function state_pinned()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		local unpinChance = escapePillChoice{5, 3, 1}
		local absorbChance = escapePillChoice{1, 3, 5}
		if percent < unpinChance then
			vsoAnim( "bodyState", "rollover" )
			vsoVictimAnimReplay( "drivingSeat", "unpin", "bodyState")
			nextState( "bed" )
		elseif percent < unpinChance+absorbChance then
			vsoSound( "slurp" )
			vsoAnim( "bodyState", "absorb" )
			vsoVictimAnimReplay( "drivingSeat", "absorbpinned", "bodyState")
			nextOccupants( 1 )
			nextState( "lay" )
		elseif percent < unpinChance+absorbChance+3 then
			vsoAnim( "bodyState", "fallasleep")
			nextState( "pinned_sleep")
		elseif percent < unpinChance+absorbChance+3+40 then
			vsoAnim( "bodyState", "lick")
		elseif percent < unpinChance+absorbChance+3+40+3 then
			vsoAnim( "bodyState", "situp" )
			vsoVictimAnimReplay( "drivingSeat", "situnpin", "bodyState")
			nextState( "sit" )
		else
			vsoAnim( "bodyState", "idle" )
		end
	end

	if vsoHasAnySPOInputs( "drivingSeat" ) and vsoPill( "easyescape" ) then
		vsoAnim( "bodyState", "situp" )
		vsoVictimAnimReplay( "drivingSeat", "situnpin", "bodyState")
		nextState( "sit" )
	end
end

function interact_state_pinned( targetid )

	showEmote("emotehappy");
	vsoAnim( "bodyState", "pet" )

end

-------------------------------------------------------------------------------

function state_pinned_sleep()

	local anim = vsoAnimCurr( "bodyState" );

	if vsoAnimEnd( "bodyState" ) and updateState() then
		local percent = vsoRand(100)
		if percent < 5 then
			vsoAnim( "bodyState", "wakeup" )
			nextState( "pinned" )
		else
			vsoAnim( "bodyState", "idle" )
		end
	end

	if vsoHasAnySPOInputs( "drivingSeat" ) and vsoPill( "easyescape" ) then
		vsoAnim( "bodyState", "wakeup" )
		nextState( "pinned" )
	end
end

function interact_state_pinned_sleep( targetid )

	local percent = vsoRand(100)
	if percent < 15 then
		vsoAnim( "bodyState", "wakeup" )
		nextState( "pinned" )
	else
		showEmote("emotehappy");
		-- vsoAnim( "bodyState", "pet" )
	end

end