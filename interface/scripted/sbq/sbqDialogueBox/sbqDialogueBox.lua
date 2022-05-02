---@diagnostic disable: undefined-global

local inited

sbq = {
	data = {
		settings = { personality = "default", mood = "default" },
		defaultPortrait = "/empty_image.png",
		icons = {
			oralVore = "/items/active/sbqController/oralVore.png",
			tailVore = "/items/active/sbqController/tailVore.png",
			absorbVore = "/items/active/sbqController/absorbVore.png",
			navelVore = "/items/active/sbqController/navelVore.png",

			analVore = "/items/active/sbqController/analVore.png",
			cockVore = "/items/active/sbqController/cockVore.png",
			breastVore = "/items/active/sbqController/breastVore.png",
			unbirth = "/items/active/sbqController/unbirth.png"
		}
	}
}

require("/scripts/SBQ_RPC_handling.lua")
require( "/lib/stardust/json.lua" )

function init()
	sbq.config = root.assetJson("/sbqGeneral.config")
	sbq.name = world.entityName(pane.sourceEntity())
	nameLabel:setText(sbq.name)

	sbq.data = sb.jsonMerge(sbq.data, metagui.inputData)
	if sbq.data.settings.digestionImmunity == nil then
		sbq.data.settings.digestionImmunity = (player.getProperty("sbqPreyEnabled") or {}).digestionImmunity or false
	end
	if sbq.data.dialogueBoxScripts ~= nil then
		for _, script in ipairs(sbq.data.dialogueBoxScripts) do
			require(script)
		end
	end
	sbq.updateDialogueBox(sbq.data.dialogueTreeStart or { "greeting", "personality", "mood" })
end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)
	sbq.refreshData()
	sbq.getOccupancy()
end

function sbq.getOccupancy()
	if sbq.data.occupantHolder ~= nil then
		sbq.loopedMessage("getOccupancy", sbq.data.occupantHolder, "getOccupancyData", {}, function (occupancyData)
			sbq.occupant = occupancyData.occupant
			sbq.occupants = occupancyData.occupants
			sbq.checkVoreButtonsEnabled()
		end)
	end
end
function sbq.refreshData()
	sbq.loopedMessage("refreshData", pane.sourceEntity(), "sbqRefreshDialogueBoxData", { player.id(), (player.getProperty("sbqCurrentData") or {}).type }, function (dialogueBoxData)
		sbq.data = sb.jsonMerge(sbq.data, dialogueBoxData)
	end)
end

function sbq.getDialogueData()
	sbq.addRPC( world.sendEntityMessage( pane.sourceEntity(), "sbqGetDialogueBoxData" ), function (dialogueBoxData)
		sbq = sb.jsonMerge(sbq, dialogueBoxData)
	end)
end

function sbq.getDialogueBranch(dialogueTreeLocation)
	local dialogueTree = sbq.data.dialogueTree
	for _, branch in ipairs(dialogueTreeLocation) do
		if sbq.data.settings[branch] ~= nil then
			dialogueTree =  dialogueTree[tostring(sbq.data.settings[branch])] or dialogueTree.default or dialogueTree
		else
			dialogueTree = dialogueTree[branch] or dialogueTree
		end
		-- for dialog in other files thats been pointed to
		if type(dialogueTree) == "string" then
			if dialogueTree[1] == "/" then
				dialogueTree = root.assetJson(dialogueTree)
			elseif dialogueTree[1] == "[" then
				local decoded = json.decode(dialogueTree[1])
				if type(decoded) == "table" then
					dialogueTree = sbq.getDialogueBranch(decoded) -- I know, recursion is risky, but none of this stuff is randomly generated someone would have to intentionally make a loop to break it
				end
			end
		end
	end
	return dialogueTree
end

local prevRandomRolls = {}
local finished = false
local dialoguePos = 1

function sbq.updateDialogueBox(dialogueTreeLocation)
	local dialogueTree = sbq.getDialogueBranch(dialogueTreeLocation)
	if not dialogueTree then return false end

	sbq.prevDialogueBranch = dialogueTree
	sbq.dialogueTreeLocation = dialogueTreeLocation

	local randomDialogue = dialogueTree.randomDialogue
	local randomPortrait = dialogueTree.randomPortrait
	local randomName = dialogueTree.randomName
	local randomButtonText = dialogueTree.randomButtonText

	local randomRolls = {}

	if dialogueTree.useLastRandom then
		randomRolls = prevRandomRolls
	end
	-- we want to make sure the rolls for the portraits and the dialogue line up
	local i = 1
	while type(randomDialogue) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomDialogue))
		end
		randomDialogue = randomDialogue[randomRolls[i]]
		i = i + 1
	end
	i = 1
	while type(randomPortrait) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomPortrait))
		end
		randomPortrait = randomPortrait[randomRolls[i]]
		i = i + 1
	end
	i = 1
	while type(randomName) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomName))
		end
		randomName = randomName[randomRolls[i]]
		i = i + 1
	end
	i = 1
	while type(randomButtonText) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomButtonText))
		end
		randomButtonText = randomButtonText[randomRolls[i]]
		i = i + 1
	end
	prevRandomRolls = randomRolls

	local playerName = world.entityName(player.id())

	if type(randomPortrait) == "string" then
		dialoguePortrait:setFile(randomPortrait)
	elseif dialogueTree.portrait ~= nil then
		if type(dialogueTree.portrait) == "table" then
			dialoguePortrait:setFile(dialogueTree.portrait[dialoguePos] or sbq.data.defaultPortrait)
		else
			dialoguePortrait:setFile(dialogueTree.portrait)
		end
	else
		dialoguePortrait:setFile(sbq.data.defaultPortrait)
	end

	if type(randomName) == "string" then
		nameLabel:setText(randomName)
	elseif dialogueTree.name ~= nil then
		if type(dialogueTree.name) == "table" then
			nameLable:setText(dialogueTree.name[dialoguePos] or sbq.data.defaultName or world.entityName(pane.sourceEntity()))
		else
			nameLable:setText(dialogueTree.name)
		end
	else
		nameLabel:setText(sbq.data.defaultName or world.entityName(pane.sourceEntity()))
	end

	if type(randomButtonText) == "string" then
		dialogueCont:setText(randomButtonText)
	elseif dialogueTree.buttonText ~= nil then
		if type(dialogueTree.buttonText) == "table" then
			dialogueCont:setText(dialogueTree.buttonText[dialoguePos] or "...")
		else
			dialogueCont:setText(dialogueTree.buttonText)
		end
	else
		dialogueCont:setText("...")
	end

	local speaker = pane.sourceEntity()

	if dialogueTree.speaker ~= nil then
		speaker = dialogueTree.speaker
	end
	local tags = { entityname = playerName }

	if type(randomDialogue) == "string" then
		dialogueLabel:setText(sb.replaceTags(randomDialogue, tags))
		world.sendEntityMessage(speaker, "sbqSay", randomDialogue, tags)
		finished = true
	elseif dialogueTree.dialogue ~= nil then
		dialogueLabel:setText(sb.replaceTags(dialogueTree.dialogue[dialoguePos], tags ))
		world.sendEntityMessage(speaker, "sbqSay", dialogueTree.dialogue[dialoguePos], tags)

		if dialoguePos >= #dialogueTree.dialogue then
			finished = true
			dialoguePos = 1
		else
			dialoguePos = dialoguePos + 1
		end
	else
		dialogueLabel:setText("")
	end

	if finished then
		if dialogueTree.callFunctions ~= nil then
			for funcName, args in pairs(dialogueTree.callFunctions) do
				sbq[funcName](table.unpack(args))
			end
		end
	end

	sbq.dismissAfterTimer(dialogueTree.dismissTime)

	return dialogueTree, randomRolls
end

function sbq.checkVoreTypeActive(voreType)
	local voreTypeData = ((sbq.data.settings or {}).voreTypes or {})[voreType]
	if voreTypeData == nil then return "hidden" end

	local currentData = player.getProperty( "sbqCurrentData") or {}

	local preyEnabled = sb.jsonMerge( sbq.config.defaultPreyEnabled.player, (status.statusProperty("sbqPreyEnabled") or {}))
	if (voreTypeData ~= nil) and voreTypeData.enabled and preyEnabled.enabled and preyEnabled[voreType] and ( currentData.type ~= "prey" ) then
		if voreTypeData.feelingIt then
			if currentData.type == "driver" and ((not currentData.edible) or ( (sbq.occupants[voreTypeData.location] + 1 + currentData.totalOccupants) > sbq.data.sbqData.locations[voreTypeData.location].max)) then
				return "tooBig"
			elseif (sbq.occupants[voreTypeData.location] >= sbq.data.sbqData.locations[voreTypeData.location].max ) then
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
	for voreType, data in pairs((sbq.data.settings or {}).voreTypes or {}) do
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

	local dialogueTree = sbq.updateDialogueBox({ "vore", voreType, "personality", "mood", active })
	if active == "yes" then
		sbq.timer("eatMessage", dialogueTree.delay or 1.5, function ()
			sbq.updateDialogueBox({ "vore", voreType, "personality", "mood", "yes", "tease"})
			world.sendEntityMessage( sbq.data.occupantHolder, "requestTransition", voreType, { id =  player.id() } )
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
	local contextMenu = {}
	if not finished then
		return sbq.updateDialogueBox(sbq.dialogueTreeLocation)
	else
		finished = false
	end

	if sbq.prevDialogueBranch.continue ~= nil then
		table.insert(sbq.dialogueTreeLocation, "continue")
		if sbq.prevDialogueBranch.continue.nearEntitiesNamed ~= nil then
			local entities = checkEntitiesMatch( world.entityQuery( world.entityPosition(player.id()), sbq.prevDialogueBranch.continue.range or 10, sbq.prevDialogueBranch.continue.queryArgs or {includedTypes = {"object", "npc", "vehicle", "monster"}} ), sbq.prevDialogueBranch.continue.nearEntitiesNamed)
			if entities ~= nil then
				for _, entity in ipairs(entities) do
					world.sendEntityMessage( entity, "sbqSetInteracted", player.id())
				end
				sbq.updateDialogueBox(sbq.dialogueTreeLocation)
			else
				sbq.updateDialogueBox(sbq.prevDialogueBranch.failJump)
			end
		else
			sbq.updateDialogueBox(sbq.dialogueTreeLocation)
		end
	elseif sbq.prevDialogueBranch.jump ~= nil then
		sbq.updateDialogueBox(sbq.prevDialogueBranch.jump)
	elseif sbq.prevDialogueBranch.options ~= nil then
		for i, option in ipairs(sbq.prevDialogueBranch.options) do
			local action = {option[1]}
			if option[2].nearEntitiesNamed ~= nil and (option[2].voreType == nil) or ( sbq.checkVoreTypeActive(option[2].voreType) ~= "hidden" ) then
				local entities = checkEntitiesMatch( world.entityQuery( world.entityPosition(player.id()), option[2].range or 10, sbq.prevDialogueBranch.continue.queryArgs or {includedTypes = {"object", "npc", "vehicle", "monster"}}), option[2].nearEntitiesNamed)
				if entities ~= nil then
					if option[2].dialogue ~= nil or option[2].randomDialogue ~= nil then
						action[2] = function ()
							table.insert( sbq.dialogueTreeLocation, "options" )
							table.insert( sbq.dialogueTreeLocation, i )
							table.insert( sbq.dialogueTreeLocation, 2 )
							for _, entity in ipairs(entities) do
								world.sendEntityMessage( entity, "sbqSetInteracted", player.id())
							end
							sbq.updateDialogueBox( sbq.dialogueTreeLocation )
						end
					elseif option[2].jump ~= nil then
						action[2] = function () sbq.updateDialogueBox( option[2].jump ) end
					end
					table.insert(contextMenu, action)
				end
			elseif (option[2].voreType == nil) or ( sbq.checkVoreTypeActive(option[2].voreType) ~= "hidden" ) then
				if option[2].dialogue ~= nil or option[2].randomDialogue ~= nil then
					action[2] = function ()
						table.insert( sbq.dialogueTreeLocation, "options" )
						table.insert( sbq.dialogueTreeLocation, i )
						table.insert( sbq.dialogueTreeLocation, 2 )
						sbq.updateDialogueBox( sbq.dialogueTreeLocation )
					end
				elseif option[2].jump ~= nil then
					action[2] = function () sbq.updateDialogueBox( option[2].jump ) end
				end
				table.insert(contextMenu, action)
			end
		end
	end
	if sbq.prevDialogueBranch.buttonFunc ~= nil and sbq[sbq.prevDialogueBranch.buttonFunc] ~= nil then
		sbq[sbq.prevDialogueBranch.buttonFunc]()
	end
	if #contextMenu > 0 then
		metagui.contextMenu(contextMenu)
	end
end

function checkEntitiesMatch(entities, find)
	local found = {}
	local continue
	for _, name in ipairs(find) do
		for _, entity in ipairs(entities) do
			if name == world.entityName(entity) then
				table.insert(found, entity)
				continue = true
			end
		end
		if not continue then return end
	end
	return found
end


function oralVore:onClick()
	sbq.voreButton("oralVore")
end

function tailVore:onClick()
	sbq.voreButton("tailVore")
end

function absorbVore:onClick()
	sbq.voreButton("absorbVore")
end

function navelVore:onClick()
	sbq.voreButton("navelVore")
end


function analVore:onClick()
	sbq.voreButton("analVore")
end

function cockVore:onClick()
	sbq.voreButton("cockVore")
end

function breastVore:onClick()
	sbq.voreButton("breastVore")
end

function unbirth:onClick()
	sbq.voreButton("unbirth")
end
