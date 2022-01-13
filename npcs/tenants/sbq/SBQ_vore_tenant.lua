local oldinit = init
local oldupdate = update
local olduninit = uninit
local occupantHolder
local inited
local dialogueBoxOpen = 0
local talkingWithPrey
local timeUntilNewHolder = 0

function init()
	oldinit()
	sbq.config = root.assetJson("/sbqGeneral.config")
	sbq.sbqData = config.getParameter("sbqData") or {}
	storage.sbqSettings = sb.jsonMerge( sbq.config.defaultSettings, sb.jsonMerge(storage.sbqSettings or {}, (sbq.sbqData.defaultSettings or {})))

	message.setHandler("sbqGetDialogueBoxData", function (_,_, id)
		local location = sbq.getOccupantArg(id, "location")
		local dialogueTreeStart
		if location ~= nil then
			dialogueTreeStart = { location, storage.sbqSettings.bellyEffect }
		end
		return { dialogueTreeStart = dialogueTreeStart, sbqData = sbq.sbqData, settings = storage.sbqSettings, dialogueTree = config.getParameter("dialogueTree"), defaultPortrait = config.getParameter("defaultPortrait"), defaultName = config.getParameter("defaultName"), occupantHolder = occupantHolder }
	end)
	message.setHandler("sbqRefreshDialogueBoxData", function (_,_, id, isPrey)
		talkingWithPrey = (isPrey == "prey")
		if not talkingWithPrey and id ~= nil then
			local args = { sourceId = id, sourcePosition = world.entityPosition(id) }
			---@diagnostic disable-next-line: undefined-global
			setInteracted(args)
		end
		dialogueBoxOpen = 0.5
		return { settings = storage.sbqSettings, occupantHolder = occupantHolder }
	end)
	message.setHandler("sbqSay", function (_,_, string, tags)
		npc.say(string, tags)
	end)
	message.setHandler( "sbqNewOccupantHolder", function (_,_, newOccupantHolder)
		occupantHolder = newOccupantHolder
	end)
	message.setHandler( "sbqOccupantHolderExists", function (_,_, occupantHolderId, occupancyData )
		occupantHolder = occupantHolderId
		timeUntilNewHolder = 5

		sbq.occupant = occupancyData.occupant
		sbq.occupants = occupancyData.occupants

	end)
	message.setHandler("sbqSetInteracted", function (_,_, id)
		local args = { sourceId = id, sourcePosition = world.entityPosition(id) }
		---@diagnostic disable-next-line: undefined-global
		setInteracted(args)
	end)

end

function update(dt)
	oldupdate(dt)

	if (not occupantHolder) or (timeUntilNewHolder <= 0) then
		occupantHolder = world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { spawner = entity.id(), sbqData = config.getParameter("sbqData"), states = config.getParameter("states") } )
	end

	if npc.loungingIn() == nil then
		timeUntilNewHolder = math.max(0, timeUntilNewHolder - dt)
	end

	sbq.checkRPCsFinished(dt)
	world.sendEntityMessage(occupantHolder, "faceDirection", mcontroller.facingDirection())
	dialogueBoxOpen = math.max(0, dialogueBoxOpen - dt)
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
	if dialogueBoxOpen == 0 then
		world.sendEntityMessage( args.sourceId, "sbqOpenMetagui", "starbecue:dialogueBox", entity.id() )
	end
end

function sbq.getOccupantArg(id, arg)
	for i, occupant in pairs(sbq.occupant) do
		if occupant.id == id then
			return occupant[arg]
		end
	end
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
