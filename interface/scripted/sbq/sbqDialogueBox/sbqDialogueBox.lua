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
	sbq.checkTimers(dt)
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

	sbq.prevDialogueBranch = dialogueTree
	sbq.dialogueTreeLocation = dialogueTreeLocation

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

	if dialogueTree.callFunctions ~= nil then
		for funcName, args in pairs(dialogueTree.callFunctions) do
			sbq[funcName](table.unpack(args))
		end
	end

	sbq.dismissAfterTimer(dialogueTree.dismissTime)

	return dialogueTree, randomRolls
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

	local dialogueTree = sbq.updateDialogueBox({ voreType, active })
	if active == "yes" then
		sbq.timer("eatMessage", dialogueTree.delay or 1.5, function ()
			sbq.updateDialogueBox({ voreType, "yes", "tease"})
			world.sendEntityMessage( sbq.data.occupantHolder, "requestEat", player.id(), voreType, voreTypeData.location )
		end)
	end
end

function sbq.dismissAfterTimer(time)
	if time == -1 then
		sbq.timerList.dismissAfterTime = nil
	else
		sbq.forceTimer("dismissAfterTime", time or 10, function ()
			pane.dismiss()
		end)
	end
end

function dialogueCont:onClick()
	if sbq.prevDialogueBranch.continue ~= nil then
		table.insert(sbq.dialogueTreeLocation, "continue")
		sbq.updateDialogueBox(sbq.dialogueTreeLocation)
	elseif sbq.prevDialogueBranch.options ~= nil then
		local contextMenu = {}
		for i, option in ipairs(sbq.prevDialogueBranch.options) do
			local action = {option[1]}
			if option[2].dialogue ~= nil then
				table.insert( sbq.dialogueTreeLocation, "options" )
				table.insert( sbq.dialogueTreeLocation, i )
				table.insert( sbq.dialogueTreeLocation, 2 )
				action[2] = function () sbq.updateDialogueBox( sbq.dialogueTreeLocation ) end
			elseif option[2].jump ~= nil then
				action[2] = function () sbq.updateDialogueBox( option[2].jump ) end
			end
			table.insert(contextMenu, action)
		end
		metagui.contextMenu(contextMenu)
	end
end

function oralVore:onClick()
	sbq.voreButton("oralVore")
end

function cockVore:onClick()
	sbq.voreButton("cockVore")
end
