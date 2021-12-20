---@diagnostic disable: undefined-global

local inited

sbq = {
	data = {
		mood = "neutral",
		defaultPortrait = "/empty_image.png",
		icons = {
			oralVore = "/items/active/sbqController/oralVore.png",
			tailVore = "/items/active/sbqController/tailVore.png",
			absorbVore = "/items/active/sbqController/absorbVore.png",

			analVore = "/items/active/sbqController/analVore.png",
			cockVore = "/items/active/sbqController/cockVore.png",
			breastVore = "/items/active/sbqController/breastVore.png",
			unbirth = "/items/active/sbqController/unbirth.png"
		}
	}
}

function init()
	sbq.config = root.assetJson("/sbqGeneral.config")
	sbq.name = world.entityName(pane.sourceEntity())
	nameLabel:setText(sbq.name)

	sbq.addRPC( world.sendEntityMessage( pane.sourceEntity(), "sbqGetDialogueBoxData", player.id() ), function (dialogueBoxData)
		sbq.data = sb.jsonMerge(sbq.data, dialogueBoxData)
		sbq.updateDialogueBox( dialogueBoxData.dialogueTreeStart or {"greeting", "mood"})
		inited = true
	end)
end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
	if not inited then return end
	sbq.refreshData()
	sbq.getOccupancy()
end

function sbq.getOccupancy()
	sbq.loopedMessage("getOccupancy", sbq.data.occupantHolder, "getOccupancyData", {}, function (occupancyData)
		sbq.occupant = occupancyData.occupant
		sbq.occupants = occupancyData.occupants
		sbq.checkVoreButtonsEnabled()
	end)
end
function sbq.refreshData()
	sbq.loopedMessage("refreshData", pane.sourceEntity(), "sbqRefreshDialogueBoxData", {}, function (dialogueBoxData)
		sbq.data = sb.jsonMerge(sbq.data, dialogueBoxData)
	end)
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
	for _, branch in ipairs(dialogueTreeLocation) do
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
	local playerName = world.entityName(player.id())
	dialogue = sb.replaceTags( dialogue, { entityname = playerName })

	dialogueLabel:setText(dialogue)
	world.sendEntityMessage(pane.sourceEntity(), "sbqSay", dialogue)
	dialoguePortrait:setFile(portrait)
end

function sbq.checkVoreTypeActive(voreType)
	local voreTypeData = sbq.data.settings.voreTypes[voreType]
	local preyEnabled = sb.jsonMerge( sbq.config.defaultPreyEnabled.player, (status.statusProperty("sbqPreyEnabled") or {}))
	if (voreTypeData ~= nil) and voreTypeData.enabled and preyEnabled.enabled and preyEnabled[voreType] then
		if voreTypeData.feelingIt then
			if (sbq.occupants[voreTypeData.location] >= sbq.data.sbqData.locations[voreTypeData.location].max ) then
				return "full"
			else
				return "yes"
			end
		else
			return "notFeelingIt"
		end
	else
		return "hidden"
	end
end

function sbq.checkVoreButtonsEnabled()
	for voreType, data in pairs(sbq.data.settings.voreTypes) do
		local button = _ENV[voreType]
		local active = sbq.checkVoreTypeActive(voreType)
		button:setVisible(active ~= "hidden")
		local image = sbq.data.icons[voreType]
		if active ~= "yes" then
			image = image.."?brightness=-25?saturation=-100"
		end
		button:setImage(image)
	end
end

function sbq.voreButton(voreType)
	local active = sbq.checkVoreTypeActive(voreType)
	local voreTypeData = sbq.data.settings.voreTypes[voreType]

	sbq.updateDialogueBox({ voreType, active })
	if active == "yes" then
		world.sendEntityMessage( sbq.data.occupantHolder, "requestEat", player.id(), voreType, voreTypeData.location )
	end
end

function oralVore:onClick()
	sbq.voreButton("oralVore")
end

function cockVore:onClick()
	sbq.voreButton("cockVore")
end
