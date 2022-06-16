---@diagnostic disable: undefined-global

local inited

sbq = {
	config = root.assetJson("/sbqGeneral.config"),
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
dialogueBoxScripts = {}

require("/scripts/SBQ_RPC_handling.lua")
require("/lib/stardust/json.lua")
require("/interface/scripted/sbq/sbqDialogueBox/sbqDialogueBoxScripts.lua")

function init()
	sbq.name = world.entityName(pane.sourceEntity())
	nameLabel:setText(sbq.name)

	sbq.data = sb.jsonMerge(sbq.data, metagui.inputData)
	if sbq.data.settings.preyEnabled == nil then
		sbq.data.settings = sb.jsonMerge(sbq.data.settings, sb.jsonMerge( sbq.config.defaultPreyEnabled.player, player.getProperty("sbqPreyEnabled") or {}))
	end
	sbq.data.settings.race = world.entitySpecies(pane.sourceEntity())
	for _, script in ipairs(sbq.data.dialogueBoxScripts or {}) do
		require(script)
	end
	if sbq.data.entityPortrait then
		dialoguePortraitCanvas:setVisible(true)
	else
		dialoguePortrait:setVisible(true)
	end
	sbq.dialogueTree = sbq.data.dialogueTree
	sbq.updateDialogueBox(sbq.data.dialogueTreeStart or { "greeting" })
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
			sbq.actualOccupants = occupancyData.actualOccupants
		end)
	end
	sbq.checkVoreButtonsEnabled()
end
function sbq.refreshData()
	sbq.loopedMessage("refreshData", pane.sourceEntity(), "sbqRefreshDialogueBoxData", { player.id(), (player.getProperty("sbqCurrentData") or {}).type }, function (dialogueBoxData)
		sbq.data = sb.jsonMerge(sbq.data, dialogueBoxData)
	end)
end


local prevRandomRolls = {}
local finished = false
local dialoguePos = 1

function sbq.updateDialogueBox(dialogueTreeLocation, dialogueTree)
	local dialogueTree = sbq.getDialogueBranch(dialogueTreeLocation, sbq.data.settings, dialogueTree)
	if not dialogueTree then return false end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	sbq.prevDialogueBranch = dialogueTree

	local randomDialogue = dialogueTree.randomDialogue
	local randomPortrait = dialogueTree.randomPortrait
	local randomName = dialogueTree.randomName
	local randomButtonText = dialogueTree.randomButtonText
	local randomEmote = dialogueTree.randomEmote

	local randomRolls = {}

	if dialogueTree.useLastRandom then
		randomRolls = prevRandomRolls
	end
	-- we want to make sure the rolls for the portraits and the dialogue line up
	randomRolls, randomDialogue		= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomDialogue, "randomDialogue")
	randomRolls, randomPortrait		= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomPortrait, "randomPortrait")
	randomRolls, randomName			= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomName, "randomName")
	randomRolls, randomButtonText	= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomButtonText, "randomButtonText")
	randomRolls, randomEmote		= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomEmote, "randomEmote")

	prevRandomRolls = randomRolls

	local playerName = world.entityName(player.id())
	local speaker = pane.sourceEntity()

	if dialogueTree.speaker ~= nil then
		speaker = dialogueTree.speaker
		if type(speaker) == "string" then
			speaker = world.loadUniqueEntity(speaker)
		end
	end
	local tags = { entityname = playerName }
	local imagePortrait

	if type(randomName) == "string" then
		nameLabel:setText(randomName)
	elseif dialogueTree.name ~= nil then
		if type(dialogueTree.name) == "table" then
			nameLable:setText(dialogueTree.name[dialoguePos] or dialogueTree.name[#dialogueTree.name] or sbq.data.defaultName or world.entityName(pane.sourceEntity()))
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
			dialogueCont:setText(dialogueTree.buttonText[dialoguePos] or dialogueTree.buttonText[#dialogueTree.buttonText] or "...")
		else
			dialogueCont:setText(dialogueTree.buttonText)
		end
	else
		dialogueCont:setText("...")
	end

	if type(randomPortrait) == "string" then
		if sbq.data.entityPortrait then
			sbq.setPortrait( dialoguePortraitCanvas, world.entityPortrait( speaker, randomPortrait or sbq.data.defaultPortrait ), {32,8} )
		else
			imagePortrait = ((sbq.data.portraitPath or "")..(randomPortrait or sbq.data.defaultPortrait))
			dialoguePortrait:setFile(imagePortrait)
		end
	elseif dialogueTree.portrait ~= nil then
		if type(dialogueTree.portrait) == "table" then
			if sbq.data.entityPortrait then
				sbq.setPortrait( dialoguePortraitCanvas, world.entityPortrait( speaker, dialogueTree.portrait[dialoguePos] or dialogueTree.portrait[#dialogueTree.portrait] or sbq.data.defaultPortrait ), {32,8} )
			else
				imagePortrait = ((sbq.data.portraitPath or "")..(dialogueTree.portrait[dialoguePos] or dialogueTree.portrait[#dialogueTree.portrait] or sbq.data.defaultPortrait))
				dialoguePortrait:setFile(imagePortrait)
			end
		else
			if sbq.data.entityPortrait then
				sbq.setPortrait( dialoguePortraitCanvas, world.entityPortrait( speaker, dialogueTree.portrait or sbq.data.defaultPortrait ), {32,8} )
			else
				imagePortrait = ((sbq.data.portraitPath or "")..(dialogueTree.portrait or sbq.data.defaultPortrait))
				dialoguePortrait:setFile(imagePortrait)
			end
		end
	else
		if sbq.data.entityPortrait then
			sbq.setPortrait( dialoguePortraitCanvas, world.entityPortrait( speaker, sbq.data.defaultPortrait ), {32,8} )
		else
			imagePortrait = ((sbq.data.portraitPath or "")..(sbq.data.defaultPortrait))
			dialoguePortrait:setFile(imagePortrait)
		end
	end

	if type(randomDialogue) == "string" then
		local randomDialogue = sbq.generateKeysmashes(randomDialogue, dialogueTree.keysmashMin, dialogueTree.keysmashMax)
		dialogueLabel:setText(sb.replaceTags(randomDialogue, tags))
		world.sendEntityMessage(speaker, "sbqSay", randomDialogue, tags, imagePortrait, randomEmote)
		finished = true
	elseif dialogueTree.dialogue ~= nil then
		local dialogue = sbq.generateKeysmashes(dialogueTree.dialogue[dialoguePos] or dialogueTree.dialogue[#dialogueTree.dialogue], dialogueTree.keysmashMin, dialogueTree.keysmashMax)
		dialogueLabel:setText(sb.replaceTags(dialogue, tags ))
		world.sendEntityMessage(speaker, "sbqSay", dialogue, tags, imagePortrait, (dialogueTree.emote or {})[dialoguePos])
		if dialoguePos >= #dialogueTree.dialogue then
			finished = true
			dialoguePos = 1
		else
			dialoguePos = dialoguePos + 1
		end
	else
		dialogueLabel:setText("")
	end

	sbq.dismissAfterTimer(dialogueTree.dismissTime)

	return dialogueTree, randomRolls
end

function sbq.setPortrait( canvasName, data, offset )
	local canvas = widget.bindCanvas( canvasName.backingWidget )
	canvas:clear()
	for k,v in ipairs(data or {}) do
		local pos = v.position or {0, 0}
		canvas:drawImage(v.image, { pos[1]+offset[1], pos[2]+offset[2]}, 4, nil, true )
	end
end

local keysmashchars = {"a","s","d","f","g","h","j","k","","l",";","\'"}
function sbq.generateKeysmashes(input, lengthMin, lengthMax)
	local input = input or ""
	return input:gsub("<keysmash>", function ()
		local keysmash = ""
		for i = 1, math.random(lengthMin or 5, lengthMax or 15) do
			keysmash = keysmash..keysmashchars[math.random(#keysmashchars)]
		end
		return keysmash
	end)
end

function sbq.checkVoreTypeActive(voreType)
	if (not sbq.data.settings) or sbq.data.settings.isPrey then return "hidden" end
	if not (sbq.data.settings[voreType.."Pred"] or sbq.data.settings[voreType.."PredEnable"]) then return "hidden" end
	local currentData = player.getProperty( "sbqCurrentData") or {}

	local locationName = sbq.data.sbqData.voreTypes[voreType]
	if not locationName then return "hidden" end

	local locationData = sbq.data.sbqData.locations[locationName]
	if not locationData then return "hidden" end

	local preyEnabled = sb.jsonMerge( sbq.config.defaultPreyEnabled.player, (status.statusProperty("sbqPreyEnabled") or {}))
	if (sbq.data.settings[voreType.."PredEnable"] or sbq.data.settings[voreType.."Pred"]) and preyEnabled.preyEnabled and preyEnabled[voreType] and ( currentData.type ~= "prey" ) then
		if sbq.data.settings[voreType.."Pred"] then
			if type(sbq.data.occupantHolder) ~= "nil" and type(sbq.occupants) == "table" then
				if currentData.type == "driver" and ((not currentData.edible) or (((sbq.occupants[locationName] + 1 + currentData.totalOccupants) > (sbq.data.settings.visualMax[locationName] or locationData.max))) and not (sbq.data.settings.hammerspace and not sbq.data.settings.hammerspaceDisabled[locationName]) ) then
					return "tooBig", locationName, locationData
				elseif (sbq.occupants[locationName] >= (sbq.data.settings.visualMax[locationName] or locationData.max) ) then
					if sbq.actualOccupants == 0 then
						return "otherLocationFull", locationName, locationData
					else
						return "full", locationName, locationData
					end
				else
					return "request", locationName, locationData
				end
			else
				return "request", locationName, locationData
			end
		else
			return "notFeelingIt", locationName, locationData
		end
	else
		return "hidden", locationName, locationData
	end
end

function sbq.checkVoreButtonsEnabled()
	for voreType, data in pairs(sbq.data.icons or {}) do
		local button = _ENV[voreType]
		local active = sbq.checkVoreTypeActive(voreType)
		button:setVisible(active ~= "hidden")
		local image = sbq.data.icons[voreType]
		if active ~= "request" then
			image = image.."?brightness=-25?saturation=-100"
		end
		button:setImage(image)
	end
end

function sbq.voreButton(voreType)
	local active, locationName, locationData = sbq.checkVoreTypeActive(voreType)
	sbq.data.settings.voreType = voreType
	sbq.data.settings.getVoreButtonAction = active
	sbq.data.settings.location = locationName
	sbq.data.settings.locationDigest = locationData.digest

	if active == "request" then
		sbq.data.settings.doingVore = "before"
		local dialogueTree = sbq.updateDialogueBox({ "vore" }) or {}
		sbq.timer("eatMessage", dialogueTree.delay or 1.5, function ()
			sbq.data.settings.doingVore = "after"
			sbq.updateDialogueBox({ "vore" })
			world.sendEntityMessage( sbq.data.occupantHolder or pane.sourceEntity(), "requestTransition", voreType, { id =  player.id() } )
		end)
	else
		sbq.updateDialogueBox({ "vore" })
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
		return sbq.updateDialogueBox({}, sbq.prevDialogueBranch)
	else
		finished = false
	end
	if type(sbq.prevDialogueBranch.callScript) == "string" then
		if type(dialogueBoxScripts[sbq.prevDialogueBranch.callScript]) == "function" then
			sbq.updateDialogueBox({}, dialogueBoxScripts[sbq.prevDialogueBranch.callScript](sbq.prevDialogueBranch, sbq.data.settings, table.unpack(sbq.prevDialogueBranch.scriptArgs)))
		end
	elseif sbq.prevDialogueBranch.continue ~= nil then
		if sbq.prevDialogueBranch.continue.nearEntitiesNamed ~= nil then
			local entities = checkEntitiesMatch( world.entityQuery( world.entityPosition(player.id()), sbq.prevDialogueBranch.continue.range or 10, sbq.prevDialogueBranch.continue.queryArgs or {includedTypes = {"object", "npc", "vehicle", "monster"}} ), sbq.prevDialogueBranch.continue.nearEntitiesNamed)
			if entities ~= nil then
				for _, entity in ipairs(entities) do
					world.sendEntityMessage( entity, "sbqSetInteracted", player.id())
				end
				sbq.updateDialogueBox({}, sbq.prevDialogueBranch.continue)
			else
				sbq.updateDialogueBox({}, sbq.prevDialogueBranch.fail)
			end
		else
			sbq.updateDialogueBox({}, sbq.prevDialogueBranch.continue)
		end
	elseif sbq.prevDialogueBranch.jump ~= nil then
		sbq.updateDialogueBox(sbq.prevDialogueBranch.jump)
	elseif sbq.prevDialogueBranch.options ~= nil then
		for i, option in ipairs(sbq.prevDialogueBranch.options) do
			local action = {option[1]}
			local continue = true
			local entities = {}
			if option[2].nearEntitiesNamed ~= nil then
				continue = false
				local found = checkEntityName( world.entityQuery( world.entityPosition(player.id()), option[2].range or 10, sbq.prevDialogueBranch.continue.queryArgs or {includedTypes = {"object", "npc", "vehicle", "monster"}}), option[2].nearEntitiesNamed)
				for _, id in ipairs(found) do
					continue = true
					table.insert(entities, id)
				end
			end
			if option[2].nearUniqueId ~= nil then
				local found = checkEntityUniqueId( world.entityQuery( world.entityPosition(player.id()), option[2].range or 10, sbq.prevDialogueBranch.continue.queryArgs or {includedTypes = {"object", "npc", "vehicle", "monster"}}), option[2].nearUniqueId)
				for _, id in ipairs(found) do
					continue = true
					table.insert(entities, id)
				end
			end
			if continue and ((option[2].voreType == nil) or ( sbq.checkVoreTypeActive(option[2].voreType) ~= "hidden" )) then
				if option[2].dialogue ~= nil or option[2].randomDialogue ~= nil or option[2].next then
					action[2] = function ()
						for _, entity in ipairs(entities) do
							world.sendEntityMessage( entity, "sbqSetInteracted", player.id())
						end
						sbq.updateDialogueBox( {}, option[2] )
					end
				elseif option[2].jump ~= nil then
					action[2] = function () sbq.updateDialogueBox( option[2].jump ) end
				end
				table.insert(contextMenu, action)
			end
		end
	end
	if #contextMenu > 0 then
		metagui.contextMenu(contextMenu)
	end
end

function checkEntityName(entities, find)
	local found = {}
	local continue
	for _, name in ipairs(find) do
		for _, entity in ipairs(entities) do
			if name == world.entityName(entity) then
				table.insert(found, entity)
				continue = true
			end
		end
		if not continue then return {} end
	end
	return found
end

function checkEntityUniqueId(entities, find)
	local found = {}
	local continue
	for _, name in ipairs(find) do
		for _, entity in ipairs(entities) do
			if name == world.entityUniqueId(entity) then
				table.insert(found, entity)
				continue = true
			end
		end
		if not continue then return {} end
	end
	return found
end

function close:onClick()
	pane.dismiss()
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
