--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")

function vsoNotnil( val, msg ) -- HACK: intercept self.cfgVSO to inject things from other files
	if val == nil then vsoError( msg ) end
	if msg == "missing vso in config file" then
		local defaultVictimAnims = root.assetJson( "/vehicles/spov/default_victim_animations.config" )
		val.victimAnimations = sb.jsonMerge( defaultVictimAnims, val.victimAnimations )
	end
	return val;
end

p = {}

p.movement = {
	jumps = 0,
	jumped = false,
	waswater = false,
	bapped = 0,
	downframes = 0,
	groundframes = 0,
	run = false,
	wasspecial1 = 10, -- Give things time to finish initializing, so it realizes you're holding special1 from spawning vap instead of it being a new press
	E = false,
	wasE = false,
	primaryCooldown = 0,
	altCooldown = 0,
	lastYVelocity = 0
}

function p.showEmote( emotename ) --helper function to express a emotion particle "emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if vsoTimeDelta( "emoteblock" ) > 0.2 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
	end
end

function p.setOccupants(occupants)
	p.occupants = occupants
	animator.setGlobalTag( "occupants", tostring(occupants) )
end

function p.setState(state)
	if state == nil then
		sb.logError( "nil state from ".. p.state )
	end
	p.state = state
	animator.setGlobalTag( "state", state )
	vsoNext( "state_"..state )
end

function p.localToGlobal( position )
	local lpos = { position[1], position[2] }
	if self.vsoCurrentDirection == -1 then lpos[1] = -lpos[1] end
	local mpos = mcontroller.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end
function p.globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if self.vsoCurrentDirection == -1 then pos[1] = -pos[1] end
	return pos
end

function p.occupantArray( maybearray )
	if maybearray[1] == nil then -- not an array, no change
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[p.occupants + 1]
	end
end

function p.swapOccupants()
	local food = vsoGetTargetId("food")
	vsoSetTarget( "food", vsoGetTargetId("dessert") )
	vsoSetTarget( "dessert", food )

	vsoUneat( "firstOccupant" )
	vsoUneat( "secondOccupant" )
	vsoEat( vsoGetTargetId("food"), "firstOccupant" )
	vsoEat( vsoGetTargetId("dessert"), "secondOccupant" )
end

function p.entityLounging( entity )
	if entity == vehicle.entityLoungingIn( "driver" ) then return true end
	if entity == vehicle.entityLoungingIn( "firstOccupant" ) then return true end
	if entity == vehicle.entityLoungingIn( "secondOccupant" ) then return true end
	return false
end

function p.bodyAnim( anim )
	local prefix = p.stateconfig[p.state].animationPrefix or ""
	vsoAnim( "bodyState", prefix..anim )
	p.headbob( anim )
end

function p.headAnim( anim )
	local prefix = p.stateconfig[p.state].animationPrefix or ""
	vsoAnim( "headState", prefix..anim )
end

p.headbobbing = {vals = {}, time = 0}
function p.headbob( name )
	if p.headbobbing.name == name then return end
	p.headbobbing.name = name
	p.headbobbing.vals = (p.stateconfig[p.state].headbob or {})[name] or {}
	p.headbobbing.time = 0
end

local _vsoTransAnimUpdate = vsoTransAnimUpdate
function vsoTransAnimUpdate( transformname, dt )
	if transformname == "headbob" and p.stateconfig[p.state].headbob ~= nil then
		p.headbobbing.time = p.headbobbing.time + dt * self.sv.animspeed;
		if p.headbobbing.time > 1 then
			p.headbobbing.time = p.headbobbing.time -1
		end
		sb.setLogMap("headbob time", p.headbobbing.time)
		vsoTransMoveTo( "head",
			p.stateconfig[p.state].headbob.x or 0,
			p.headbobbing.vals[ math.ceil( p.headbobbing.time * #p.headbobbing.vals ) ] or 0
		)
	else
		_vsoTransAnimUpdate( transformname, dt )
	end
end

-------------------------------------------------------------------------------

function p.loadStoredData()
	vsoStorageSaveAndLoad( function()	--Get defaults from the item spawner itself
		if storage.colorReplaceMap ~= nil then
			vsoSetDirectives( vsoMakeColorReplaceDirectiveString( storage.colorReplaceMap ) );
		end
	end )
end

function p.onForcedReset()
	vsoAnimSpeed( 1.0 );
	vsoVictimAnimVisible( "firstOccupant", false )
	vsoUseLounge( false, "firstOccupant" )
	vsoVictimAnimVisible( "secondOccupant", false )
	vsoUseLounge( false, "secondOccupant" )
	vsoUseSolid( false )

	p.setOccupants( 0 )
	p.setState( "stand" )
	vsoAnim( "bodyState", "idle" )

	vsoMakeInteractive( true )

	vsoTimeDelta( "emoteblock" ) -- without this, the first call to showEmote() does nothing
end

function p.onBegin()
	vsoEffectWarpIn();	--Play warp in effect

	if config.getParameter( "driver" ) ~= nil then
		p.control.standalone = true
		p.control.driver = "driver"
		p.control.driving = true
		local driver = config.getParameter( "driver" )
		storage._vsoSpawnOwner = driver
		storage._vsoSpawnOwnerName = world.entityName( driver )
		vsoEat( driver, "driver" )
		vsoVictimAnimVisible( "driver", false )

		local settings = config.getParameter( "settings" )
		p.bellyeffect = settings.bellyeffect
	else
		p.control.standalone = false
		p.control.driver = "firstOccupant"
		p.control.driving = false
		vsoUseLounge( false, "driver" )
	end

	onForcedReset();	--Do a forced reset once.

	vsoStorageLoad( p.loadStoredData );	--Load our data (asynchronous, so it takes a few frames)

	if vsoPill( "heal" ) then p.bellyeffect = "heal" end
	if vsoPill( "digest" ) then p.bellyeffect = "digest" end
	if vsoPill( "softdigest" ) then p.bellyeffect = "softdigest" end

	-- message.setHandler( "settingsMenuGet", function settingsMenuGet()
	-- 	return {
	-- 		bellyeffect = p.bellyeffect,
	-- 		clickmode = "attack", -- todo
	-- 		firstOccupant = vsoGetTargetId( "food" ),
	-- 		secondOccupant = vsoGetTargetId( "dessert" ),
	-- 	}
	-- end )
	message.setHandler( "settingsMenuSet", function(_,_, key, val )
		if key == "bellyeffect" then
			p.bellyeffect = val
		elseif key == "clickmode" then
			-- todo
		elseif key == "letout" then
			if p.state == "stand" and p.occupants > 0 then
				if p.occupants == 1 then
					p.doTransition( "escape", 1 )
				else
					if val == 1 then
						p.swapOccupants()
					end
					p.doTransition( "escape", 2 )
				end
			end
		end
	end )
	message.setHandler( "despawn", _vsoOnDeath )
	message.setHandler( "forcedsit", p.control.pressE )

	p.stateconfig = config.getParameter("states")

	self.sv.ta.headbob = { visible = false } -- hack: intercept vsoTransAnimUpdate for our own headbob system
end

function p.onEnd()

	vsoEffectWarpOut();
	
end

-------------------------------------------------------------------------------

p.statescripts = {}

function p.registerStateScript( state, name, func )
	if p.statescripts[state] == nil then
		p.statescripts[state] = {}
	end
	p.statescripts[state][name] = func
end

local _ptransition = {}

function p.doTransition( direction, scriptarg )
	vsoCounterReset( "struggleCount" )
	local tconfig = p.occupantArray( p.stateconfig[p.state].transitions[direction] )
	local continue = true
	local after = function() end
	if tconfig.script ~= nil then
		local statescript = p.statescripts[p.state][tconfig.script]
		local _continue, _after, _tconfig = statescript( scriptarg )
		if _continue ~= nil then continue = _continue end
		if _after ~= nil then after = _after end
		if _tconfig ~= nil then tconfig = _tconfig end
	end
	if not continue then return end
	_ptransition.after = after
	_ptransition.state = tconfig.state
	if tconfig.animation ~= nil then
		p.bodyAnim( tconfig.animation )
	end
	if tconfig.victimAnimation ~= nil then
		vsoVictimAnimReplay( tconfig.victimAnimation.which, tconfig.victimAnimation.name, "bodyState" )
	end
	vsoNext( "state__ptransition" )
end

 -- somehow, even though I change the animation tag *after* vsoAnimEnded, it's too early
local _endedframes = 0
function state__ptransition()
	if vsoAnimEnded( "bodyState" ) then
		_endedframes = _endedframes + 1
		if _endedframes > 2 then
			_endedframes = 0
			p.bodyAnim( "idle" )
			_ptransition.after()
			p.setState( _ptransition.state )
		end
	end
	p.control.doPhysics()
end

-------------------------------------------------------------------------------

p.control = {}

function p.control.updateDriving()
	if p.control.standalone then
		vsoVictimAnimSetStatus( "driver", { "breathprotectionvehicle" } )
		p.control.driving = true
		if vehicle.controlHeld( p.control.driver, "Special3" ) then
			world.sendEntityMessage(
				vehicle.entityLoungingIn( p.control.driver ), "openvappysettings",
				entity.id(), vsoGetTargetId( "food" ), vsoGetTargetId( "dessert" )
			)
		end
	elseif vsoGetTargetId( "food" ) ~= nil then
		if vehicle.controlHeld( p.control.driver, "Special1" ) then
			p.control.driving = true
		end
		if vehicle.controlHeld( p.control.driver, "Special2" ) then
			p.control.driving = false
		end
	else
		p.control.driving = false
	end
end

function p.control.probablyOnGround() -- check number of frames -> ceiling isn't ground
	local yvel = mcontroller.yVelocity()
	if yvel < 0.1 and yvel > -0.1 then
		p.movement.groundframes = p.movement.groundframes + 1
	else
		p.movement.groundframes = 0
	end
	return p.movement.groundframes > 5
end

function p.control.notMoving()
	local xvel = mcontroller.xVelocity()
	return xvel < 0.1 and xvel > -0.1
end

function p.control.underWater()
	return mcontroller.liquidPercentage() >= 0.2
end

function p.control.doPhysics()
	if not p.control.underWater() then
		mcontroller.setXVelocity( 0 )
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	else
		mcontroller.approachYVelocity( 0, 50 )
		mcontroller.approachYVelocity( -10, 50 )
	end
	if p.state ~= "stand" and mcontroller.yVelocity() < -5 then
		sb.logInfo( "falling" )
		nextState( "stand" )
		updateState()
		p.bodyAnim( "fall" )
		if p.state == "bed" or p.state == "hug" or p.state == "pinned" or p.state == "pinned_sleep" then
			vsoUneat( "firstOccupant" )
			vsoSetTarget( "food", nil )
			vsoUseLounge( false, "firstOccupant" )
		end
	end
end

function p.control.pressE(_,_, seat_index )
	if seat_index == 0 and p.control.standalone then
		p.movement.E = true
	elseif seat_index == 1 and not p.control.standalone then
		p.movement.E = true
	end
end

function p.control.interact()
	if p.movement.E then -- intercepting vsoForcePlayerSit to get this
		if not p.movement.wasE then
			local aim = vehicle.aimPosition( p.control.driver )
			local mpos = mcontroller.position()
			local dpos = world.distance( mpos, aim )
			local interactables
			local queryParameters = {
				withoutEntityId = entity.id(), -- don't interact with self
				order = "nearest"
			}
			if world.magnitude( dpos ) < 9 then -- interact range -- and not world.lineTileCollision( mpos, aim )
				interactables = world.entityQuery( aim, 0.5, queryParameters )
			else
				interactables = world.entityQuery( mcontroller.position(), 3, queryParameters )
			end
			local obj = interactables[1]
			local driver = vehicle.entityLoungingIn( p.control.driver )
			if obj == driver then
				obj = interactables[2]
			end
			if obj ~= nil and driver ~= nil then
				local objpos = world.entityPosition( obj )
				vsoDebugRect( objpos[1]-0.5, objpos[2]-0.5, objpos[1]+0.5, objpos[2]+0.5, "red" )

				local name = world.getObjectParameter( obj, "objectName" )
				-- if name ~= nil then -- object
					local interactaction = world.getObjectParameter( obj, "interactAction" )
					local interactdata = world.getObjectParameter( obj, "interactData" )
					local localinteracted = false
					if interactaction == nil then -- some things return that from script? let's try to get that
						local s, e = pcall(function() -- this only works on local entities, pcall should stop it from crashing the game
							local action = world.callScriptedEntity( obj, "onInteraction", {
								source = world.distance( mpos, objpos ),
								sourceId = driver
							} )
							if action ~= nil then
								interactaction = action[1]
								interactdata = action[2]
							end
							localinteracted = true
						end)
						if not s then
							sb.logError(e)
						end
					end
					if interactaction ~= nil then
						if type( interactdata ) == "string" then
							interactdata = root.assetJson( interactdata )
						end
						world.sendEntityMessage( driver, "vsoForceInteract", interactaction, interactdata, obj )
					elseif world.getObjectParameter( obj, "uiConfig" ) ~= nil then
						uiconfig = world.getObjectParameter( obj, "uiConfig" )
						if world.getObjectParameter( obj, "slotCount" ) ~= nil then
							uiconfig = sb.replaceTags( uiconfig, { ["slots"] = world.getObjectParameter( obj, "slotCount" ) } )
						end
						local configdata = root.assetJson( uiconfig )
						world.sendEntityMessage( driver, "vsoForceInteract", "OpenContainer", configdata, obj )
					elseif world.getObjectParameter( obj, "upgradeStates" ) then -- upgradeablecraftingobjects
					elseif not localinteracted then -- call onInteraction for non-local entities, sadly we can't get the return value or this would be earlier
						world.objectQuery( objpos, 1, {
							name = name,
							callScript = "onInteraction",
							callScriptArgs = { {
								source = world.distance( mpos, objpos ),
								sourceId = driver
							} },
						} )
					end
				-- end
			end
		end
		p.movement.wasE = true
	else
		p.movement.wasE = false
	end
	p.movement.E = false
end

function p.control.drive()
	if not p.control.driving then return end
	local control = p.stateconfig[p.state].control

	local dx = 0
	if vehicle.controlHeld( p.control.driver, "left" ) then
		dx = dx - 1
	end
	if vehicle.controlHeld( p.control.driver, "right" ) then
		dx = dx + 1
	end
	mcontroller.approachXVelocity( dx * control.swimSpeed, 50 )
	if p.control.probablyOnGround() then
		p.control.groundMovement( dx )
	elseif p.control.underWater() then
		p.control.waterMovement( dx )
	else
		p.control.airMovement( dx )
	end

	p.control.primaryAction()
	p.control.altAction()
	p.control.interact()
end

function p.control.primaryAction()
	local control = p.stateconfig[p.state].control
	if control.primaryAction ~= nil and vehicle.controlHeld( p.control.driver, "PrimaryFire" ) then
		if p.movement.primaryCooldown < 1 then
			if control.primaryAction.projectile ~= nil then
				p.control.projectile(control.primaryAction.projectile)
			end
			if control.primaryAction.animation ~= nil then
				p.bodyAnim( control.primaryAction.animation )
			end
			if control.primaryAction.script ~= nil then
				local statescript = p.statescripts[p.state][control.primaryAction.script]
				statescript() -- what arguments might this need?
			end
			p.movement.primaryCooldown = control.primaryAction.cooldown
		end
	end
	p.movement.primaryCooldown = p.movement.primaryCooldown - 1
end
function p.control.altAction()
	local control = p.stateconfig[p.state].control
	if control.altAction ~= nil and vehicle.controlHeld( p.control.driver, "altFire" ) then
		if p.movement.altCooldown < 1 then
			if control.altAction.projectile ~= nil then
				p.control.projectile(control.altAction.projectile)
			end
			if control.altAction.animation ~= nil then
				p.bodyAnim( control.altAction.animation )
			end
			if control.altAction.script ~= nil then
				local statescript = p.statescripts[p.state][control.altAction.script]
				statescript() -- what arguments might this need?
			end
			p.movement.altCooldown = control.altAction.cooldown
		end
	end
	p.movement.altCooldown = p.movement.altCooldown - 1
end

function p.control.groundMovement( dx )
	local control = p.stateconfig[p.state].control

	local running = false
	if not vehicle.controlHeld( p.control.driver, "down" ) and p.occupants < control.fullThreshold then
		running = true
	end
	if dx ~= 0 then
		vsoFaceDirection( dx )
	end
	if running then
		mcontroller.setXVelocity( dx * control.runSpeed )
	else
		mcontroller.setXVelocity( dx * control.walkSpeed )
	end

	if dx ~= 0 then
		if not running then
			p.bodyAnim( "walk" )
			p.movement.animating = true
		elseif running then
			p.bodyAnim( "run" )
			p.movement.animating = true
		end
	elseif p.movement.animating then
		p.bodyAnim( "idle" )
		p.movement.animating = false
	end

	mcontroller.setYVelocity( -0.15 ) -- to detect leaving ground
	if vehicle.controlHeld( p.control.driver, "jump" ) then
		if not vehicle.controlHeld( p.control.driver, "down" ) then
			if not p.movement.jumped then
				p.bodyAnim( "jump" )
				p.movement.animating = true
				if p.occupants < control.fullThreshold then
					mcontroller.setYVelocity( control.jumpStrength )
				else
					mcontroller.setYVelocity( control.fullJumpStrength )
				end
			end
		else
			mcontroller.applyParameters{ ignorePlatformCollision = true }
		end
		p.movement.jumped = true
	else
		p.movement.jumped = false
	end

	p.movement.waswater = false
	p.movement.jumps = 1
end

function p.control.waterMovement( dx )
	local control = p.stateconfig[p.state].control

	if dx ~= 0 then
		vsoFaceDirection( dx )
	end
	mcontroller.approachXVelocity( dx * control.swimSpeed, 50 )

	if vehicle.controlHeld( p.control.driver, "jump" ) then
		mcontroller.approachYVelocity( 10, 50 )
	else
		mcontroller.approachYVelocity( -10, 50 )
	end

	if vehicle.controlHeld( p.control.driver, "jump" )
	-- or vehicle.controlHeld( p.control.driver, "down" )
	or vehicle.controlHeld( p.control.driver, "left" )
	or vehicle.controlHeld( p.control.driver, "right" ) then
		p.bodyAnim( "swim" )
		p.movement.animating = true
	elseif not p.struggling then
		p.bodyAnim( "swimidle" )
		p.movement.animating = true
	end

	p.movement.waswater = true
	p.movement.jumped = false
	p.movement.jumps = 1
end

function p.control.airMovement( dx )
	local control = p.stateconfig[p.state].control

	local running = false
	if not vehicle.controlHeld( p.control.driver, "down" ) and p.occupants < control.fullThreshold then
		running = true
	end
	if dx ~= 0 then
		if running then
			mcontroller.approachXVelocity( dx * control.runSpeed, 50 )
		else
			mcontroller.approachXVelocity( dx * control.walkSpeed, 50 )
		end
	else
		mcontroller.approachXVelocity( 0, 30 )
	end

	if vehicle.controlHeld( p.control.driver, "down" ) then
		mcontroller.applyParameters{ ignorePlatformCollision = true }
	else
		mcontroller.applyParameters{ ignorePlatformCollision = false }
	end
	if mcontroller.yVelocity() > 0 and vehicle.controlHeld( p.control.driver, "jump" ) then
		mcontroller.approachYVelocity( -100, world.gravity(mcontroller.position()) )
	else
		mcontroller.approachYVelocity( -200, 2 * world.gravity(mcontroller.position()) )
	end
	if vehicle.controlHeld( p.control.driver, "jump" ) then
		if not p.movement.jumped and p.movement.jumps < control.jumpCount then
			p.bodyAnim( "jump" )
			p.movement.animating = true
			if p.occupants < control.fullThreshold then
				mcontroller.setYVelocity( control.jumpStrength )
			else
				mcontroller.setYVelocity( control.fullJumpStrength )
			end
			if not p.movement.waswater then
				p.movement.jumps = p.movement.jumps + 1
				-- particles from effects/multiJump.effectsource
				animator.burstParticleEmitter( control.pulseEffect )
				for i = 1, control.pulseSparkles do
					animator.burstParticleEmitter( "defaultblue" )
					animator.burstParticleEmitter( "defaultlightblue" )
				end
				vsoSound( "doublejump" )
			end
		end
		p.movement.jumped = true
	else
		p.movement.jumped = false
	end
	
	if mcontroller.yVelocity() < -10 and p.movement.lastYVelocity >= -10 then
		p.bodyAnim( "fall" )
		p.movement.animating = true
	end
	p.movement.lastYVelocity = mcontroller.yVelocity()
end

function p.control.projectile( projectiledata )
	local position = p.localToGlobal( projectiledata.position )
	local direction
	if projectiledata.aimable then
		local aiming = vehicle.aimPosition( p.control.driver )
		vsoFacePoint( aiming[1] )
		aiming[2] = aiming[2] + 0.2 * self.vsoCurrentDirection * (aiming[1] - position[1])
		direction = world.distance( aiming, position )
	else
		direction = { self.vsoCurrentDirection, 0 }
	end
	world.spawnProjectile( projectiledata.name, position, entity.id(), direction )
end

-------------------------------------------------------------------------------

function p.standardState()

	p.idleStateChange()
	if p.control.driving then
		p.driverStateChange()
	end
	p.handleBelly()
	p.control.doPhysics()
	p.control.updateDriving()

end

function p.idleStateChange()
	-- sb.setLogMap("isc", 0)
	if not p.control.probablyOnGround() or not p.control.notMoving() then return end

	if vsoTimerEvery( "idleStateChange", 5.0, 5.0 ) then -- every 5 seconds? this is arbitrary, oh well
		local transitions = p.stateconfig[p.state].transitions
		if not p.control.driving then
			local percent = vsoRand(100)
			for name, t in pairs(transitions) do
				local transition = p.occupantArray( t )
				if transition.chance ~= nil and transition.chance > 0 then
					percent = percent - transition.chance
					if percent < 0 then
						p.doTransition( name )
						return
					end
				end
			end
		end
	end

	if vsoAnimEnded( "bodyState" ) then
		local idles = p.stateconfig[p.state].idle or {}
		local percent = vsoRand(100)
		for _, idle in pairs(idles) do
			percent = percent - 15
			if percent < 0 then
				p.bodyAnim( idle )
				return
			end
		end
		p.bodyAnim( "idle" )
	end

	if vsoAnimEnded( "headState" ) then
		local idles = p.stateconfig[p.state].headIdle or {}
		local percent = vsoRand(100)
		for _, idle in pairs(idles) do
			percent = percent - 15
			if percent < 0 then
				p.headAnim( idle )
				return
			end
		end
		p.headAnim( "idle" )
	end
end

function p.driverStateChange()
	local transitions = p.stateconfig[p.state].transitions
	local movetype, movedir = vso4DirectionInput( p.control.driver )
	if movetype > 0 then
		if movedir == "U" and transitions.up ~= nil then
			p.doTransition("up")
		end
		if (movedir == "F" or movedir == "B")  and transitions.side ~= nil then
			p.doTransition("side")
		end
		if movedir == "D" and transitions.down ~= nil then
			p.doTransition("down")
		end
	end
end

function p.handleBelly()
	if p.occupants > 0 then
		p.bellyEffects()
	end
	if p.control.probablyOnGround() and p.control.notMoving() then
		p.handleStruggles()
	end
end

function p.bellyEffects()
	if vsoTimerEvery( "gurgle", 1.0, 8.0 ) then
		vsoSound( "digest" )
	end
	vsoVictimAnimSetStatus( "firstOccupant", { "vsoindicatebelly", "breathprotectionvehicle" } )

	local effect = 0
	if p.bellyeffect == "digest" or p.bellyeffect == "softdigest" then
		effect = -1
	elseif p.bellyeffect == "heal" then
		effect = 1
	end
	if p.occupants > 1 then
		vsoVictimAnimSetStatus( "secondOccupant", { "vsoindicatebelly", "breathprotectionvehicle" } )
			if effect ~= 0 then
			local health_change = effect * vsoDelta()
			local health = world.entityHealth( vsoGetTargetId("dessert") )
			if p.bellyeffect == "softdigest" and health[1]/health[2] <= -health_change then
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
		if p.bellyeffect == "softdigest" and health[1]/health[2] <= -health_change then
			health_change = (1 - health[1]) / health[2]
		end
		vsoResourceAddPercent( vsoGetTargetId("food"), "health", health_change, function(still_alive)
			if not still_alive then
				if p.occupants == 2 then
					p.swapOccupants()
					vsoUneat( "SecondOccupant" )
					vsoSetTarget( "dessert", nil )
					vsoUseLounge( false, "secondOccupant" )
					setOccupants(1)
				else
					vsoUneat( "firstOccupant" )
					vsoSetTarget( "food", nil )
					vsoUseLounge( false, "firstOccupant" )
					setOccupants(0)
				end
			end
		end)
	end
end

function p.handleStruggles()
	if not vsoAnimEnded( "bodyState" ) and (
		vsoAnimIs( "bodyState", "s_up" ) or
		vsoAnimIs( "bodyState", "s_front" ) or
		vsoAnimIs( "bodyState", "s_back" ) or
		vsoAnimIs( "bodyState", "s_down" )
	) then
		return -- already struggling
	end
	local movetype, movedir = vso4DirectionInput( "firstOccupant" )
	local struggler = 1
	if movetype == 0 then
		movetype, movedir = vso4DirectionInput( "secondOccupant" )
		struggler = 2
		if movetype == 0 then return end
	end

	if p.control.driving and struggler == 1 and not p.control.standalone then
		return -- control vappy instead of struggling
	end

	local struggledata = p.stateconfig[p.state].struggle

	local dir = nil
	if movedir == "B" then dir = "back" end
	if movedir == "F" then dir = "front" end
	if movedir == "U" then dir = "up" end
	if movedir == "D" then dir = "down" end

	if dir == nil then return end -- invalid struggle
	if struggledata[dir] == nil then return end

	if struggledata.script ~= nil then
		local statescript = p.statestripts[p.state][struggledata.script]
		statescript( struggler, dir )
	end

	local chance = struggledata.chances
	if struggledata[dir].chances ~= nil then
		chance = struggledata[dir].chances
	end
	if vsoPill( "easyescape" ) then
		chance = chance.easyescape
	elseif vsoPill( "antiescape" ) then
		chance = chance.antiescape
	else
		chance = chance.normal
	end

	if chance ~= nil and ( chance.max == 0 or (
		not p.control.driving
		and vsoCounterValue( "struggleCount" ) >= chance.min
		and vsoCounterChance( "struggleCount", chance.min, chance.max )
	) ) then
		p.doTransition( struggledata[dir].transition, struggler )
	else
		p.bodyAnim( "s_"..dir )
		if struggledata[dir].victimAnimation then
			vsoVictimAnimReplay( "firstOccupant", struggledata[dir].victimAnimation, "bodyState" )
		end
		vsoSound( "struggle" )
		vsoCounterAdd( "struggleCount", 1 )
	end
end

function p.onInteraction( targetid )
	local state = p.stateconfig[p.state]
	if not p.control.driving then
		local position = p.globalToLocal( world.entityPosition( targetid ) )
		local interact
		if position[1] > 3 then
			interact = p.occupantArray( state.interact.front )
		elseif position[1] < -3 then
			interact = p.occupantArray( state.interact.back )
		else
			interact = p.occupantArray( state.interact.side )
		end

		if interact.chance > 0 and vsoChance( interact.chance ) then
			p.doTransition( interact.transition, targetid )
			return
		end
	end
	if state.interact.petAnimation then
		p.bodyAnim( "pet" )
	end
	p.showEmote( "emotehappy" )
end