state = {}

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
	isPathfinding = false,
	hunger = 100
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

p.seats = {} -- meant to be a redirect pointers to the occupant data
p.lounging = {}

function p.clearOccupant(i)
	return {
		seatname = "occupant"..i,
		index = i,
		id = nil,
		statList = p.sbqData.occupantStatusEffects or {},
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

require("/vehicles/sbq/sbq_occupant_handling.lua")

function init()
end

function update(dt)
	p.checkSpawnerExists()
	p.totalTimeAlive = p.totalTimeAlive + dt
	p.dt = dt
	p.checkRPCsFinished(dt)
	p.checkTimers(dt)

	p.updateOccupants(dt)
	p.handleStruggles(dt)
	p.doBellyEffects(dt)
	p.applyStatusLists()
end

function uninit()
end

function p.checkSpawnerExists()
	if p.spawner and world.entityExists(p.spawner) then
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
