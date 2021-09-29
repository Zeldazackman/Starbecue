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
	occupantSlots = 7, -- 0 indexed
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
p.lounging = {}

function p.clearOccupant(i)
	return {
		seatname = "occupant"..i,
		index = i,
		id = nil,
		statList = p.vso.occupantStatusEffects or {},
		visible = true,
		emote = "idle",
		dance = "idle",
		location = nil,
		species = nil,
		smolPreyData = {},
		nestedPreyData = {},
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
			special1 = 0,
			special2 = 0,
			special3 = 0,

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
require("/vehicles/spov/pvso_occupant_handling.lua")

function init()
	p.vso = config.getParameter("vso")
	p.directoryPath = config.getParameter("directoryPath")
	p.cfgAnimationFile = config.getParameter("animation")
	p.victimAnimations = root.assetJson(p.vso.victimAnimations)
	p.stateconfig = config.getParameter("states")
	p.loungePositions = config.getParameter("loungePositions")
	p.animStateData = root.assetJson( p.directoryPath .. p.cfgAnimationFile ).animatedParts.stateTypes
	p.config = root.assetJson( "/pvso_general.config")
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

	for i = 0, p.occupantSlots do
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
		p.warpInEffect()
	end

	p.driver = config.getParameter( "driver" )
	if p.driver ~= nil then
		p.occupant[0].id = p.driver
		p.driverSeat = "occupant0"

		p.seats[p.driverSeat] = p.occupant[0]
		p.lounging[p.driver] = p.occupant[0]

		p.occupant[0].visible = false
		p.occupant[0].statList = p.vso.driverStatusEffects or {}

		p.driving = true
		p.spawner = p.driver
		p.forceSeat( p.driver, 0 )
		world.sendEntityMessage( p.driver, "giveVoreController")
	else
		p.seats.objectControls = p.clearOccupant(0)
		p.seats.objectControls.seatname = "objectControls"
		p.seats.objectControls.controls.powerMultiplier = p.objectPowerLevel()
		p.driverSeat = "objectControls"
		p.includeDriver = true
		p.driving = false
		p.isObject = true
	end

	p.vso.maxOccupants.total = 7
	if p.includeDriver then
		p.vso.maxOccupants.total = 8
	end

	p.seats[p.driverSeat].smolPreyData = config.getParameter("layer") or {}
	p.seats[p.driverSeat].species = p.seats[p.driverSeat].smolPreyData.species

	if p.spawner then
		p.spawnerUUID = world.entityUniqueId(p.spawner)
	end

	p.onForcedReset()	--Do a forced reset once.

	local startState = config.getParameter( "startState" ) or p.settings.startState or p.vso.startState or "stand"
	p.setState( startState )
	p.updateState(0)
	p.resolvePosition(5)

	for _, script in ipairs(p.config.scripts) do
		require(script)
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

	p.emoteCooldown =  math.max( 0, p.emoteCooldown - dt )
	p.settingsMenuOpen = math.max( 0, p.settingsMenuOpen - dt )
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

function p.resolvePosition(range)
	local resolvePosition = world.resolvePolyCollision(p.movementParams.collisionPoly, mcontroller.position(), range or 5)
	if resolvePosition ~= nil then
		mcontroller.setPosition(resolvePosition)
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
					p.driver, "openPVSOInterface", world.entityName( entity.id() ):gsub("^spov","").."Settings",
					{ vso = entity.id(), occupants = p.occupant, maxOccupants = p.vso.maxOccupants.total, powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier }, false, entity.id()
				)
			end
		elseif p.lounging[args.sourceId].location ~= nil and stateData.struggle ~= nil then
			local struggleData = stateData.struggle[p.lounging[args.sourceId].location]
			if struggleData and struggleData.directions and struggleData.directions.interact ~= nil and p.struggleChance(struggleData, p.lounging[args.sourceId].index, "interact") then
				p.doTransition( stateData.struggle[p.lounging[args.sourceId].location].directions.interact.transition, { id = args.sourceId } )
			end
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
		elseif stateData.interact ~= nil and stateData.interact.animation ~= nil then
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
	if p.spawner and world.entityExists(p.spawner) then
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
	for i = 0, p.occupantSlots do
		vehicle.setLoungeEnabled( "occupant"..i, false )
	end

	vehicle.setInteractive( true )

	p.emoteCooldown = 0

	onForcedReset()
end

function p.onDeath(eaten)
	if p.spawner then
		world.sendEntityMessage(p.spawner, "vsoDespawned", p.settings)
	end

	if not eaten then
		p.warpOutEffect()
		for i = 0, #p.occupant do
			p.uneat(p.occupant[i].id)
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

function p.showEmote( emotename ) --helper function to express a emotion particle "emotesleepy","emoteconfused","emotesad","emotehappy","love"
	if p.emoteCooldown < 0 then
		animator.setParticleEmitterBurstCount( emotename, 1 );
		animator.burstParticleEmitter( emotename )
		p.emoteCooldown = 0.2; -- seconds
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

function p.getSmolPreyData(settings, species, state, layer)
	return {
		species = species,
		recieved = true,
		update = true,
		layer = layer,
		settings = settings,
		state = state,
		images = p.smolPreyAnimationPaths(settings, species, state)
	}
end

function p.smolPreyAnimationPaths(settings, species, state)
	local directory = "/vehicles/spov/"..species.."/"
	local animatedParts = root.assetJson( "/vehicles/spov/"..species.."/"..species..".animation" ).animatedParts
	local edibleAnims = root.assetJson( "/vehicles/spov/"..species.."/"..species..".vehicle" ).states[state].edibleAnims

	local head
	local head_fullbright

	local body
	local body_fullbright

	local tail
	local tail_fullbright

	local backlegs
	local backlegs_fullbright

	local frontlegs
	local frontlegs_fullbright

	local backarms
	local backarms_fullbright

	local frontarms
	local frontarms_fullbright

	if edibleAnims.head ~= nil then
		local skin = (settings.skinNames or {}).head or "default"
		head = p.fixSmolPreyPathTags( directory, animatedParts.parts.head.partStates.headState[edibleAnims.head].properties.image, skin, settings)
		if animatedParts.parts.head_fullbright ~= nil then
			head_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.head_fullbright.partStates.headState[edibleAnims.head].properties.image, skin, settings)
		end
	end
	if edibleAnims.body ~= nil then
		local skin = (settings.skinNames or {}).body or "default"
		body = p.fixSmolPreyPathTags( directory, animatedParts.parts.body.partStates.bodyState[edibleAnims.body].properties.image, skin, settings)
		if animatedParts.parts.body_fullbright ~= nil then
			body_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.body_fullbright.partStates.bodyState[edibleAnims.body].properties.image, skin, settings)
		end
	end
	if edibleAnims.tail ~= nil then
		local skin = (settings.skinNames or {}).tail or "default"
		tail = p.fixSmolPreyPathTags( directory, animatedParts.parts.tail.partStates.tailState[edibleAnims.tail].properties.image, skin, settings)
		if animatedParts.parts.tail_fullbright ~= nil then
			tail_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.tail_fullbright.partStates.tailState[edibleAnims.tail].properties.image, skin, settings)
		end
	end
	if edibleAnims.legs ~= nil then
		local skin = (settings.skinNames or {}).legs or "default"
		backlegs = p.fixSmolPreyPathTags( directory, animatedParts.parts.backlegs.partStates.legsState[edibleAnims.legs].properties.image, skin, settings)
		frontlegs = p.fixSmolPreyPathTags( directory, animatedParts.parts.frontlegs.partStates.legsState[edibleAnims.legs].properties.image, skin, settings)
		if animatedParts.parts.backlegs_fullbright ~= nil then
			backlegs_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.backlegs_fullbright.partStates.legsState[edibleAnims.legs].properties.image, skin, settings)
		end
		if animatedParts.parts.frontlegs_fullbright ~= nil then
			frontlegs_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.frontlegs_fullbright.partStates.legsState[edibleAnims.legs].properties.image, skin, settings)
		end
	end
	if edibleAnims.arms ~= nil then
		local skin = (settings.skinNames or {}).arms or "default"
		backarms = p.fixSmolPreyPathTags( directory, animatedParts.parts.backarms.partStates.armsState[edibleAnims.arms].properties.image, skin, settings)
		frontarms = p.fixSmolPreyPathTags( directory, animatedParts.parts.frontarms.partStates.armsState[edibleAnims.arms].properties.image, skin, settings)
		if animatedParts.parts.backarms_fullbright ~= nil then
			backarms_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.backarms_fullbright.partStates.armsState[edibleAnims.arms].properties.image, skin, settings)
		end
		if animatedParts.parts.frontarms_fullbright ~= nil then
			frontarms_fullbright = p.fixSmolPreyPathTags( directory, animatedParts.parts.frontarms_fullbright.partStates.armsState[edibleAnims.arms].properties.image, skin, settings)
		end
	end

	return {
		head = head,
		head_fullbright = head_fullbright,

		body = body,
		body_fullbright = body_fullbright,

		tail = tail,
		tail_fullbright = tail_fullbright,

		backlegs = backlegs,
		backlegs_fullbright = backlegs_fullbright,

		frontlegs = frontlegs,
		frontlegs_fullbright = frontlegs_fullbright,

		backarms = backarms,
		backarms_fullbright = backarms_fullbright,

		frontarms = frontarms,
		frontarms_fullbright = frontarms_fullbright
	}
end

function p.fixSmolPreyPathTags(directory, path, skin, settings)
	return directory..sb.replaceTags(path, {
		skin = skin,
		fullbrightDirectives = settings.fullbrightDirectives or "",
		directives = settings.directives or "",
		bap = "",
		frame = "1",
		bellyoccupants = "0",
		cracks = tostring(settings.cracks) or "0"
	})
end


function p.transformPrey(i)
	local smolPreyData
	if p.occupant[i].progressBarData ~= nil then
		smolPreyData = p.occupant[i].progressBarData
	end
	if smolPreyData ~= nil then
		if smolPreyData.layer == true then
			smolPreyData.layer = p.occupant[i].smolPreyData
		end
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
	else
		local species = world.entityName( entity.id() ):gsub("^spov","")
		if world.entityType(p.occupant[i].id) == "player" then
			p.addRPC(world.sendEntityMessage(p.occupant[i].id, "loadVSOsettings", species), function(settings)
				p.occupant[i].smolPreyData = p.getSmolPreyData(settings, species, "smol")
				p.occupant[i].species = species
			end)
		else
			p.occupant[i].smolPreyData = p.getSmolPreyData(p.settings, species, "smol")
			p.occupant[i].species = species
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
	return p.config.inedibleCreatures[world.entityType(occupantId)]
end

-------------------------------------------------------------------------------

function p.getOccupantFromEid(eid)
	if p.lounging[eid] ~= nil then
		return p.lounging[eid].index
	end
end

function p.getSeatnameFromEid(eid)
	if p.lounging[eid] ~= nil then
		return p.lounging[eid].seatname
	end
end

function p.getLocationFromEid(eid)
	if p.lounging[eid] ~= nil then
		return p.lounging[eid].location
	end
end

function p.getIndexFromEid(eid)
	if p.lounging[eid] ~= nil then
		return p.lounging[eid].index
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

function p.randomChance(percent)
	return math.random() <= (percent/100)
end
