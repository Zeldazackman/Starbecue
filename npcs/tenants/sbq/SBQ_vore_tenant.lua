local oldinit = init
local oldupdate = update
local olduninit = uninit
local occupantHolder
local inited

function init()
	oldinit()
	sbq.sbqData = config.getParameter("sbqData") or {}
	storage.sbqSettings = sb.jsonMerge(storage.sbqSettings or {}, (sbq.sbqData.defaultSettings or {}))
	message.setHandler("sbqGetDialogueBoxData", function ()
		return { sbqData = sbq.sbqData, settings = storage.sbqSettings, dialogueTree = config.getParameter("dialogueTree"), defaultPortrait = config.getParameter("defaultPortrait"), occupantHolder = occupantHolder }
	end)
	message.setHandler("sbqRefreshDialogueBoxData", function ()
		return { settings = storage.sbqSettings, occupantHolder = occupantHolder }
	end)
end

function update(dt)
	oldupdate(dt)

	if not occupantHolder then
		occupantHolder = world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { spawner = entity.id(), sbqData = config.getParameter("sbqData"), states = config.getParameter("states") } )
	end

	sbq.checkRPCsFinished(dt)
end

function uninit()
	olduninit()
end

function sbq.checkRPCsFinished(dt)
	for i, list in pairs(sbq.rpcList) do
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
end

sbq.rpcList = {}
function sbq.addRPC(rpc, callback, failCallback)
	if callback ~= nil or failCallback ~= nil  then
		table.insert(sbq.rpcList, {rpc = rpc, callback = callback, failCallback = failCallback, dt = 0})
	end
end

sbq.loopedMessages = {}
function sbq.loopedMessage(name, eid, message, args, callback, failCallback)
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

function handleInteract(args)
	world.sendEntityMessage( args.sourceId, "sbqOpenMetagui", "starbecue:dialogueBox", entity.id() )
end

function sbq.oralVore(args)
	local distance = entity.distanceToEntity(args.sourceId)
	if entity.entityInSight(args.sourceId) and ( math.abs(distance[1]) <= 5 ) and ( math.abs(distance[2]) <= 5 ) then
		sbq.requestEat(args.sourceId, "oralVore", "belly")
	end
end

function sbq.requestEat(prey, voreType, location)
	world.sendEntityMessage(occupantHolder, "requestEat", prey, voreType, location )
end

function sbq.requestUneat(prey, voreType)
	world.sendEntityMessage(occupantHolder, "requestUneat", prey, voreType )
end
