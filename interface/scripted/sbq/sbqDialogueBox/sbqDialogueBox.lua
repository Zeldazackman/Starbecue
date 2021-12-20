---@diagnostic disable: undefined-global

sbq = {}

function init()
	sbq.name = world.entityName(pane.sourceEntity())
	nameLabel:setText(sbq.name)

	sbq.addRPC( world.sendEntityMessage( pane.sourceEntity(), "sbqGetDialogueBoxData" ), function (dialogueBoxData)
		sbq.data = sb.jsonMerge(sbq.data, dialogueBoxData)
		sbq.updateDialogueBox({"greeting", "mood"})
	end)

end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
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

function sbq.getDialogueData()
	sbq.addRPC( world.sendEntityMessage( pane.sourceEntity(), "sbqGetDialogueBoxData" ), function (dialogueBoxData)
		sbq = sb.jsonMerge(sbq, dialogueBoxData)
	end)
end

function sbq.getDialogueBranch(dialogueTreeLocation)
	local dialogueTree = sbq.data.dialogueTree
	sb.logInfo(sb.printJson(dialogueTree,1))
	for _, branch in ipairs(dialogueTreeLocation) do
		sb.logInfo(branch)
		if branch == "mood" then
			if dialogueTree[sbq.data.mood] ~= nil then
				dialogueTree = dialogueTree[sbq.data.mood]
			else
				dialogueTree = dialogueTree.neutral
			end
		elseif dialogueTree[branch] ~= nil then
			dialogueTree = dialogueTree[branch]
		end
	end
	sb.logInfo(sb.printJson(dialogueTree,1))
	return dialogueTree
end

function sbq.updateDialogueBox(dialogueTreeLocation)
	local dialogueTree = sbq.getDialogueBranch(dialogueTreeLocation)
	if not dialogueTree then return false end

	local dialogue = dialogueTree.dialogue
	local portrait = dialogueTree.portrait or sbq.data.defaultPortrait
	local randomRolls = {}
	-- we want to make sure the rolls for the portraits and the dialogue line up
	while type(dialogue) == "table" do
		local roll = math.random(#dialogue)
		table.insert(randomRolls, roll)
		dialogue = dialogue[roll]
	end
	local i = 1
	while type(dialogue) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#portrait))
		end
		portrait = portrait[randomRolls[i]]
		i = i + 1
	end

	dialogueLabel:setText(dialogue)
	dialoguePortrait:setFile(portrait)
end
