state = {
	stand = {}
}

sbq = {
	occupants = {
		maximum = 8,
		total = 8,
		belly = 1,
		cock = 1
	},
	includeDriver = true,
	occupant = {},
	occupantSlots = 7, -- 0 indexed
	justAte = false,
	justLetout = false,
	nextIdle = 0,
	swapCooldown = 0,
	emoteCooldown = 0,
	isPathfinding = false,
	hunger = 100,
	state = "stand",
	direction = 1
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

sbq.movementParams = {
	mass = 0
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

require("/vehicles/sbq/sbq_control_handling.lua")
require("/vehicles/sbq/sbq_occupant_handling.lua")
require("/vehicles/sbq/sbq_state_control.lua")
require("/vehicles/sbq/sbq_animation.lua")
require("/vehicles/sbq/sbq_replaceable_functions.lua")
require("/scripts/SBQ_RPC_handling.lua")


require("/vehicles/sbq/sbqOccupantHolder/sbqOH_animation.lua")

local inited

function init()
	sbq.spawner = config.getParameter("spawner") or config.getParameter("driver")
	sbq.driver = sbq.spawner
	sbq.driving = world.entityType(sbq.spawner) == "player"
	sbq.includeDriver = true
end

function initAfterInit(data)
	sbq.sbqData = sb.jsonMerge(config.getParameter("sbqData"), data.sbqData)
	sbq.cfgAnimationFile = sbq.sbqData.animation
	sbq.victimAnimations = root.assetJson(sbq.sbqData.victimAnimations)
	sbq.stateconfig = sb.jsonMerge(config.getParameter("states"), data.states)
	sbq.loungePositions = config.getParameter("loungePositions")
	sbq.animStateData = root.assetJson( sbq.cfgAnimationFile ).animatedParts.stateTypes
	sbq.config = root.assetJson( "/sbqGeneral.config")
	sbq.transformGroups = {
		occupant0Position = {},
		occupant1Position = {},
		occupant2Position = {},
		occupant3Position = {},
		occupant4Position = {},
		occupant5Position = {},
		occupant6Position = {},
		occupant7Position = {},
	}

	sbq.settings = sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.sbqData.defaultSettings or {}), config.getParameter( "settings" ) or {})

	sbq.partTags.global = {}

	for part, _ in pairs(root.assetJson( sbq.cfgAnimationFile ).animatedParts.parts) do
		sbq.partTags[part] = {}
	end
	for part, _ in pairs(root.assetJson( "/vehicles/sbq/sbqOccupantHolder/sbqOccupantHolder.animation" ).animatedParts.parts) do
		sbq.partTags[part] = {}
	end

	for transformGroup, _ in pairs(sbq.transformGroups) do
		sbq.resetTransformationGroup(transformGroup)
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
			time = 0
		}
		sbq.animFunctionQueue[statename] = {}
		state.tag = nil
	end

	if sbq.spawner then
		sbq.spawnerUUID = world.entityUniqueId(sbq.spawner)
	end

	sbq.resetOccupantCount()

	for i = 0, sbq.occupantSlots do
		sbq.occupant[i] = sbq.clearOccupant(i)
		sbq.seats["occupant"..i] = sbq.occupant[i]
	end
	sbq.seats.occupantD = sbq.clearOccupant("D")
	sbq.seats.occupantD.id = sbq.spawner
	sbq.lounging[sbq.spawner] = sbq.seats.occupantD
	sbq.driverSeat = "occupantD"

	mcontroller.applyParameters({ collisionEnabled = false, frictionEnabled = false, gravityEnabled = false, ignorePlatformCollision = true})

	if sbq.sbqData.scripts ~= nil then
		for _, script in ipairs(sbq.sbqData.scripts) do
			require(script)
		end
	end
	for _, script in ipairs(sbq.config.scripts) do
		require(script)
	end

	local retrievePrey = config.getParameter("retrievePrey")
	if type(retrievePrey) == "number" and world.entityExists(retrievePrey) then
		world.sendEntityMessage(retrievePrey, "sbqSendAllPreyTo", entity.id())
	end
end

sbq.totalTimeAlive = 0
local sentDataMessage
function update(dt)
	if not sentDataMessage then
		sentDataMessage = true
		sbq.addRPC(world.sendEntityMessage(sbq.spawner, "sbqGetSpeciesVoreConfig"), function (data)
			initAfterInit(data)
			inited = true
		end, function ()
			sentDataMessage = false
		end)
	end

	sbq.checkSpawnerExists()
	sbq.totalTimeAlive = sbq.totalTimeAlive + dt
	sbq.dt = dt
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)

	if not inited then return end

	sbq.getAnimData()
	sbq.updateAnims(dt)

	sbq.updateControls(dt)
	sbq.getSeatData(sbq.seats.occupantD, "occupantD", sbq.driver)
	sbq.openPredHud(dt)

	sbq.updateOccupants(dt)
	sbq.handleStruggles(dt)
	sbq.doBellyEffects(dt)
	sbq.applyStatusLists()

	sbq.applyTransformations()
end

function uninit()
end

sbq.predHudOpen = 1

function sbq.openPredHud(dt)
	if not sbq.driving then return end
	sbq.predHudOpen = math.max( 0, sbq.predHudOpen - dt )
	if sbq.predHudOpen <= 0 then
		sbq.predHudOpen = 2
		world.sendEntityMessage( sbq.driver, "sbqOpenMetagui", "starbecue:predHud", entity.id())
	end
end

function sbq.checkSpawnerExists()
	if sbq.spawner and world.entityExists(sbq.spawner) then
		mcontroller.setPosition(world.entityPosition(sbq.spawner))

		sbq.loopedMessage( "occupantHolderExists", sbq.spawner, "sbqOccupantHolderExists", {
			entity.id(),
			{occupant = sbq.occupant, occupants = sbq.occupants},
			{
				species = world.entityName(entity.id()),
				type = "driver"
			}
		},
		function (seatdata)
			sbq.spawnerEquips = seatdata
		end)

	elseif (sbq.spawnerUUID ~= nil) then
		sbq.loopedMessage("preyWarpDespawn", sbq.spawnerUUID, "sbqPreyWarpRequest", {},
		function(data)
			-- put function handling the data return for the preywarp request here to make the player prey warp to the pred's location and set themselves as prey again

			sbq.spawnerUUID = nil
		end,
		function()
			-- this function is for when the request fails, leave it unchanged
			sbq.spawnerUUID = nil
		end)
	else
		sbq.onDeath()
	end
end

function sbq.onDeath(eaten)
	if sbq.spawner ~= nil then
		world.sendEntityMessage(sbq.spawner, "sbqPredatorDespawned", sbq.settings)
	end

	if not eaten then
		for i = 0, #sbq.occupant do
			sbq.uneat(sbq.occupant[i].id)
		end
		sbq.getAnimData()
	end

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
				if type(maybearray.failOnFull) == "number" and (sbq.occupants[maybearray.location] >= maybearray.failOnFull) then return maybearray.failTransition
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


-------------------------------------------------------------------------------------------------------

function sbq.getSmolPreyData(settings, species, state, tags, layer)
	return {
		species = species,
		recieved = true,
		layer = layer,
		settings = settings,
		state = state
	}
end

function sbq.entityLounging( entity )
	if entity == sbq.spawner then return true end

	for i = 0, sbq.occupantSlots do
		if entity == sbq.occupant[i].id then return true end
	end
	return false
end

function sbq.edible( occupantId, seatindex, source, emptyslots, locationslots )
	if sbq.driver ~= occupantId then return false end
	local total = sbq.occupants.total
	total = total + 1
	if total > emptyslots or (locationslots and total > locationslots and locationslots ~= -1) then return false end
	if sbq.stateconfig[sbq.state].edible then
		world.sendEntityMessage(source, "sbqSmolPreyData", seatindex,
			sbq.getSmolPreyData(
				sbq.settings,
				world.entityName( entity.id() ),
				sbq.state,
				sbq.partTags,
				sbq.seats[sbq.driverSeat].smolPreyData
			),
			entity.id()
		)

		local nextSlot = 1
		for i = 0, sbq.occupantSlots do
			if type(sbq.occupant[i].id) == "number" then
				local location = sbq.occupant[i].location
				local massMultiplier = 0

				if location == "nested" then
					location = sbq.occupant[i].nestedPreyData.ownerLocation
				end
				massMultiplier = sbq.sbqData.locations[location].mass or 0

				if sbq.occupant[i].location == "nested" then
					massMultiplier = massMultiplier * sbq.occupant[i].nestedPreyData.massMultiplier
				end

				local occupantData = sb.jsonMerge(sbq.occupant[i], {
					location = "nested",
					visible = false,
					nestedPreyData = {
						owner = sbq.driver,
						location = sbq.occupant[i].location,
						massMultiplier = massMultiplier,
						digest = sbq.sbqData.locations[location].digest,
						nestedPreyData = sbq.occupant[i].nestedPreyData
					}
				})
				world.sendEntityMessage( source, "addPrey", seatindex + nextSlot, occupantData)
				nextSlot = nextSlot+1
			end
		end
		return true
	end
end

-------------------------------------------------------------------------------------------------------

function state.stand.eat(args)
	return sbq.doVore(args, "belly", {}, "swallow")
end

function state.stand.escape(args)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function state.stand.analEscape(args)
	return sbq.doEscape(args, {}, {} )
end
