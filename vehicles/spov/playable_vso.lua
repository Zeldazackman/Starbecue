--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

state = {}

p = {
	maxOccupants = { --basically everything I think we'd need
		total = 0
	},
	occupants = {
		total = 0
	},
	occupant = {},
	occupantOffset = 1,
	justAte = false,
	justLetout = false,
	nextIdle = 0,
	swapCooldown = 0,
	isPathfinding = false
}

p.settings = {}

p.movement = {
	jumps = 0,
	jumped = false,
	sinceLastJump = 0,
	jumpProfile = "airJumpProfile",
	airtime = 0,
	groundMovement = "run",
	aimingLock = 0
}

p.seats = {} -- meant to be a redirect pointers to the occupant data
p.entity = {}

function p.clearOccupant(i)
	return {
		seatname = "occupant"..i,
		index = i,
		id = nil,
		loungeStatList = {},
		statList = {},
		visible = true,
		emote = "idle",
		dance = "idle",
		location = nil,
		species = nil,
		smolPreyData = {recieved = false},
		struggleCount = 0,
		bellySettleDownTimer = 0,
		occupantTime = 0,
		progressBar = 0,
		progressBarActive = false,
		progressBarMode = 1,
		progressBarFinishFunc = nil,
		victimAnim = { enabled = false, last = { x = 0, y = 0 } },
		controls = {
			primaryFire = 0,
			altFire = 0,
			dx = 0,
			dy = 0,
			left = 0,
			right = 0,
			up = 0,
			down = 0,
			jump = 0,
			shift = 0,
			special1 = 1, --so that it doesn't trip p.tapControl from using the tech
			special2 = 1,
			special3 = 1,

			primaryFireReleased = 0,
			altFireReleased = 0,
			leftReleased = 0,
			rightReleased = 0,
			upReleased = 0,
			downReleased = 0,
			jumpReleased = 0,
			shiftReleased = 0,
			special1Released = 0,
			special2Released = 0,
			special3Released = 0,

			primaryFirePressed = false,
			altFirePressed = false,
			leftPressed = false,
			rightPressed = false,
			upPressed = false,
			downPressed = false,
			jumpPressed = false,
			shiftPressed = false,
			special1Pressed = false,
			special2Pressed = false,
			special3Pressed = false,

			aim = {0,0},
			primaryHandItem = nil,
			altHandItem = nil,
			species = nil,

			mass = 0,
			head = nil,
			chest = nil,
			legs = nil,
			back = nil,
			headCosmetic = nil,
			chestCosmetic = nil,
			legsCosmetic = nil,
			backCosmetic = nil,
			powerMultiplier = 1
		}
	}
end

require("/vehicles/spov/pvso_animation.lua")
require("/vehicles/spov/pvso_state_control.lua")
require("/vehicles/spov/pvso_driving.lua")
require("/vehicles/spov/pvso_pathfinding.lua")
require("/vehicles/spov/pvso_replaceable_functions.lua")

function init()
	p.vso = config.getParameter("vso")
	p.directoryPath = config.getParameter("directoryPath")
	p.cfgAnimationFile = config.getParameter("animation")
	p.victimAnimations = root.assetJson(p.vso.victimAnimations)
	p.stateconfig = config.getParameter("states")
	p.loungePositions = config.getParameter("loungePositions")
	p.animStateData = root.assetJson( p.directoryPath .. p.cfgAnimationFile ).animatedParts.stateTypes
	p.config = root.assetJson( "/vehicles/spov/pvso_general.config")
	p.transformGroups = root.assetJson( p.directoryPath .. p.cfgAnimationFile ).transformationGroups
	p.settings = p.config.defaultSettings
	p.settings = sb.jsonMerge(p.settings, config.getParameter( "settings", p.config.defaultSettings ))
	p.spawner = config.getParameter("spawner")

	--[[
	so, the thing is, we want this to move like an actor, even if it is a vehicle, so we have to have a little funny business,
	both mcontrollers use the same arguments for the most part, just the actor mcontroller has more values, as well as some
	different function names, however the json for the data is what is the most important and thats the same for what is shared,
	therefore, if we try and set the params to the default actor ones, and then merge the humanoid ones on top
	that could help with the illusion yes?
	]]
	p.movementParams = sb.jsonMerge(root.assetJson("/default_actor_movement.config"), root.assetJson("/player.config:movementParameters"))
	p.movementParams = sb.jsonMerge(p.movementParams, root.assetJson("/humanoid.config:movementParameters"))
	p.movementParams.jumpCount = 1

	mcontroller.applyParameters(p.movementParams)

	p.movementParamsName = "default"
	p.faceDirection(config.getParameter("direction", 1)) -- the hitbox and default movement params are set here

	p.resetOccupantCount()

	for i = 1, p.vso.maxOccupants.total do
		p.occupant[i] = p.clearOccupant(i)
		p.seats["occupant"..i] = p.occupant[i]
	end

	for _, state in pairs(p.animStateData) do
		state.animationState = {
			anim = state.default,
			priority = state.states[state.default].priority,
			cycle = state.states[state.default].cycle,
			frames = state.states[state.default].frames,
			time = 0,
			queue = {},
		}
		state.tag = nil
	end

	if not config.getParameter( "uneaten" ) then
		world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect
	end

	p.driver = config.getParameter( "driver" )
	p.occupant[0] = p.clearOccupant(0)
	p.occupant[0].id = p.driver
	p.occupant[0].seatname = "driver"
	p.occupant[0].visible = false
	p.seats.driver = p.occupant[0]
	p.driverSeat = "driver"

	if p.driver ~= nil then
		p.entity[p.driver] = p.occupant[0]
		p.standalone = true
		p.driving = true
		p.spawner = p.driver
		p.forceSeat( p.driver, "driver" )
		world.sendEntityMessage( p.driver, "giveVoreController")
	else
		p.driving = false
		p.standalone = false
		vehicle.setLoungeEnabled( "driver", false )
	end
	p.spawnerUUID = world.entityUniqueId(p.spawner)

	if entity.uniqueId() ~= nil then
		world.setUniqueId(entity.id(), sb.makeUuid())
		sb.logInfo("uuid"..entity.uniqueId())
	end

	p.onForcedReset()	--Do a forced reset once.

	message.setHandler( "settingsMenuSet", function(_,_, val )
		p.settings = val
	end )

	message.setHandler( "letout", function(_,_, val )
		p.doTransition( "escape", {id = val} )
	end )

	message.setHandler( "transform", function(_,_, val, eid )
		if p.entity[eid].progressBarActive then return end
		local val = val
		if val == nil then
			if p.stateconfig.smol ~= nil then
				val = config.getParameter("name")
			else
				return
			end
		end
		p.entity[eid].progressBarActive = true
		p.entity[eid].progressBarMode = 1
		p.entity[eid].progressBar = 0
		p.entity[eid].progressBarFinishFunc = function()
			p.entity[eid].species = val
		end
	end )

	message.setHandler( "settingsMenuRefresh", function(_,_)
		return {
			occupants = p.occupant,
			powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier
		}
	end)

	message.setHandler( "despawn", function(_,_, nowarpout)
		if p.driver then
			world.sendEntityMessage(p.driver, "PVSOClear")
		end
		p.nowarpout = nowarpout
		p.onDeath()
	end )

	message.setHandler( "digest", function(_,_, eid)
		local location = p.getLocationFromEid(eid)
		local success, timing = p.doTransition("digest"..location)
		return {success=success, timing=timing}
	end )

	message.setHandler( "uneat", function(_,_, eid)
		p.uneat( eid )
	end )

	message.setHandler( "smolPreyPath", function(_,_, seatindex, data)
		p.occupant[seatindex].smolPreyData = data
	end )

	p.state = "start" -- this state doesn't need to exist
	if not config.getParameter( "uneaten" ) then
		if not p.vso.startState then
			p.vso.startState = "stand"
		end
		p.setState( p.vso.startState )
		p.doAnims( p.stateconfig[p.vso.startState].idle, true )
	else -- released from larger pred
		p.setState( "smol" )
		p.doAnims( p.stateconfig.smol.idle, true )
	end

	onBegin()
end

p.totalTimeAlive = 0
function update(dt)
	p.checkSpawnerExists()
	p.totalTimeAlive = p.totalTimeAlive + dt
	p.dt = dt
	p.updateAnims(dt)
	p.checkRPCsFinished(dt)
	p.checkTimers(dt)
	p.idleStateChange(dt)

	p.updateControls(dt)
	p.updatePathfinding(dt)
	p.updateDriving(dt)

	p.updateOccupants(dt)
	p.handleStruggles(dt)
	p.handleBelly()
	p.applyStatusLists()

	p.emoteCooldown = p.emoteCooldown - dt
	p.update(dt)
	p.updateState(dt)
end

function uninit()
	if mcontroller.atWorldLimit()
	--or (world.entityHealth(entity.id()) <= 0) -- vehicles don't have health?
	then
		p.onDeath()
	end
end

-- returns sourcePosition, sourceId, and interactPosition
function onInteraction(args)

	local stateData = p.stateconfig[p.state]
	if p.entityLounging(args.sourceId) then
		-- should add some sort of script for if you're already prey here?
		return
	elseif p.notMoving() then
		p.showEmote( "emotehappy" )
		if stateData.interact ~= nil then
			if stateData.interact.side ~= nil  then
				local area = mcontroller.collisionBoundBox()
				local entities = world.entityQuery({area[1], area[2]}, {area[3], area[4]}, {
					includedTypes = {"creature"}
				})
				for i = 1, #entities do
					if entities[i] == args.sourceId then
						p.doTransition( p.occupantArray(stateData.interact.side).transition, {id=args.sourceId} )
						return
					end
				end
			end
			local interactPosition = p.globalToLocal( args.sourcePosition )
			if interactPosition[1] > 0 then
				p.doTransition( p.occupantArray(stateData.interact.front).transition, {id=args.sourceId} )
				return
			else
				p.doTransition( p.occupantArray(stateData.interact.back).transition, {id=args.sourceId} )
				return
			end
		elseif stateData.interact.animation ~= nil then
			p.doAnims( stateData.interact.animation )
		end
		if state[p.state].interact ~= nil then
			if state[p.state].interact() then
				return
			end
		end
	end
end

function p.logJson(arg)
	sb.logInfo(sb.printJson(arg))
end

function sameSign(num1, num2)
	if num1 <= 0 and num2 <= 0 then
		return true
	elseif num1 >=0 and num2 >=0 then
		return true
	else
		return false
	end
end

p.dtSinceList = {}
function p.dtSince(name, overwrite) -- used for when something isn't in the main update loop but knowing the dt since it was last called is good
	local last = p.dtSinceList[name] or 0
	if overwrite then
		p.dtSinceList[name] = p.totalTimeAlive
	end
	return p.totalTimeAlive - last
end

function p.facePoint(x)
	p.faceDirection(x - mcontroller.position()[1])
end

function p.faceDirection(x)
	if x > 0 then
		p.direction = 1
		animator.setFlipped(false)
	elseif x < 0 then
		p.direction = -1
		animator.setFlipped(true)
	end
	p.setMovementParams(p.movementParamsName)
end

function p.setMovementParams(name)
	p.movementParamsName = name
	local params = p.vso.movementSettings[name]
	if params.flip then
		for _, coords in ipairs(params.collisionPoly) do
			coords[1] = coords[1] * p.direction
		end
	end
	p.movementParams = sb.jsonMerge(p.movementParams, params)
	mcontroller.applyParameters(params)
end

function p.checkSpawnerExists()
	if world.entityExists(p.spawner) then
	elseif (p.spawnerUUID ~= nil) then
		p.loopedMessage("preyWarpDespawn", p.spawnerUUID, "pvsoPreyWarpRequest", {},
		function(data)
			p.spawnerUUID = nil
		end,
		function()
			p.spawnerUUID = nil
		end)
	else
		p.onDeath()
	end
end

function p.onForcedReset()
	animator.setAnimationRate( 1.0 );
	for i = 1, p.vso.maxOccupants.total do
		vehicle.setLoungeEnabled( "occupant"..i, false )
	end

	vehicle.setInteractive( true )

	p.emoteCooldown = 0

	onForcedReset()
end

function p.onDeath()
	world.sendEntityMessage(p.spawner, "saveVSOsettings", p.settings)

	if not p.nowarpout then
		world.spawnProjectile( "spovwarpouteffectprojectile", mcontroller.position(), entity.id(), {0,0}, true)
	end

	onEnd()
	vehicle.destroy()
end

p.rpcList = {}
function p.addRPC(rpc, callback, failCallback)
	if callback ~= nil then
		table.insert(p.rpcList, {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0})
	end
end

p.loopedMessages = {}
function p.loopedMessage(name, eid, message, args, callback, failCallback)
	if p.loopedMessages[name] == nil then
		p.loopedMessages[name] = {
			rpc = world.sendEntityMessage(eid, message, args),
			callback = callback,
			failCallback = failCallback
		}
	elseif p.loopedMessages[name].rpc:finished() then
		if p.loopedMessages[name].rpc:succeeded() and p.loopedMessages[name].callback ~= nil then
			p.loopedMessages[name].callback(p.loopedMessages[name].rpc:result())
		elseif p.loopedMessages[name].failCallback ~= nil then
			p.loopedMessages[name].failCallback()
		end
		p.loopedMessages[name] = nil
	end
end

function p.checkRPCsFinished(dt)
	for i, list in pairs(p.rpcList) do
		list.dt = list.dt + dt -- I think this is good to have, incase the time passed since the RPC was put into play is important
		if list.rpc:finished() then
			if list.rpc:succeeded() and list.callback ~= nil then
				list.callback(list.rpc:result(), list.dt)
			elseif list.failCallback ~= nil then
				list.failCallback(list.dt)
			end
			table.remove(p.rpcList, i)
		end
	end
end

p.timerList = {}

function p.randomTimer(name, min, max, callback)
	if name == nil or p.timerList[name] == nil then
		local timer = {
			targetTime = (math.random(min * 100, max * 100))/100,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			p.timerList[name] = timer
		else
			table.insert(p.timerList, timer)
		end
		return true
	end
end

function p.timer(name, time, callback)
	if name == nil or p.timerList[name] == nil then
		local timer = {
			targetTime = time,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			p.timerList[name] = timer
		else
			table.insert(p.timerList, timer)
		end
		return true
	end
end

function p.checkTimers(dt)
	for name, timer in pairs(p.timerList) do
		timer.currTime = timer.currTime + dt
		if timer.currTime >= timer.targetTime then
			if timer.callback ~= nil then
				timer.callback()
			end
			if type(name) == "number" then
				table.remove(p.timerList, name)
			else
				p.timerList[name] = nil
			end
		end
	end
end

function p.applyStatusEffects(eid, statuses)
	for i = 1, #statuses do
		world.sendEntityMessage(eid, "applyStatusEffect", statuses[i][1], statuses[i][2], entity.id())
	end
end

function p.applyStatusLists()
	for i = 0, #p.occupant do
		if p.occupant[i].id ~= nil and world.entityExists(p.occupant[i].id) then
			p.loopedMessage( p.occupant[i].seatname.."StatusEffects", p.occupant[i].id, "pvsoApplyStatusEffects", p.occupant[i].statList )
			p.loopedMessage( p.occupant[i].seatname.."ForceSeat", p.occupant[i].id, "pvsoForceSit", {index=i, source=entity.id()})
		end
	end
end

function p.addStatusToList(index, status, power, source)
	p.occupant[index].statList[status] = {
		power = power or 1,
		source = source or entity.id()
	}
end

function p.removeStatusFromList(index, status)
	p.occupant[index].statList[status] = nil
end

function p.forceSeat( occupantId, seatname )
	if occupantId then
		vehicle.setLoungeEnabled(seatname, true)
		local seat = p.getIndexFromSeatname(seatname)
		world.sendEntityMessage( occupantId, "pvsoForceSit", {index=seat, source=entity.id()})
	end
end

function p.unForceSeat(occupantId)
	if occupantId then
		world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoRemoveForceSit", 1, entity.id())
	end
end

function p.locationFull(location)
	if p.occupants.total == p.vso.maxOccupants.total then
		return true
	else
		return p.occupants[location] == p.vso.maxOccupants[location]
	end
end

function p.locationEmpty(location)
	if p.occupants.total == 0 then
		return true
	else
		return p.occupants[location] == 0
	end
end

function p.doVore(args, location, statuses, sound )
	if p.eat( args.id, location ) then
		vehicle.setInteractive( false )
		p.showEmote("emotehappy")
		p.transitionLock = true
		--vsoVictimAnimSetStatus( "occupant"..i, statuses );
		return true, function()
			p.transitionLock = false
			vehicle.setInteractive( true )
			if sound then animator.playSound( sound ) end
		end
	else
		return false
	end
end

function p.doEscape(args, location, statuses, afterstatus )
	if p.locationEmpty(location) then return false end
	local victim = args.id

	if not victim then -- could be part of above but no need to log an error here
		return false
	end
	vehicle.setInteractive( false )
	--vsoVictimAnimSetStatus( "occupant"..i, statuses );
	p.transitionLock = true

	return true, function()
		p.transitionLock = false
		vehicle.setInteractive( true )
		p.uneat( victim )
		--world.sendEntityMessage( victim, "applyStatusEffect", afterstatus.status, afterstatus.duration, entity.id() )
	end
end

function p.doEscapeNoDelay(args, location, afterstatus )
	if p.locationEmpty(location) then return false end
	local victim = args.id

	if not victim then -- could be part of above but no need to log an error here
		return false
	end

	vehicle.setInteractive( true )
	p.uneat( victim )
	--world.sendEntityMessage( victim, "applyStatusEffect", afterstatus.status, afterstatus.duration, entity.id() )
end


function p.checkEatPosition(position, location, transition, noaim)
	if not p.locationFull(location) then
		local prey = world.entityQuery(position, 2, {
			withoutEntityId = p.driver,
			includedTypes = {"creature"}
		})
		local entityaimed = world.entityQuery(p.seats[p.driverSeat].controls.aim, 2, {
			withoutEntityId = p.driver,
			includedTypes = {"creature"}
		})
		local aimednotlounging = p.firstNotLounging(entityaimed)

		if #prey > 0 then
			for i = 1, #prey do
				if ((prey[i] == entityaimed[aimednotlounging]) or noaim) and not p.entityLounging(prey[i]) then
					p.doTransition( transition, {id=prey[i]} )
					return true
				end
			end
		end
		return false
	end
end

function p.firstNotLounging(entityaimed)
	for i = 1, #entityaimed do
		if not p.entityLounging(entityaimed[i]) then
			return i
		end
	end
end

function p.moveOccupantLocation(args, part, location)
	if p.locationFull(location) then return false end
	p.occupant[args.index].location = location
	return true
end

function p.findFirstIndexForLocation(location)
	for i = 1, p.occupants.total do
		if p.occupant[i].location == location then
			return i
		end
	end
	return
end

function p.showEmote( emotename ) --helper function to express a emotion particle "emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if p.emoteCooldown < 0 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
		p.emoteCooldown = 0.2; -- seconds
	end
end
function p.resetOccupantCount()
	p.occupants.total = 0
	for i = 1, #p.vso.locations.regular do
		p.occupants[p.vso.locations.regular[i]] = 0
	end
	if p.vso.locations.sided then
		for i = 1, #p.vso.locations.sided do
			p.occupants[p.vso.locations.sided[i].."R"] = 0
			p.occupants[p.vso.locations.sided[i].."L"] = 0
		end
	end
	p.occupants.fatten = p.settings.fatten or 0
	p.occupants.mass = 0
end

function p.updateOccupants(dt)
	p.resetOccupantCount()

	local lastFilled = true
	for i = 1, p.vso.maxOccupants.total do
		if p.occupant[i].id and world.entityExists(p.occupant[i].id) then

			p.occupants.total = p.occupants.total + 1
			p.occupants[p.occupant[i].location] = p.occupants[p.occupant[i].location] + 1
			for i = 1, #p.vso.locations.mass do
				if p.vso.locations.mass[i] == p.occupant[i].location then
					p.occupants.mass = p.occupants.mass + p.occupant[i].controls.mass
				end
			end

			if not lastFilled and p.swapCooldown <= 0 then
				p.swapOccupants( i-1, i )
				i = i - 1
			end
			p.entity[p.occupant[i].id] = p.occupant[i]
			p.occupant[i].index = i
			p.occupant[i].seatname = "occupant"..i
			p.seats["occupant"..i] = p.occupant[i]
			vehicle.setLoungeEnabled("occupant"..i, true)
			p.occupant[i].occupantTime = p.occupant[i].occupantTime + dt
			if p.occupant[i].progressBarActive == true then
				p.occupant[i].progressBar = p.occupant[i].progressBar + (((math.log(p.occupant[i].controls.powerMultiplier)+1) * dt) * p.occupant[i].progressBarMode)
				if p.occupant[i].progressBarMode == 1 then
					p.occupant[i].progressBar = math.min(100, p.occupant[i].progressBar)
					if p.occupant[i].progressBar >= 100 then
						p.occupant[i].progressBarFinishFunc()
						p.occupant[i].progressBar = 0
						p.occupant[i].progressBarActive = false
					end
				else
					p.occupant[i].progressBar = math.max(0, p.occupant[i].progressBar)
					if p.occupant[i].progressBar <= 0 then
						p.occupant[i].progressBarFinishFunc()
						p.occupant[i].progressBar = 0
						p.occupant[i].progressBarActive = false
					end
				end
			end
			lastFilled = true
		else
			p.occupant[i] = p.clearOccupant(i)
			lastFilled = false
			vehicle.setLoungeEnabled("occupant"..i, false)
		end
	end
	p.swapCooldown = math.max(0, p.swapCooldown - 1)

	for i = 1, #p.vso.locations.mass do
		if p.vso.locations.mass[i] == "fatten" then
			p.occupants.mass = p.occupants.mass + p.occupants.fatten
		end
	end

	for _, combine in ipairs(p.vso.locations.combine) do
		for j = 2, #combine do
			p.occupants[ combine[1] ] = p.occupants[ combine[1] ]+p.occupants[ combine[j] ]
			if p.occupants[ combine[1] ] > p.vso.maxOccupants[ combine[1] ] then
				p.occupants[ combine[1] ] = p.vso.maxOccupants[ combine[1] ]
			end
			p.occupants[ combine[j] ] = p.occupants[ combine[1] ]
		end
	end

	mcontroller.applyParameters({mass = p.movementParams.mass + p.occupants.mass})

	animator.setGlobalTag( "totaloccupants", tostring(p.occupants.total) )
	for i = 1, #p.vso.locations.regular do
		animator.setGlobalTag( p.vso.locations.regular[i].."occupants", tostring(p.occupants[p.vso.locations.regular[i]]) )
	end

	if p.vso.locations.sided then
		for i = 1, #p.vso.locations.sided do
			if p.direction >= 1 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
				animator.setGlobalTag( p.vso.locations.sided[i].."2occupants", tostring(p.occupants[p.vso.locations.sided[i].."R"]) )
				animator.setGlobalTag( p.vso.locations.sided[i].."1occupants", tostring(p.occupants[p.vso.locations.sided[i].."L"]) )
			else
				animator.setGlobalTag( p.vso.locations.sided[i].."1occupants", tostring(p.occupants[p.vso.locations.sided[i].."R"]) )
				animator.setGlobalTag( p.vso.locations.sided[i].."2occupants", tostring(p.occupants[p.vso.locations.sided[i].."L"]) )
			end
		end
	end
end

function p.localToGlobal( position )
	local lpos = { position[1], position[2] }
	if p.direction == -1 then lpos[1] = -lpos[1] end
	local mpos = mcontroller.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end
function p.globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if p.direction == -1 then pos[1] = -pos[1] end
	return pos
end

function p.occupantArray( maybearray )
	if maybearray == nil or maybearray[1] == nil then -- not an array, check for eating
		if maybearray.location then
			if maybearray.failOnFull then
				if (maybearray.failOnFull ~= true) and (p.occupants[maybearray.location] >= maybearray.failOnFull) then return maybearray.failTransition
				elseif p.locationFull(maybearray.location) then return maybearray.failTransition end
			else
				if p.locationEmpty(maybearray.location) then return maybearray.failTransition end
			end
		end
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[(p.occupants[maybearray[1].location or "total"] or 0) + 1]
	end
end

function p.swapOccupants(a, b)
	local A = p.occupant[a]
	local B = p.occupant[b]
	p.occupant[a] = B
	p.occupant[b] = A

	if B then p.forceSeat( p.occupant[b].id, "occupant"..a ) end
	if A then p.forceSeat( p.occupant[a].id, "occupant"..b ) end

	p.swapCooldown = 100 -- p.unForceSeat and p.forceSeat are asynchronous, without some cooldown it'll try to swap multiple times and bad things will happen
end

function p.entityLounging( entity )
	if entity == p.driver then return true end
	for i = 1, p.vso.maxOccupants.total do
		if entity == p.occupant[i].id then return true end
	end
	return false
end

function p.edible( occupantId, seatindex, source )
	if p.driver ~= occupantId then return false end
	if p.occupants.total > 0 then return false end
	if p.stateconfig[p.state].edible then
		world.sendEntityMessage( source, "smolPreyPath", seatindex, p.getSmolPreyData())
		return true
	end
end

function p.getSmolPreyData()
	return {
		recieved = true,
		path = p.directoryPath,
		settings = p.settings,
		state = p.stateconfig.smol,
		animatedParts = root.assetJson( p.directoryPath .. p.cfgAnimationFile ).animatedParts
	}
end

function p.isMonster( id )
	if id == nil then return false end
	if not world.entityExists(id) then return false end
	return world.entityType(id) == "monster"
end

function p.inedible(occupantId)
	for i = 1, #p.config.inedibleCreatures do
		if world.entityType(occupantId) == p.config.inedibleCreatures[i] then return true end
	end
	return false
end

function p.eat( occupantId, location )
	local seatindex = p.occupants.total + 1

	if occupantId == nil or p.entityLounging(occupantId) or p.inedible(occupantId) or p.locationFull(location) then return false end -- don't eat self
	local loungeables = world.entityQuery( world.entityPosition(occupantId), 5, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.entityLounging", callScriptArgs = { occupantId }
	} )
	local edibles = world.entityQuery( world.entityPosition(occupantId), 2, {
		withoutEntityId = entity.id(), includedTypes = { "vehicle" },
		callScript = "p.edible", callScriptArgs = { occupantId, seatindex, entity.id() }
	} )
	p.occupant[seatindex].location = location

	if edibles[1] == nil then
		if loungeables[1] == nil then -- now just making sure the prey doesn't belong to another loungable now
			p.occupant[seatindex].id = occupantId
			world.sendEntityMessage(occupantId, "pvsoMakeNonHostile")
			p.forceSeat( occupantId, "occupant"..seatindex )
			p.updateOccupants(0)
			p.justAte = true
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] ) -- "spov"..species
	p.occupant[seatindex].id = occupantId
	p.occupant[seatindex].species = species
	p.forceSeat( occupantId, "occupant"..seatindex )
	world.sendEntityMessage( edibles[1], "despawn", true ) -- no warpout
	p.occupant[seatindex].visible = false
	p.updateOccupants(0)
	p.justAte = true
	return true
end

function p.uneat( occupantId )
	world.sendEntityMessage( occupantId, "PVSOClear")
	world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoRemoveBellyEffects")
	p.unForceSeat( occupantId )
	seatindex = p.entity[occupantId].index
	local occupantData = p.entity[occupantId]
	p.occupant[seatindex] = p.clearOccupant(seatindex)
	if occupantData.species ~= nil then
		world.spawnVehicle( occupantData.species, p.localToGlobal({ occupantData.victimAnim.last.x or 0, occupantData.victimAnim.last.y or 0}), { driver = occupantId, settings = occupantData.smolPreyData.settings, uneaten = true } )
	end
end

-------------------------------------------------------------------------------

function p.getOccupantFromEid(eid)
	if p.entity[eid] ~= nil then
		return p.entity[eid].index
	end
end

function p.getSeatnameFromEid(eid)
	if p.entity[eid] ~= nil then
		return p.entity[eid].seatname
	end
end

function p.getLocationFromEid(eid)
	if p.entity[eid] ~= nil then
		return p.entity[eid].location
	end
end

function p.getIndexFromEid(eid)
	if p.entity[eid] ~= nil then
		return p.entity[eid].index
	end
end

function p.getEidFromSeatname(seatname)
	if p.seats[seatname] ~= nil then
		return p.seats[seatname].id
	end
end

function p.getIndexFromSeatname(seatname)
	if p.seats[seatname] ~= nil then
		return p.seats[seatname].index
	end
end

function p.getLocationFromSeatname(seatname)
	if p.seats[seatname] ~= nil then
		return p.seats[seatname].location
	end
end

function p.getEidFromIndex(index)
	if p.occupant[index] ~= nil then
		return p.occupant[index].id
	end
end

-------------------------------------------------------------------------------

function p.notMoving()
	return (math.abs(mcontroller.xVelocity()) < 0.1) and mcontroller.onGround()
end

function p.underWater()
	return mcontroller.liquidPercentage() >= p.movementParams.minimumLiquidPercentage
end

function p.useEnergy(eid, cost, callback)
	p.addRPC( world.sendEntityMessage(eid, "useEnergy", cost), callback)
end

-------------------------------------------------------------------------------

function p.handleBelly()
	if p.occupants.total > 0 then
		if p.driver ~= nil then
			p.doBellyEffects(p.driver, math.log(p.seats[p.driverSeat].controls.powerMultiplier)+1)
		else
			p.doBellyEffects(false, p.standalonePowerLevel())
		end
	end
end

function p.standalonePowerLevel()
	local power = world.threatLevel()
	if type(power) ~= "number" or power < 1 then return 1 end
	return power
end

p.restoreHunger = 0
function p.doBellyEffects(driver, powerMultiplier)
	local status = p.settings.bellyEffect or "pvsoRemoveBellyEffects"
	local hungereffect = p.settings.hungerEffect or 0

	for i = 1, p.vso.maxOccupants.total do
		local eid = p.occupant[i].id

		if eid and world.entityExists(eid) then
			local health = world.entityHealth(eid)
			local light = p.vso.lights.prey
			light.position = world.entityPosition( eid )
			world.sendEntityMessage( eid, "PVSOAddLocalLight", light )

			if p.isLocationDigest(p.occupant[i].location) then
				if (p.settings.bellySounds == true) and p.randomTimer( "gurgle", 1.0, 8.0 ) then animator.playSound( "digest" ) end
				local hunger_change = (hungereffect * powerMultiplier * p.dt)/100
				if status ~= nil and status ~= "" then world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, entity.id() ) end
				if (p.settings.bellyEffect == "pvsoSoftDigest" or p.settings.bellyEffect == "pvsoDisplaySoftDigest") and health[1] <= 1 then hunger_change = 0 end
				if driver then
					world.sendEntityMessage( driver, "addHungerHealth", hunger_change)
				end
				p.extraBellyEffects(i, eid, health, status)
			else
				p.otherLocationEffects(i, eid, health, status)
			end
		end
	end
end

function p.isLocationDigest(location)
	for i = 1, #p.vso.locations.digest do
		if p.vso.locations.digest[i] == location then
			return true
		end
	end
	return false
end

p.struggleCount = 0
p.bellySettleDownTimer = 5

function p.handleStruggles(dt)
	local struggler = -1
	local struggledata
	local movedir = nil

	while (movedir == nil) and struggler < p.vso.maxOccupants.total do
		struggler = struggler + 1
		movedir = p.getSeatDirections( p.occupant[struggler].seatname )
		if p.occupant[struggler].seatname == p.driverSeat then
			movedir = nil
		end
		p.occupant[struggler].bellySettleDownTimer = math.max( 0, p.occupant[struggler].bellySettleDownTimer - dt)
		if p.occupant[struggler].bellySettleDownTimer <= 0 then
			p.occupant[struggler].struggleCount = math.max( 0, p.occupant[struggler].struggleCount - 1)
			p.occupant[struggler].bellySettleDownTimer = 4
		end

		struggledata = p.stateconfig[p.state].struggle[p.occupant[struggler].location]
		if movedir then
			if (struggledata == nil) or (struggledata[movedir] == nil) then
				movedir = nil
			elseif not p.hasAnimEnded( struggledata.part.."State" )
			and (
				p.animationIs( struggledata.part.."State", "s_up" ) or
				p.animationIs( struggledata.part.."State", "s_front" ) or
				p.animationIs( struggledata.part.."State", "s_back" ) or
				p.animationIs( struggledata.part.."State", "s_down" )
			)then
				movedir = nil
			else
				for i = 1, #p.config.speciesStrugglesDisabled do
					if p.occupant[struggler].species == p.config.speciesStrugglesDisabled[i] then
						movedir = nil
					end
				end
			end
		end
	end
	if movedir == nil then return end -- invalid struggle

	local strugglerId = p.occupant[struggler].id

	if struggledata.script ~= nil then
		local statescript = state[p.state][struggledata.script]
		statescript({index = struggler, id = strugglerId, direction = movedir})
	end

	local chances = struggledata.chances
	if struggledata[movedir].chances ~= nil then
		chances = struggledata[movedir].chances
	end
	if chances[p.settings.escapeModifier] ~= nil then
		chances = chances[p.settings.escapeModifier]
	end
	if chances ~= nil and (math.random(chances.min, chances.max) <= p.occupant[struggler].struggleCount) then
		p.doTransition( struggledata[movedir].transition, {index = struggler, direction = movedir, id = strugglerId} )
	else
		p.occupant[struggler].struggleCount = p.occupant[struggler].struggleCount + 1
		p.occupant[struggler].bellySettleDownTimer = 5

		sb.setLogMap("b", "struggle")
		local animation = {offset = struggledata[movedir].offset}
		animation[struggledata.part] = "s_"..movedir

		p.doAnims(animation)

		if not p.movement.animating then
			p.doAnims( struggledata[movedir].animation or struggledata.animation )
		else
			p.doAnims( struggledata[movedir].animationWhenMoving or struggledata.animationWhenMoving )
		end

		if struggledata[movedir].victimAnimation then
			p.doVictimAnim( strugglerId, struggledata[movedir].victimAnimation, struggledata.part.."State" )
		end
		animator.playSound( "struggle" )
	end
end

function p.randomChance(percent)
	return math.random() <= (percent/100)
end
