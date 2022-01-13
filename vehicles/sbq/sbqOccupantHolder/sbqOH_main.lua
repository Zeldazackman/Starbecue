state = {
	stand = {}
}

p = {
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

p.settings = {}

p.partTags = {}

p.movement = {
	jumps = 0,
	jumped = false,
	sinceLastJump = 0,
	jumpProfile = "airJumpProfile",
	airtime = 0,
	groundMovement = "run",
	aimingLock = 0
}

p.movementParams = {
	mass = 0
}

p.seats = {} -- meant to be a redirect pointers to the occupant data
p.lounging = {}

function p.clearOccupant(i)
	return {
		seatname = "occupant"..i,
		index = i,
		id = nil,
		statList = p.sbqData.occupantStatusEffects or {},
		visible = false,
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

require("/vehicles/sbq/sbqOccupantHolder/sbqOH_animation.lua")

function init()
	p.sbqData = config.getParameter("sbqData")
	p.directoryPath = config.getParameter("directoryPath")
	p.cfgAnimationFile = p.sbqData.animation
	p.victimAnimations = root.assetJson(p.sbqData.victimAnimations)
	p.stateconfig = config.getParameter("states")
	p.loungePositions = config.getParameter("loungePositions")
	p.animStateData = root.assetJson( p.cfgAnimationFile ).animatedParts.stateTypes
	p.config = root.assetJson( "/sbqGeneral.config")
	p.transformGroups = {
		occupant0Position = {},
		occupant1Position = {},
		occupant2Position = {},
		occupant3Position = {},
		occupant4Position = {},
		occupant5Position = {},
		occupant6Position = {},
		occupant7Position = {},
	}

	p.settings = sb.jsonMerge(sb.jsonMerge(p.config.defaultSettings, p.sbqData.defaultSettings or {}), config.getParameter( "settings" ) or {})

	p.spawner = config.getParameter("spawner") or config.getParameter("driver")

	p.partTags.global = root.assetJson( p.cfgAnimationFile ).globalTagDefaults

	for part, _ in pairs(root.assetJson( p.cfgAnimationFile ).animatedParts.parts) do
		p.partTags[part] = {}
	end

	for transformGroup, _ in pairs(p.transformGroups) do
		p.resetTransformationGroup(transformGroup)
	end

	if config.getParameter("uneaten") then
		p.timer("uneaten", 0.1, function ()
			world.sendEntityMessage(p.spawner, "sbqNewOccupantHolder", entity.id())
		end)
	end

	p.animFunctionQueue = {}
	for statename, state in pairs(p.animStateData) do
		state.animationState = {
			anim = state.default,
			priority = state.states[state.default].priority,
			cycle = state.states[state.default].cycle,
			frames = state.states[state.default].frames,
			time = 0
		}
		p.animFunctionQueue[statename] = {}
		state.tag = nil
	end

	if p.spawner then
		p.spawnerUUID = world.entityUniqueId(p.spawner)
	end

	p.resetOccupantCount()

	for i = 0, p.occupantSlots do
		p.occupant[i] = p.clearOccupant(i)
		p.seats["occupant"..i] = p.occupant[i]
	end
	p.seats["occupantS"] = p.clearOccupant("S")
	p.driverSeat = "occupantS"

	mcontroller.applyParameters({ collisionEnabled = false, frictionEnabled = false, gravityEnabled = false, ignorePlatformCollision = true})

	if p.sbqData.scripts ~= nil then
		for _, script in ipairs(p.sbqData.scripts) do
			require(script)
		end
	end
	for _, script in ipairs(p.config.scripts) do
		require(script)
	end
end

p.totalTimeAlive = 0
function update(dt)
	p.checkSpawnerExists()
	p.totalTimeAlive = p.totalTimeAlive + dt
	p.dt = dt
	p.checkRPCsFinished(dt)
	p.checkTimers(dt)

	p.getAnimData()
	p.updateAnims(dt)

	p.updateControls(dt)

	p.updateOccupants(dt)
	p.handleStruggles(dt)
	p.doBellyEffects(dt)
	p.applyStatusLists()

	p.applyTransformations()
end

function uninit()
end

function p.checkSpawnerExists()
	if p.spawner and world.entityExists(p.spawner) then
		mcontroller.setPosition(world.entityPosition(p.spawner))

	elseif (p.spawnerUUID ~= nil) then
		p.loopedMessage("preyWarpDespawn", p.spawnerUUID, "sbqPreyWarpRequest", {},
		function(data)
			-- put function handling the data return for the preywarp request here to make the player prey warp to the pred's location and set themselves as prey again

			p.spawnerUUID = nil
		end,
		function()
			-- this function is for when the request fails, leave it unchanged
			p.spawnerUUID = nil
		end)
	else
		p.onDeath()
	end
end

function p.onDeath(eaten)
	if p.spawner then
		world.sendEntityMessage(p.spawner, "sbqOccupantHolderDespawn", p.settings)
	end
	for i = 0, #p.occupant do
		p.uneat(p.occupant[i].id)
	end

	vehicle.destroy()
end

p.rpcList = {}
function p.addRPC(rpc, callback, failCallback)
	if callback ~= nil or failCallback ~= nil  then
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


-------------------------------------------------------------------------------------------------------

function p.getSmolPreyData(settings, species, state, tags, layer)
	return {
		species = species,
		recieved = true,
		layer = layer,
		settings = settings,
		state = state
	}
end

function p.edible( occupantId, seatindex, source, emptyslots, locationslots )
	if p.spawner ~= occupantId then return false end
	local total = p.occupants.total
	total = total + 1

	if total > emptyslots or (total > locationslots and locationslots ~= -1) then return false end
	if p.stateconfig[p.state].edible then
		world.sendEntityMessage(source, "sbqSmolPreyData", seatindex,
			p.getSmolPreyData(
				p.settings,
				world.entityName( entity.id() ),
				p.state,
				p.partTags,
				p.seats[p.driverSeat].smolPreyData
			),
			entity.id()
		)

		local nextSlot = 1
		for i = 1, p.occupantSlots do
			if p.occupant[i].id ~= nil then
				local location = p.occupant[i].location
				local massMultiplier = 0

				if location == "nested" then
					location = p.occupant[i].nestedPreyData.ownerLocation
				end
				massMultiplier = p.sbqData.locations[location].mass or 0

				if p.occupant[i].location == "nested" then
					massMultiplier = massMultiplier * p.occupant[i].nestedPreyData.massMultiplier
				end

				local occupantData = sb.jsonMerge(p.occupant[i], {
					location = "nested",
					visible = false,
					nestedPreyData = {
						owner = p.driver,
						location = p.occupant[i].location,
						massMultiplier = massMultiplier,
						digest = p.sbqData.locations[location].digest,
						nestedPreyData = p.occupant[i].nestedPreyData
					}
				})
				world.sendEntityMessage( source, "addPrey", seatindex + nextSlot, occupantData)
				nextSlot = nextSlot+1
			end
		end
		return true
	end
end

-- to have any extra effects applied to those in digest locations
function p.extraBellyEffects(i, eid, health, status)
end

-- to have effects applied to other locations, for example, womb if the predator does unbirth
function p.otherLocationEffects(i, eid, health, status)
end

-------------------------------------------------------------------------------------------------------

function state.stand.eat(args)
	return p.doVore(args, "belly", {}, "swallow")
end

function state.stand.escape(args)
	return p.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function state.stand.analEscape(args)
	return p.doEscape(args, {}, {} )
end
