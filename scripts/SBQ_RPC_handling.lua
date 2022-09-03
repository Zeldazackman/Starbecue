function sbq.checkRPCsFinished(dt)
	for i, list in ipairs(sbq.rpcList) do
		list.dt = list.dt + dt -- I think this is good to have, incase the time passed since the RPC was put into play is important
		if list.rpc:finished() then
			if list.rpc:succeeded() and list.callback ~= nil then
				list.callback(list.rpc:result(), list.dt)
			elseif list.failCallback ~= nil then
				list.failCallback(list.dt)
			end
			table.remove(sbq.rpcList, i)
		end
	end
	for name, list in pairs(sbq.namedRPCList) do
		list.dt = list.dt + dt -- I think this is good to have, incase the time passed since the RPC was put into play is important
		if list.rpc:finished() then
			if list.rpc:succeeded() and list.callback ~= nil then
				list.callback(list.rpc:result(), list.dt)
			elseif list.failCallback ~= nil then
				list.failCallback(list.dt)
			end
			sbq.namedRPCList[name] = nil
		end
	end
end

sbq.rpcList = {}
function sbq.addRPC(rpc, callback, failCallback)
	if callback ~= nil or failCallback ~= nil  then
		table.insert(sbq.rpcList, {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0})
	end
end

sbq.namedRPCList = {}
function sbq.addNamedRPC(name, rpc, callback, failCallback)
	if (callback ~= nil or failCallback ~= nil) and name and not sbq.namedRPCList[name] then
		sbq.namedRPCList[name] = {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0}
	end
end


sbq.loopedMessages = {}
function sbq.loopedMessage(name, eid, message, args, callback, failCallback)
	if type(eid) == "number" and world.entityExists(eid) then
		if sbq.loopedMessages[name] == nil then
			sbq.loopedMessages[name] = {
				rpc = world.sendEntityMessage(eid, message, table.unpack(args or {})),
				callback = callback,
				failCallback = failCallback
			}
		elseif sbq.loopedMessages[name].rpc:finished() then
			if sbq.loopedMessages[name].rpc:succeeded() and sbq.loopedMessages[name].callback ~= nil then
				sbq.loopedMessages[name].callback(sbq.loopedMessages[name].rpc:result())
			elseif sbq.loopedMessages[name].failCallback ~= nil then
				sbq.loopedMessages[name].failCallback()
			end
			sbq.loopedMessages[name] = nil
		end
	end
end

sbq.timerList = {}

function sbq.randomTimer(name, min, max, callback)
	if name == nil or sbq.timerList[name] == nil then
		local timer = {
			targetTime = (math.random(min * 100, max * 100))/100,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			sbq.timerList[name] = timer
		else
			table.insert(sbq.timerList, timer)
		end
		return true
	end
end

function sbq.timer(name, time, callback)
	if name == nil or sbq.timerList[name] == nil then
		local timer = {
			targetTime = time,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			sbq.timerList[name] = timer
		else
			table.insert(sbq.timerList, timer)
		end
		return true
	end
end

function sbq.forceTimer(name, time, callback)
		local timer = {
			targetTime = time,
			currTime = 0,
			callback = callback
		}
		if name ~= nil then
			sbq.timerList[name] = timer
		else
			table.insert(sbq.timerList, timer)
		end
		return true
end

function sbq.checkTimers(dt)
	for name, timer in pairs(sbq.timerList) do
		timer.currTime = timer.currTime + dt
		if timer.currTime >= timer.targetTime then
			if timer.callback ~= nil then
				timer.callback()
			end
			if type(name) == "number" then
				table.remove(sbq.timerList, name)
			else
				sbq.timerList[name] = nil
			end
		end
	end
end
