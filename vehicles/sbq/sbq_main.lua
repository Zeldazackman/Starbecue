--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

state = {}

sbq = {
	occupants = {
		maximum = 0,
		total = 0
	},
	occupant = {},
	occupantSlots = 7, -- 0 indexed
	justAte = false,
	justLetout = false,
	nextIdle = 0,
	swapCooldown = 0,
	isPathfinding = false,
	hunger = 100,
	emoteCooldown = 0
}

sbq.settings = {}

sbq.partTags = {}

sbq.movement = {
	jumps = 0,
	jumped = false,
	sinceLastJump = 0,
	jumpProfile = "airJumpProfile",
	airtime = 0,
	groundMovement = "run",
	aimingLock = 0
}

sbq.seats = {} -- meant to be a redirect pointers to the occupant data
sbq.lounging = {}

function sbq.clearOccupant(i)
	return {
		seatname = "occupant"..i,
		index = i,
		id = nil,
		statList = sbq.sbqData.occupantStatusEffects or {},
		visible = true,
		emote = "idle",
		dance = "idle",
		location = nil,
		species = nil,
		smolPreyData = {},
		nestedPreyData = {},
		struggleTime = 0,
		bellySettleDownTimer = 0,
		occupantTime = 0,
		progressBar = 0,
		progressBarActive = false,
		progressBarData = nil,
		progressBarMultiplier = 1,
		progressBarFinishFunc = nil,
		progressBarColor = nil,
		victimAnim = { enabled = false, last = { x = 0, y = 0, xs = 1, ys = 1, r = 0 } },
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

require("/vehicles/sbq/sbq_animation.lua")
require("/vehicles/sbq/sbq_state_control.lua")
require("/vehicles/sbq/sbq_control_handling.lua")
require("/vehicles/sbq/sbq_driving.lua")
require("/vehicles/sbq/sbq_pathfinding.lua")
require("/vehicles/sbq/sbq_replaceable_functions.lua")
require("/vehicles/sbq/sbq_occupant_handling.lua")
require("/scripts/SBQ_RPC_handling.lua")

function init()
	sbq.sbqData = config.getParameter("sbqData")
	sbq.cfgAnimationFile = config.getParameter("animation")
	sbq.victimAnimations = root.assetJson(sbq.sbqData.victimAnimations)
	sbq.stateconfig = config.getParameter("states")
	sbq.loungePositions = config.getParameter("loungePositions")
	sbq.animStateData = root.assetJson( sbq.cfgAnimationFile ).animatedParts.stateTypes
	sbq.config = root.assetJson( "/sbqGeneral.config")
	sbq.transformGroups = root.assetJson( sbq.cfgAnimationFile ).transformationGroups

	sbq.settings = sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.sbqData.defaultSettings or {}), config.getParameter( "settings" ) or {})

	sbq.spawner = config.getParameter("spawner")
	sbq.settings.directives = sbq.sbqData.defaultDirectives or ""

	if mcontroller_extensions then
		for k,v in pairs(mcontroller_extensions) do
			mcontroller[k] = v
		end
	end

	for transformGroup, _ in pairs(sbq.transformGroups) do
		sbq.resetTransformationGroup(transformGroup)
	end

	sbq.partTags.global = root.assetJson( sbq.cfgAnimationFile ).globalTagDefaults

	for part, _ in pairs(root.assetJson( sbq.cfgAnimationFile ).animatedParts.parts ) do
		sbq.partTags[part] = {}
	end

	sbq.setColorReplaceDirectives()
	sbq.setSkinPartTags()

	--[[
	so, the thing is, we want this to move like an actor, even if it is a vehicle, so we have to have a little funny business,
	both mcontrollers use the same arguments for the most part, just the actor mcontroller has more values, as well as some
	different function names, however the json for the data is what is the most important and thats the same for what is shared,
	therefore, if we try and set the params to the default actor ones, and then merge the humanoid ones on top
	that could help with the illusion yes?
	]]
	sbq.movementParams = sb.jsonMerge(sb.jsonMerge(root.assetJson("/default_actor_movement.config"), root.assetJson("/humanoid.config:movementParameters")), root.assetJson("/player.config:movementParameters"))
	sbq.movementParams.jumpCount = 1

	mcontroller.applyParameters(sbq.movementParams)

	sbq.movementParamsName = "default"
	sbq.faceDirection(config.getParameter("direction", 1)) -- the hitbox and default movement params are set here

	sbq.resetOccupantCount()

	for i = 0, sbq.occupantSlots do
		sbq.occupant[i] = sbq.clearOccupant(i)
		sbq.seats["occupant"..i] = sbq.occupant[i]
	end

	sbq.animFunctionQueue = {}
	for statename, state in pairs(sbq.animStateData) do
		state.animationState = {
			anim = state.default,
			priority = state.states[state.default].priority,
			cycle = state.states[state.default].cycle,
			frames = state.states[state.default].frames,
			mode = state.states[state.default].mode,
			speed = state.states[state.default].frames / state.states[state.default].cycle,
			frame = 1,
			time = 0,
			queue = {},
		}
		state.tag = nil
		sbq.animFunctionQueue[statename] = {}
		sbq.setPartTag("global", statename.."Frame", 1)
		sbq.setPartTag("global", statename.."Anim", state.default)
	end

	sbq.driver = config.getParameter( "driver" )
	if sbq.driver ~= nil then
		sbq.occupant[0].id = sbq.driver
		sbq.driverSeat = "occupant0"

		sbq.seats[sbq.driverSeat] = sbq.occupant[0]
		sbq.lounging[sbq.driver] = sbq.occupant[0]

		sbq.occupant[0].visible = false
		sbq.occupant[0].statList = sbq.sbqData.driverStatusEffects or {}

		sbq.driving = true
		sbq.spawner = sbq.driver
		sbq.forceSeat( sbq.driver, 0 )
		world.sendEntityMessage( sbq.driver, "sbqGiveController")
	else
		sbq.seats.objectControls = sbq.clearOccupant(0)
		sbq.seats.objectControls.seatname = "objectControls"
		sbq.seats.objectControls.controls.powerMultiplier = sbq.objectPowerLevel()
		sbq.driverSeat = "objectControls"
		sbq.includeDriver = true
		sbq.driving = false
		sbq.isObject = true
	end

	if not config.getParameter( "uneaten" ) then
		sbq.warpInEffect()
	end

	sbq.occupants.maximum = 7
	if sbq.includeDriver then
		sbq.occupants.maximum = 8
	end

	sbq.seats[sbq.driverSeat].smolPreyData = config.getParameter("layer") or {}
	sbq.seats[sbq.driverSeat].species = sbq.seats[sbq.driverSeat].smolPreyData.species

	if sbq.spawner then
		sbq.spawnerUUID = world.entityUniqueId(sbq.spawner)
	end

	local startState = config.getParameter( "startState" ) or sbq.settings.startState or sbq.sbqData.startState or "stand"
	sbq.setState( startState )
	sbq.updateState(0)
	sbq.resolvePosition(5)

	for _, script in ipairs(sbq.config.scripts) do
		require(script)
	end
	sbq.init()
end

sbq.totalTimeAlive = 0
function update(dt)
	sbq.checkSpawnerExists()
	sbq.totalTimeAlive = sbq.totalTimeAlive + dt
	sbq.dt = dt
	sbq.updateAnims(dt)
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)
	sbq.idleStateChange(dt)

	sbq.updateControls(dt)
	sbq.updatePathfinding(dt)
	sbq.updateDriving(dt)

	sbq.updateOccupants(dt)
	sbq.handleStruggles(dt)
	sbq.doBellyEffects(dt)
	sbq.applyStatusLists()

	sbq.update(dt)
	sbq.updateState(dt)
	sbq.applyTransformations()
end

function uninit()
	if mcontroller.atWorldLimit()
	--or (world.entityHealth(entity.id()) <= 0) -- vehicles don't have health?
	then
		sbq.onDeath()
	end
end

function sbq.resolvePosition(range)
	local resolvePosition = world.resolvePolyCollision(sbq.movementParams.collisionPoly, mcontroller.position(), range or 5)
	if resolvePosition ~= nil then
		mcontroller.setPosition(resolvePosition)
	end
end

function sbq.eatFeedableHandItems(entity)
	if sbq.eatHandItem(entity, "primary") then return true end
	if sbq.eatHandItem(entity, "alt") then return true end
end

function sbq.eatHandItem(entity, hand)
	if sbq.settings.lockSettings and world.entityUniqueId(entity) ~= sbq.settings.ownerId then return false end
	local item = world.entityHandItemDescriptor(entity, hand)
	if item ~= nil then
		local config = root.itemConfig(item).config
		item.count = 1
		if config.sbqModifier ~= nil then
			local modifier = config.sbqModifier
			local allowed = sbq.sbqData.allowedModifiers
			local default = sbq.sbqData.defaultSettings

			if allowed then
				local changed = false
				for k,v in pairs(modifier) do
					if not allowed[k] then
						sb.logInfo("can't apply: not allowed")
						return nil
					end
					if allowed[k].min and allowed[k].min > v then
						sb.logInfo("can't apply: "..k.." too low ("..v.." smaller than minimum "..allowed[k]..")")
						return nil
					end
					if allowed[k].max and allowed[k].max < v then
						sb.logInfo("can't apply: "..k.." too high ("..v.." larger than maximum "..allowed[k]..")")
						return nil
					end
					if not allowed[k].min and not allowed[k].max and allowed[k] ~= "bool" then
						if not allowed[k][v] then
							sb.logInfo("can't apply: "..k.." not valid (got \""..v.."\", allowed "..sb.printJson(allowed[k])..")")
							return nil
						end
					end
					if (sbq.settings[k] or default[k]) ~= v then
						sbq.settings[k] = v
						changed = true
					end
				end
				if changed then
					world.sendEntityMessage(entity, "sbqEatItem", item, true, true)
					world.sendEntityMessage(sbq.spawner, "sbqSaveSettings", sbq.settings)
					return true
				end
			end
		elseif config.foodValue ~= nil then
			if sbq.hunger < 100 then
				sbq.hunger = math.min(100, sbq.hunger + config.foodValue)
				world.sendEntityMessage(entity, "sbqEatItem", item, true, false)
				return true
			end
		end
	end
end

sbq.predHudOpen = 0
-- returns sourcePosition, sourceId, and interactPosition
function onInteraction(args)
	if sbq.transitionLock then return end
	local stateData = sbq.stateconfig[sbq.state]

	if not sbq.driver then
		if sbq.eatFeedableHandItems(args.sourceId) then sbq.showEmote( "emotehappy" ) return end
	end

	if sbq.entityLounging(args.sourceId) then
		if args.sourceId == sbq.driver then

		elseif sbq.lounging[args.sourceId].location ~= nil and stateData.struggle ~= nil then
			local struggleData = stateData.struggle[sbq.lounging[args.sourceId].location]
			if struggleData and struggleData.directions and struggleData.directions.interact ~= nil and sbq.struggleChance(struggleData, sbq.lounging[args.sourceId].index, "interact") then
				sbq.doTransition( stateData.struggle[sbq.lounging[args.sourceId].location].directions.interact.transition, { id = args.sourceId } )
			end
		end
		return
	elseif sbq.notMoving() then
		sbq.showEmote( "emotehappy" )
		if stateData.interact ~= nil then
			-- find closest interaction point, 4d voronoi style
			local pos = sbq.globalToLocal(args.sourcePosition)
			local aim = sbq.globalToLocal(args.interactPosition)
			local closest = nil
			local distance = math.huge
			for _,v in pairs(stateData.interact) do
				local p = v.pos
				local a = v.aim
				if not p and not a then
					-- no pos or aim, just make this one happen
					p = pos
					a = aim
				elseif a and not p then
					-- pos isn't specified, default to same as aim but less weight
					p = {
						(a[1] + pos[1])/2,
						(a[2] + pos[2])/2
					}
				elseif p and not a then
					-- aim isn't specified, default to same as pos but less weight
					a = {
						(p[1] + aim[1])/2,
						(p[2] + aim[2])/2
					}
				end
				local d = math.sqrt(
					(pos[1] - p[1])^2 +
					(pos[2] - p[2])^2 +
					(aim[1] - a[1])^2 +
					(aim[2] - a[2])^2
				)
				if d < distance then
					distance = d
					closest = v
				end
			end
			return sbq.interactChance(closest, args)
		end
		if state[sbq.state].interact ~= nil then
			if state[sbq.state].interact() then
				return
			end
		end
	end
end

function sbq.interactChance(data, args)
	if not (data.drivingEnabled or (not sbq.driver)) then return end
	if data.chance then
		if math.random() <= (data.chance/100) then
			sbq.doTransition( (sbq.occupantArray(data) or {}).transition, {id=args.sourceId} )
		elseif data.animation then
			sbq.doAnims(data.animation)
		end
	else
		sbq.doTransition( (sbq.occupantArray(data) or {}).transition, {id=args.sourceId} )
	end
end


function sbq.logJson(arg)
	sb.logInfo(sb.printJson(arg, 1))
end

function sbq.sameSign(num1, num2)
	if num1 < 0 and num2 < 0 then
		return true
	elseif num1 > 0 and num2 > 0 then
		return true
	else
		return false
	end
end

sbq.dtSinceList = {}
function sbq.dtSince(name, overwrite) -- used for when something isn't in the main update loop but knowing the dt since it was last called is good
	local last = sbq.dtSinceList[name] or 0
	if overwrite then
		sbq.dtSinceList[name] = sbq.totalTimeAlive
	end
	return sbq.totalTimeAlive - last
end

function sbq.facePoint(x)
	sbq.faceDirection(x - mcontroller.position()[1])
end

function sbq.faceDirection(x)
	if x > 0 then
		sbq.direction = 1
		animator.setFlipped(false)
	elseif x < 0 then
		sbq.direction = -1
		animator.setFlipped(true)
	end
	sbq.setMovementParams(sbq.movementParamsName)
end

function sbq.setMovementParams(name)
	if sbq.movementParamsName ~= name then
		sbq.activeControls.parameters = {}
	end
	sbq.movementParamsName = name
	local params = config.getParameter("sbqData").movementSettings[name]
	if params.flip then
		for _, coords in ipairs(params.collisionPoly) do
			coords[1] = coords[1] * sbq.direction
		end
	end
	sbq.movementParams = sb.jsonMerge(sb.jsonMerge(sbq.movementParams, params), sbq.activeControls.parameters)
	mcontroller.applyParameters(params)
end

function sbq.checkSpawnerExists()
	if sbq.spawner ~= nil and world.entityExists(sbq.spawner) then
	elseif (sbq.spawnerUUID ~= nil) then
		--[[sbq.loopedMessage("preyWarpDespawn", sbq.spawnerUUID, "sbqPreyWarpRequest", {}, -- this is now how any of that works, you have to be in the same world for a message
		function(data)
			-- put function handling the data return for the preywarp request here to make the player prey warp to the pred's location and set themselves as prey again

			sbq.spawnerUUID = nil
		end,
		function()
			-- this function is for when the request fails, leave it unchanged
			sbq.spawnerUUID = nil
		end)]]
		sbq.spawnerUUID = nil
	else
		sbq.onDeath()
	end
end


function sbq.onDeath(eaten)
	if sbq.spawner ~= nil then
		world.sendEntityMessage(sbq.spawner, "sbqPredatorDespawned", sbq.settings)
	end

	if not eaten then
		sbq.warpOutEffect()
		for i = 0, #sbq.occupant do
			sbq.uneat(sbq.occupant[i].id)
		end
	end

	sbq.uninit()
	vehicle.destroy()
end

function sbq.localToGlobal( position )
	local lpos = { position[1], position[2] }
	if sbq.direction == -1 then lpos[1] = -lpos[1] end
	local mpos = mcontroller.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end
function sbq.globalToLocal( position )
	local pos = world.distance( position, mcontroller.position() )
	if sbq.direction == -1 then pos[1] = -pos[1] end
	return pos
end

function sbq.occupantArray( maybearray )
	if maybearray == nil or maybearray[1] == nil then -- not an array, check for eating
		if maybearray.location then
			if maybearray.failOnFull then
				if (maybearray.failOnFull ~= true) and (sbq.occupants[maybearray.location] >= maybearray.failOnFull) then return maybearray.failTransition
				elseif sbq.locationFull(maybearray.location) then return maybearray.failTransition end
			else
				if sbq.locationEmpty(maybearray.location) then return maybearray.failTransition end
			end
		end
		return maybearray
	else -- pick one depending on number of occupants
		return maybearray[(sbq.occupants[maybearray[1].location or "total"] or 0) + 1]
	end
end

function sbq.getSmolPreyData(settings, species, state, tags, layer)
	return {
		species = species,
		recieved = true,
		update = true,
		layer = layer,
		settings = settings,
		state = state,
		images = sbq.smolPreyAnimationPaths(settings, species, state, tags)
	}
end

function sbq.smolPreyAnimationPaths(settings, species, state, tags)
	local directory = "/vehicles/sbq/"..species.."/"
	local animatedParts = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".animation" ).animatedParts
	local vehicle = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".vehicle" )
	local edibleAnims = vehicle.states[state].edibleAnims
	local tags = tags
	if tags == nil then
		tags = { global = root.assetJson( "/vehicles/sbq/"..species.."/"..species..".animation" ).globalTagDefaults }
	end

	settings.directives = sbq.smolpreyGetColorReplaceDirectives(vehicle.sbqData, settings)

	local returnValues  = {}

	if edibleAnims.head ~= nil then
		returnValues.head = sbq.fixSmolPreyPathTags(directory, animatedParts, "head", "head", edibleAnims.head, settings, tags)
	end
	if edibleAnims.head1 ~= nil then
		returnValues.head1 = sbq.fixSmolPreyPathTags(directory, animatedParts, "head1", "head", edibleAnims.head1, settings, tags)
	end
	if edibleAnims.head2 ~= nil then
		returnValues.head2 = sbq.fixSmolPreyPathTags(directory, animatedParts, "head2", "head", edibleAnims.head2, settings, tags)
	end
	if edibleAnims.head3 ~= nil then
		returnValues.head3 = sbq.fixSmolPreyPathTags(directory, animatedParts, "head3", "head", edibleAnims.head3, settings, tags)
	end
	if edibleAnims.body ~= nil then
		returnValues.body = sbq.fixSmolPreyPathTags(directory, animatedParts, "body", "body", edibleAnims.body, settings, tags)
	end
	if edibleAnims.belly ~= nil then
		returnValues.belly = sbq.fixSmolPreyPathTags(directory, animatedParts, "belly", "belly", edibleAnims.belly, settings, tags)
	end
	if edibleAnims.tail ~= nil then
		returnValues.tail = sbq.fixSmolPreyPathTags(directory, animatedParts, "tail", "tail", edibleAnims.tail, settings, tags)
	end
	if edibleAnims.cock ~= nil then
		returnValues.cock = sbq.fixSmolPreyPathTags(directory, animatedParts, "cock", "cock", edibleAnims.cock, settings, tags)
	end
	if edibleAnims.legs ~= nil then
		returnValues.backlegs = sbq.fixSmolPreyPathTags(directory, animatedParts, "backlegs", "legs", edibleAnims.legs, settings, tags)
		returnValues.frontlegs = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontlegs", "legs", edibleAnims.legs, settings, tags)
	end
	if edibleAnims.arms ~= nil then
		returnValues.backarms = sbq.fixSmolPreyPathTags(directory, animatedParts, "backarms", "arms", edibleAnims.arms, settings, tags)
		returnValues.frontarms = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontarms", "arms", edibleAnims.arms, settings, tags)
	end
	if edibleAnims.balls ~= nil then
		returnValues.backBalls = sbq.fixSmolPreyPathTags(directory, animatedParts, "backBalls", "backBalls", edibleAnims.balls, settings, tags)
		returnValues.frontBalls = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontBalls", "frontBalls", edibleAnims.balls, settings, tags)
	end
	if edibleAnims.breasts ~= nil then
		returnValues.backBreasts = sbq.fixSmolPreyPathTags(directory, animatedParts, "backBreasts", "backBreasts", edibleAnims.breasts, settings, tags)
		returnValues.frontBreasts = sbq.fixSmolPreyPathTags(directory, animatedParts, "frontBreasts", "frontBreasts", edibleAnims.breasts, settings, tags)
	end
	return returnValues
end

function sbq.fixSmolPreyPathTags(directory, animatedParts, partname, statename, animname, settings, tags)
	local path = (
		((((animatedParts.parts[partname].partStates[statename.."State"] or {})[animname] or {}).properties or {}).image)
		or ((((animatedParts.parts[partname].partStates[statename.."State"] or {})[((animatedParts.stateTypes[statename.."State"] or {}).states[animname] or {}).baseAnim or ""] or {}).properties or {}).image)
	)
	local framesName = animname
	if ((animatedParts.stateTypes[statename.."State"] or {}).states[animname] or {}).animFrames ~= nil then
		framesName = ((animatedParts.stateTypes[statename.."State"] or {}).states[animname] or {}).animFrames
	end

	if not path or path == "" then return end
	local partTags = sb.jsonMerge( tags.global, sb.jsonMerge( tags[partname], {
		directives = settings.directives,
		skin = (settings.skinNames or {})[partname] or "default",
		[statename.."StateFrame"] = "1",
		[statename.."StateAnim"] = framesName
	}))
	return directory..sb.replaceTags(path, partTags)
end

function sbq.GetColorReplaceDirectives(predatorConfig, predatorSettings)
	if predatorConfig.replaceColors ~= nil then
		local colorReplaceString = ""
		for i, colorGroup in ipairs(predatorConfig.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[((predatorSettings.replaceColors or {})[i] or (predatorConfig.defaultSettings.replaceColors or {})[i] or 1) + 1]
			local fullbright = (predatorSettings.fullbright or {})[i]

			if predatorSettings.replaceColorTable and predatorSettings.replaceColorTable[i] then
				replacePalette = predatorSettings.replaceColorTable[i]
				if type(replacePalette) == "string" then
					return replacePalette
				end
			end

			for j, color in ipairs(replacePalette) do
				if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
					color = color.."fb"
				end
				colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")
			end
		end
		return colorReplaceString
	end
end


function sbq.transformPrey(i)
	local smolPreyData
	if sbq.occupant[i].progressBarData ~= nil then
		smolPreyData = sbq.occupant[i].progressBarData
	end
	if smolPreyData ~= nil then
		if smolPreyData.layer == true then
			smolPreyData.layer = sbq.occupant[i].smolPreyData
			for j = 0, sbq.occupantSlots do
				if sbq.occupant[j].location == "nested" and sbq.occupant[j].nestedPreyData.owner == sbq.occupant[i].id then
					local nestedPreyData = sbq.occupant[j].nestedPreyData
					sbq.occupant[j].nestedPreyData.nestedPreyData = nestedPreyData
					sbq.occupant[j].nestedPreyData.location = smolPreyData.layerLocation
				end
			end
		end
		if world.entityType(sbq.occupant[i].id) == "player" and not smolPreyData.forceSettings then
			sbq.addRPC(world.sendEntityMessage(sbq.occupant[i].id, "sbqLoadSettings", smolPreyData.species), function(settings)
				smolPreyData.settings = settings
				sbq.occupant[i].smolPreyData = smolPreyData
				sbq.occupant[i].species = smolPreyData.species
			end)
		else
			sbq.occupant[i].smolPreyData = smolPreyData
			sbq.occupant[i].species = smolPreyData.species
		end
	else
		local species = world.entityName( entity.id() )
		local tags = {}
		local animationFile = root.assetJson("/vehicles/sbq/"..species.."/"..species..".vehicle").animation
		tags.global = root.assetJson( animationFile ).globalTagDefaults
		for part, _ in pairs(root.assetJson( animationFile ).animatedParts.parts ) do
			tags[part] = {}
		end

		if world.entityType(sbq.occupant[i].id) == "player" then
			sbq.addRPC(world.sendEntityMessage(sbq.occupant[i].id, "sbqLoadSettings", species), function(settings)
				sbq.occupant[i].smolPreyData = sbq.getSmolPreyData(settings, species, "smol", tags)
				sbq.occupant[i].species = species
			end)
		else
			sbq.occupant[i].smolPreyData = sbq.getSmolPreyData(sbq.settings, species, "smol", tags)
			sbq.occupant[i].species = species
		end
	end
	sbq.refreshList = true
end

function sbq.isMonster( id )
	if id == nil then return false end
	if not world.entityExists(id) then return false end
	return world.entityType(id) == "monster"
end

-------------------------------------------------------------------------------

function sbq.notMoving()
	return (math.abs(mcontroller.xVelocity()) < 0.1) and mcontroller.onGround()
end

function sbq.underWater()
	return mcontroller.liquidPercentage() >= sbq.movementParams.minimumLiquidPercentage
end

function sbq.useEnergy(eid, cost, callback)
	sbq.addRPC( world.sendEntityMessage(eid, "sbqUseEnergy", cost), callback)
end

-------------------------------------------------------------------------------

function sbq.objectPowerLevel()
	local power = world.threatLevel()
	if type(power) ~= "number" or power < 1 then return 1 end
	return power
end

function sbq.randomChance(percent)
	return math.random() <= (percent/100)
end

function sbq.checkSettings(checkSettings)
	for setting, value in pairs(checkSettings) do
		if sbq.settings[setting] ~= value then
			return false
		end
	end
	return true
end
