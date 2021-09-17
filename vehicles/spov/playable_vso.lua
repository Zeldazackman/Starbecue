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
	isPathfinding = false,
	hunger = 100
}

p.settings = {}

p.modifierItem = {}

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
	local seatname = "occupant"..i
	if i == 0 then
		seatname = "driver"
	end
	return {
		seatname = seatname,
		index = i,
		id = nil,
		statList = p.vso.occupantStatusEffects or {},
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
		progressBarData = nil,
		progressBarMultiplier = 1,
		progressBarFinishFunc = nil,
		progressBarColor = nil,
		victimAnim = { enabled = false, last = { x = 0, y = 0 } },
		indicatorCooldown = 0,
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

	p.settings = sb.jsonMerge(sb.jsonMerge(p.config.defaultSettings, p.vso.defaultSettings or {}), config.getParameter( "settings" ) or {})

	p.spawner = config.getParameter("spawner")
	p.settings.directives = p.vso.defaultDirectives or ""

	if mcontroller_extensions then
		for k,v in pairs(mcontroller_extensions) do
			mcontroller[k] = v
		end
	end

	p.setColorReplaceDirectives()
	p.setSkinPartTags()
	--[[
	so, the thing is, we want this to move like an actor, even if it is a vehicle, so we have to have a little funny business,
	both mcontrollers use the same arguments for the most part, just the actor mcontroller has more values, as well as some
	different function names, however the json for the data is what is the most important and thats the same for what is shared,
	therefore, if we try and set the params to the default actor ones, and then merge the humanoid ones on top
	that could help with the illusion yes?
	]]
	p.movementParams = sb.jsonMerge(sb.jsonMerge(root.assetJson("/default_actor_movement.config"), root.assetJson("/humanoid.config:movementParameters")), root.assetJson("/player.config:movementParameters"))
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

	if p.driver ~= nil then
		p.occupant[0].id = p.driver
		p.driverSeat = "driver"
		p.seats.driver = p.occupant[0]
		p.occupant[0].visible = false
		p.occupant[0].statList = p.vso.driverStatusEffects or {}

		p.entity[p.driver] = p.occupant[0]
		p.driving = true
		p.spawner = p.driver
		p.forceSeat( p.driver, "driver" )
		world.sendEntityMessage( p.driver, "giveVoreController")
	else
		p.seats.objectControls = p.clearOccupant(0)
		p.seats.objectControls.seatname = "objectControls"
		p.seats.objectControls.controls.powerMultiplier = p.objectPowerLevel()
		p.driverSeat = "objectControls"
		p.includeDriver = true
		p.driving = false
		p.isObject = true
		vehicle.setLoungeEnabled( "driver", false )
	end
	if p.settings.blackHoleBelly then
		p.vso.maxOccupants.total = 7
		if p.includeDriver then
			p.vso.maxOccupants.total = 8
		end
	end

	p.spawnerUUID = world.entityUniqueId(p.spawner)

	if entity.uniqueId() ~= nil then
		world.setUniqueId(entity.id(), sb.makeUuid())
		sb.logInfo("uuid"..entity.uniqueId())
	end

	p.onForcedReset()	--Do a forced reset once.

	message.setHandler( "settingsMenuSet", function(_,_, val )
		p.settings = val
		p.setColorReplaceDirectives()
		p.setSkinPartTags()
	end )

	message.setHandler( "letout", function(_,_, id )
		p.letout(id)
	end )

	message.setHandler( "transform", function(_,_, data, eid, multiplier )
		if p.entity[eid].progressBarActive then return end

		if data then
			if data.species == p.entity[eid].species then return end
		else
			if p.entity[eid].species == world.entityName( entity.id() ):sub( 5 ) then return end
		end

		p.entity[eid].progressBarActive = true
		p.entity[eid].progressBar = 0
		p.entity[eid].progressBarData = data
		if data == nil then
			p.entity[eid].progressBarColor = p.vso.replaceColors[1][p.settings.replaceColors[1] + 1] -- pred body color
		elseif data.barColor ~= nil then
			p.entity[eid].progressBarColor = data.barColor
		else
			-- p.entity[eid].progressBarColor = root.assetJson("something about data:vso.replaceColors.0.1")
			-- or maybe define it some other way, I dunno
		end
		p.entity[eid].progressBarMultiplier = multiplier or 1
		p.entity[eid].progressBarFinishFuncName = "transformPrey"
	end )

	message.setHandler( "settingsMenuRefresh", function(_,_)
		p.settingsMenuOpen = 0.5
		local refreshList = p.refreshList
		p.refreshList = nil
		return {
			occupants = p.occupant,
			powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier,
			settings = p.settings,
			refreshList = refreshList,
			locked = p.transitionLock
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

	message.setHandler( "smolPreyData", function(_,_, seatindex, data, vso)
		world.sendEntityMessage( vso, "despawn", true ) -- no warpout
		p.occupant[seatindex].smolPreyData = data
	end )

	message.setHandler( "indicatorClosed", function(_,_, eid)
		p.entity[eid].indicatorCooldown = 2
	end )

	p.state = "start" -- this state doesn't need to exist
	if not (config.getParameter( "uneaten" ) or p.settings.defaultSmall) then
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
	p.doBellyEffects(dt)
	p.applyStatusLists()

	p.emoteCooldown = p.emoteCooldown - dt
	p.settingsMenuOpen = p.settingsMenuOpen - dt
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

function p.eatFeedableHandItems(entity)
	if p.eatHandItem(entity, "primary") then return true end
	if p.eatHandItem(entity, "alt") then return true end
end

function p.eatHandItem(entity, hand)
	local item = world.entityHandItem(entity, hand)
	local modifierType = p.checkModifierItem(item)
	if modifierType ~= nil and p.modifierItem[modifierType] ~= nil then
		p.modifierItem[modifierType](entity, item)
		world.sendEntityMessage(entity, "pvsoEatItem", item)
		world.sendEntityMessage(p.spawner, "saveVSOsettings", p.settings)
	else
		-- probably can make it eat normal items here
	end
end

function p.modifierItem.none(entity, item)
	p.settings.bellyEffect = "pvsoRemoveBellyEffects"
	p.settings.displayDamage = false
end

function p.modifierItem.heal(entity, item)
	p.settings.bellyEffect = p.getDisplayBellyEffect("pvsoVoreHeal")
end

function p.modifierItem.digest(entity, item)
	p.settings.bellyEffect = p.getDisplayBellyEffect("pvsoDigest")
end

function p.modifierItem.softDigest(entity, item)
	p.settings.bellyEffect = p.getDisplayBellyEffect("pvsoSoftDigest")
end

function p.modifierItem.displayDamage(entity, item)
	p.settings.displayDamage = true
	p.settings.bellyEffect = p.getDisplayBellyEffect(p.settings.bellyEffect)
end

function p.modifierItem.easyEscape(entity, item)
	if p.settings.escapeModifier == "antiEscape" then
		p.settings.escapeModifier = "normal"
	else
		p.settings.escapeModifier = "easyEscape"
	end
end

function p.modifierItem.antiEscape(entity, item)
	if p.settings.escapeModifier == "easyEscape" then
		p.settings.escapeModifier = "normal"
	else
		p.settings.escapeModifier = "antiEscape"
	end
end

function p.modifierItem.fatten(entity, item)
	p.settings.fatten = math.max(0, p.settings.fatten + 1)
end

function p.modifierItem.diet(entity, item)
	p.settings.fatten = math.max(0, p.settings.fatten - 1)
end


function p.getDisplayBellyEffect(effect)
	local displayEffect = p.config.bellyDisplayStatusEffects[effect]
	if p.settings.displayDamage and displayEffect ~= nil then
		return displayEffect
	else
		return effect
	end
end

function p.checkModifierItem(item)
	for modifierType, modifierItemList in pairs(p.config.pvsoModifiers) do
		for i, modifierItem in ipairs(modifierItemList) do
			if item == modifierItem then
				return modifierType
			end
		end
	end
end

p.settingsMenuOpen = 0
-- returns sourcePosition, sourceId, and interactPosition
function onInteraction(args)
	if p.transitionLock then return end
	local stateData = p.stateconfig[p.state]

	if not p.driver then
		if p.eatFeedableHandItems(args.sourceId) then p.showEmote( "emotehappy" ) return end
	end

	if p.entityLounging(args.sourceId) then
		if args.sourceId == p.driver then
			-- open the settings menu if you're the driver
			if p.settingsMenuOpen > 0 then
				world.sendEntityMessage(p.driver, "openPVSOInterface", "close", {}, false, entity.id())
			else
				world.sendEntityMessage(
					p.driver, "openPVSOInterface", world.entityName( entity.id() ):sub( 5 ).."Settings",
					{ vso = entity.id(), occupants = p.occupant, maxOccupants = p.vso.maxOccupants.total, powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier }, false, entity.id()
				)
			end
		else
			-- should add some sort of script for if you're already prey here?
		end
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
						p.interactChance(stateData, "side", args)
						return
					end
				end
			end
			local interactPosition = p.globalToLocal( args.sourcePosition )
			if interactPosition[1] > 0 then
				p.interactChance(stateData, "front", args)
				return
			else
				p.interactChance(stateData, "back", args)
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

function p.interactChance(stateData, direction, args)
	if not (stateData.interact[direction].drivingEnabled or (not p.driver)) then return end
	if stateData.interact[direction].chance then
		if math.random() <= (stateData.interact[direction].chance/100) then
			p.doTransition( p.occupantArray(stateData.interact[direction]).transition, {id=args.sourceId} )
		end
	else
		p.doTransition( p.occupantArray(stateData.interact[direction]).transition, {id=args.sourceId} )
	end
end


function p.logJson(arg)
	sb.logInfo(sb.printJson(arg, 1))
end

function p.sameSign(num1, num2)
	if num1 < 0 and num2 < 0 then
		return true
	elseif num1 > 0 and num2 > 0 then
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
	if p.movementParamsName ~= name then
		p.activeControls.parameters = {}
	end
	p.movementParamsName = name
	local params = config.getParameter("vso").movementSettings[name]
	if params.flip then
		for _, coords in ipairs(params.collisionPoly) do
			coords[1] = coords[1] * p.direction
		end
	end
	p.movementParams = sb.jsonMerge(sb.jsonMerge(p.movementParams, params), p.activeControls.parameters)
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
		for i = 0, #p.occupant do
			if p.occupant[i].id ~= nil then
				p.occupant[i].visible = true
				world.sendEntityMessage(p.occupant[i].id, "applyStatusEffect", "pvsoRemoveInvisible")
			end
		end
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
			rpc = world.sendEntityMessage(eid, message, table.unpack(args or {})),
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
			p.loopedMessage( p.occupant[i].seatname.."NonHostile", p.occupant[i].id, "pvsoMakeNonHostile")
			p.loopedMessage( p.occupant[i].seatname.."StatusEffects", p.occupant[i].id, "pvsoApplyStatusEffects", {p.occupant[i].statList} )
			p.loopedMessage( p.occupant[i].seatname.."ForceSeat", p.occupant[i].id, "pvsoForceSit", {{index=i, source=entity.id()}})
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
		world.sendEntityMessage(occupantId, "pvsoMakeNonHostile")
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
		p.justAte = args.id
		vehicle.setInteractive( false )
		p.showEmote("emotehappy")
		p.transitionLock = true
		--vsoVictimAnimSetStatus( "occupant"..i, statuses );
		return true, function()
			p.justAte = nil
			p.transitionLock = false
			vehicle.setInteractive( true )
			if sound then animator.playSound( sound ) end
		end
	else
		return false
	end
end

function p.doEscape(args, statuses, afterstatus )
	local victim = args.id
	if not victim then return false end -- could be part of above but no need to log an error here

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

function p.checkValidAim(seat, range)
	local entityaimed = world.entityQuery(p.seats[seat].controls.aim, range or 2, {
		withoutEntityId = p.driver,
		includedTypes = {"creature"}
	})
	local target = p.firstNotLounging(entityaimed)

	if target and entity.entityInSight(target) then
		return target
	end
end

function p.checkEatPosition(position, range, location, transition, noaim, aimrange)
	if not p.locationFull(location) then
		local target = p.checkValidAim(p.driverSeat, aimrange)

		local prey = world.entityQuery(position, range, {
			withoutEntityId = p.driver,
			includedTypes = {"creature"}
		})

		for _, entity in ipairs(prey) do
			if (noaim or (entity == target)) and not p.entityLounging(entity) then
				p.doTransition( transition, {id=entity} )
				return true
			end
		end
		return false
	end
end

function p.firstNotLounging(entityaimed)
	for i = 1, #entityaimed do
		if not p.entityLounging(entityaimed[i]) then
			return entityaimed[i]
		end
	end
end

function p.moveOccupantLocation(args, location)
	if p.locationFull(location) then return false end
	return true, function()
		p.entity[args.id].location = location
	end
end

function p.findFirstOccupantIdForLocation(location)
	for i = 1, p.occupants.total do
		if p.occupant[i].location == location then
			return p.occupant[i].id, i
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
	for location, data in pairs(p.vso.locations) do
		if data.sided then
			p.occupants[location.."R"] = 0
			p.occupants[location.."L"] = 0
		else
			p.occupants[location] = 0
		end
	end
	p.occupants.fatten = p.settings.fatten or 0
	p.occupants.mass = 0
end

function p.updateOccupants(dt)
	p.resetOccupantCount()

	local lastFilled = true
	local start = 1
	if p.includeDriver then
		start = 0
	end
	for i = start, p.vso.maxOccupants.total do
		if p.occupant[i].id and world.entityExists(p.occupant[i].id) then
			p.occupants.total = p.occupants.total + 1
			p.occupants[p.occupant[i].location] = p.occupants[p.occupant[i].location] + 1
			if not lastFilled and p.swapCooldown <= 0 then
				p.swapOccupants( i-1, i )
				i = i - 1
			end
			p.occupants.mass = p.occupants.mass + p.occupant[i].controls.mass * (p.vso.locations[p.occupant[i].location].mass or 0)
			p.entity[p.occupant[i].id] = p.occupant[i]
			p.occupant[i].index = i
			local seatname = "occupant"..i
			if i == 0 then
				seatname = "driver"
			end
			p.occupant[i].seatname = seatname
			p.seats[p.occupant[i].seatname] = p.occupant[i]
			vehicle.setLoungeEnabled(p.occupant[i].seatname, true)
			p.occupant[i].occupantTime = p.occupant[i].occupantTime + dt
			if p.occupant[i].progressBarActive == true then
				p.occupant[i].progressBar = p.occupant[i].progressBar + (((math.log(p.occupant[i].controls.powerMultiplier)+1) * dt) * p.occupant[i].progressBarMultiplier)
				if p.occupant[i].progressBarMultiplier > 0 then
					p.occupant[i].progressBar = math.min(100, p.occupant[i].progressBar)
					if p.occupant[i].progressBar >= 100 then
						p[p.occupant[i].progressBarFinishFuncName](i)
						p.occupant[i].progressBarActive = false
					end
				else
					p.occupant[i].progressBar = math.max(0, p.occupant[i].progressBar)
					if p.occupant[i].progressBar <= 0 then
						p[p.occupant[i].progressBarFinishFuncName](i)
						p.occupant[i].progressBarActive = false
					end
				end
			end
			p.occupant[i].indicatorCooldown = p.occupant[i].indicatorCooldown - dt
			if world.entityType(p.occupant[i].id) == "player" and p.occupant[i].indicatorCooldown <= 0 then
				-- p.occupant[i].indicatorCooldown = 0.5
				local struggledata = (p.stateconfig[p.state].struggle or {})[p.occupant[i].location] or {}
				local directions = {}
				if not p.transitionLock then
					for dir, data in pairs(struggledata.directions or {}) do
						if data and (not p.driving or data.drivingEnabled) then
							if dir == "front" then dir = ({"left","","right"})[p.direction+2] end
							if dir == "back" then dir = ({"right","","left"})[p.direction+2] end
							directions[dir] = data.indicate or "default"
						end
					end
				end
				p.loopedMessage(p.occupant[i].id.."-indicator", p.occupant[i].id, -- update quickly but minimize spam
					"openPVSOInterface", {"indicatorhud",
					{
						owner = entity.id(),
						directions = directions,
						progress = {
							active = p.occupant[i].progressBarActive,
							color = p.occupant[i].progressBarColor,
							percent = p.occupant[i].progressBar,
							dx = (math.log(p.occupant[i].controls.powerMultiplier)+1) * p.occupant[i].progressBarMultiplier,
						},
						time = p.occupant[i].occupantTime
					}
				})
			end

			lastFilled = true
		else
			p.refreshList = true
			p.occupant[i] = p.clearOccupant(i)
			lastFilled = false
			vehicle.setLoungeEnabled(p.occupant[i].seatname, false)
		end
	end
	p.swapCooldown = math.max(0, p.swapCooldown - 1)

	mcontroller.applyParameters({mass = p.movementParams.mass + p.occupants.mass})
	animator.setGlobalTag( "totaloccupants", tostring(p.occupants.total) )
	for location, data in pairs(p.vso.locations) do
		if data.combine ~= nil then -- this doesn't work for sided stuff, but I don't think we'll ever need combine for sided stuff
			for _, combine in ipairs(data.combine) do
				p.occupants[location] = p.occupants[location] + p.occupants[combine]
				p.occupants[combine] = p.occupants[location]
			end
		end
		if data.sided then
			if p.direction >= 1 then -- to make sure those in the balls in CV and breasts in BV cases stay on the side they were on instead of flipping
				animator.setGlobalTag( location.."2occupants", tostring(p.occupants[location.."R"]) )
				animator.setGlobalTag( location.."1occupants", tostring(p.occupants[location.."L"]) )
			else
				animator.setGlobalTag( location.."1occupants", tostring(p.occupants[location.."R"]) )
				animator.setGlobalTag( location.."2occupants", tostring(p.occupants[location.."L"]) )
			end
		else
			animator.setGlobalTag( location.."occupants", tostring(p.occupants[location]) )
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
		world.sendEntityMessage( source, "smolPreyData", seatindex, p.getSmolPreyData(), entity.id())
		return true
	end
end

function p.getSmolPreyData()
	return {
		species = world.entityName( entity.id() ):sub( 5 ),
		recieved = true,
		update = true,
		path = p.directoryPath,
		settings = p.settings,
		state = p.stateconfig.smol,
		animatedParts = root.assetJson( p.directoryPath .. p.cfgAnimationFile ).animatedParts
	}
end

function p.transformPrey(i)
	local smolPreyData
	if p.occupant[i].progressBarData ~= nil then
		smolPreyData = p.occupant[i].progressBarData
	else
		smolPreyData = p.getSmolPreyData()
	end
	if smolPreyData ~= nil then
		if world.entityType(p.occupant[i].id) == "player" and not smolPreyData.forceSettings then
			p.addRPC(world.sendEntityMessage(p.occupant[i].id, "loadVSOsettings", smolPreyData.species), function(settings)
				smolPreyData.settings = settings
				p.occupant[i].smolPreyData = smolPreyData
				p.occupant[i].species = smolPreyData.species
			end)
		else
			p.occupant[i].smolPreyData = smolPreyData
			p.occupant[i].species = smolPreyData.species
		end
	end
	p.refreshList = true
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
			p.forceSeat( occupantId, "occupant"..seatindex )
			p.updateOccupants(0)
			return true -- not lounging
		else
			return false -- lounging in something inedible
		end
	end
	-- lounging in edible smol thing
	local species = world.entityName( edibles[1] ):sub( 5 ) -- "spov"..species
	p.occupant[seatindex].id = occupantId
	p.occupant[seatindex].species = species
	p.forceSeat( occupantId, "occupant"..seatindex )
	p.updateOccupants(0)
	return true
end

function p.uneat( occupantId )
	if occupantId == nil or not world.entityExists(occupantId) then return end
	world.sendEntityMessage( occupantId, "PVSOClear")
	world.sendEntityMessage( occupantId, "applyStatusEffect", "pvsoRemoveBellyEffects")
	p.unForceSeat( occupantId )
	seatindex = p.entity[occupantId].index
	local occupantData = p.entity[occupantId]
	p.occupant[seatindex] = p.clearOccupant(seatindex)
	if world.entityType(occupantId) == "player" then
		world.sendEntityMessage(occupantId, "openPVSOInterface", "close")
	end
	if occupantData.species ~= nil then
		world.spawnVehicle( "spov"..occupantData.species, p.localToGlobal({ occupantData.victimAnim.last.x or 0, occupantData.victimAnim.last.y or 0}), { driver = occupantId, settings = occupantData.smolPreyData.settings, uneaten = true } )
	end
	return true
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

function p.objectPowerLevel()
	local power = world.threatLevel()
	if type(power) ~= "number" or power < 1 then return 1 end
	return power
end

function p.doBellyEffects(dt)
	if p.occupants.total <= 0 then return end

	local status = p.settings.bellyEffect or "pvsoRemoveBellyEffects"
	local hungereffect = p.settings.hungerEffect or 0
	local powerMultiplier = math.log(p.seats[p.driverSeat].controls.powerMultiplier) + 1
	local start = 1
	if p.includeDriver then
		start = 0
	end

	for i = start, p.vso.maxOccupants.total do
		local eid = p.occupant[i].id

		if eid and world.entityExists(eid) then
			local health = world.entityHealth(eid)
			local light = p.vso.lights.prey
			light.position = world.entityPosition( eid )
			world.sendEntityMessage( eid, "PVSOAddLocalLight", light )

			if p.vso.locations[p.occupant[i].location].digest then
				if (p.settings.bellySounds == true) and p.randomTimer( "gurgle", 1.0, 8.0 ) then animator.playSound( "digest" ) end
				local hunger_change = (hungereffect * powerMultiplier * dt)/100
				if status ~= nil and status ~= "" then world.sendEntityMessage( eid, "applyStatusEffect", status, powerMultiplier, entity.id() ) end
				if (p.settings.bellyEffect == "pvsoSoftDigest" or p.settings.bellyEffect == "pvsoDisplaySoftDigest") and health[1] <= 1 then hunger_change = 0 end
				if p.driver then
					world.sendEntityMessage( p.driver, "addHungerHealth", hunger_change)
				end
				p.hunger = math.min(100, p.hunger + hunger_change)

				p.extraBellyEffects(i, eid, health, status)
			else
				p.otherLocationEffects(i, eid, health, status)
			end
		end
	end
end

function p.partsAreStruggling(parts)
	for _, part in ipairs(parts) do
		if not p.hasAnimEnded( part.."State" )
		and (
			p.animationIs( part.."State", "s_up" ) or
			p.animationIs( part.."State", "s_front" ) or
			p.animationIs( part.."State", "s_back" ) or
			p.animationIs( part.."State", "s_down" )
		)
		then return true end
	end
end

function p.handleStruggles(dt)
	if p.transitionLock then return end
	local struggler = -1
	local struggledata
	local movedir = nil

	while (movedir == nil) and struggler < p.vso.maxOccupants.total do
		struggler = struggler + 1
		movedir = p.getSeatDirections( p.occupant[struggler].seatname )
		p.occupant[struggler].bellySettleDownTimer = math.max( 0, p.occupant[struggler].bellySettleDownTimer - dt)

		if (p.occupant[struggler].seatname == p.driverSeat) and not p.includeDriver then
			movedir = nil
		end
		if p.occupant[struggler].bellySettleDownTimer <= 0 then
			p.occupant[struggler].struggleCount = math.max( 0, p.occupant[struggler].struggleCount - 1)
			p.occupant[struggler].bellySettleDownTimer = 4
		end

		if movedir then
			struggledata = p.stateconfig[p.state].struggle[p.occupant[struggler].location]
			if struggledata == nil or struggledata.directions == nil or struggledata.directions[movedir] == nil then
				movedir = nil
			elseif p.partsAreStruggling(struggledata.parts) then
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
		if statescript ~= nil then
			statescript({index = struggler, id = strugglerId, direction = movedir})
		else
			sb.logError("no script named: ["..struggledata.script.."] in state: ["..p.state.."]")
		end
	end

	local chances = struggledata.chances
	if struggledata.directions[movedir].chances ~= nil then
		chances = struggledata.directions[movedir].chances
	end
	if chances~= nil and chances[p.settings.escapeModifier] ~= nil then
		chances = chances[p.settings.escapeModifier]
	end
	if chances ~= nil and (p.settings.escapeModifier ~= "noEscape")
	and (chances.min ~= nil) and (chances.max ~= nil)
	and (math.random(chances.min, chances.max) <= p.occupant[struggler].struggleCount)
	and ((not p.driving) or struggledata.directions[movedir].drivingEnabled)
	then
		p.occupant[struggler].struggleCount = 0
		p.doTransition( struggledata.directions[movedir].transition, {index = struggler, direction = movedir, id = strugglerId} )
	else
		p.occupant[struggler].struggleCount = p.occupant[struggler].struggleCount + 1
		p.occupant[struggler].bellySettleDownTimer = 5

		local animation = {offset = struggledata.directions[movedir].offset}
		for _, part in ipairs(struggledata.parts) do
			animation[part] = "s_"..movedir
		end

		p.doAnims(animation)

		if not p.movement.animating then
			p.doAnims( struggledata.directions[movedir].animation or struggledata.animation )
		else
			p.doAnims( struggledata.directions[movedir].animationWhenMoving or struggledata.animationWhenMoving )
		end

		if struggledata.directions[movedir].victimAnimation then
			p.doVictimAnim( strugglerId, struggledata.directions[movedir].victimAnimation, (struggledata.parts[1] or "body").."State" )
		end
		animator.playSound( "struggle" )
	end
end

function p.randomChance(percent)
	return math.random() <= (percent/100)
end
