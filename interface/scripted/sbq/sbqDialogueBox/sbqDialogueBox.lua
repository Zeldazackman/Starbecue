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

require("/scripts/SBQ_RPC_handling.lua")
require( "/lib/stardust/json.lua" )

function init()
	sbq.name = world.entityName(pane.sourceEntity())
	nameLabel:setText(sbq.name)

	sbq.data = sb.jsonMerge(sbq.data, metagui.inputData)
	if sbq.data.settings.digestionImmunity == nil then
		sbq.data.settings.digestionImmunity = (player.getProperty("sbqPreyEnabled") or {}).digestionImmunity or false
	end
	sbq.data.settings.race = world.entitySpecies(pane.sourceEntity())
	if sbq.data.dialogueBoxScripts ~= nil then
		for _, script in ipairs(sbq.data.dialogueBoxScripts) do
			require(script)
		end
	end
	if sbq.data.entityPortrait then
		dialoguePortraitCanvas:setVisible(true)
	else
		dialoguePortrait:setVisible(true)
	end
	sbq.updateDialogueBox(sbq.data.dialogueTreeStart or { "greeting", "race", "personality", "mood" })
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
			sbq.checkVoreButtonsEnabled()
		end)
	end
end
function sbq.refreshData()
	sbq.loopedMessage("refreshData", pane.sourceEntity(), "sbqRefreshDialogueBoxData", { player.id(), (player.getProperty("sbqCurrentData") or {}).type }, function (dialogueBoxData)
		sbq.data = sb.jsonMerge(sbq.data, dialogueBoxData)
	end)
end

function sbq.getDialogueBranch(dialogueTreeLocation)
	local dialogueTree = sbq.getRedirectedDialogue(sbq.data.dialogueTree) or {}

	for _, branch in ipairs(dialogueTreeLocation) do
		if sbq.data.settings[branch] ~= nil then
			dialogueTree =  dialogueTree[tostring(sbq.data.settings[branch])] or dialogueTree[branch] or dialogueTree.default or dialogueTree
		else
			dialogueTree = dialogueTree[branch] or dialogueTree
		end
		dialogueTree = sbq.getRedirectedDialogue(dialogueTree)
	end
	return dialogueTree
end

local recursionCount = 0
-- for dialog in other files thats been pointed to
function sbq.getRedirectedDialogue(dialogueTree)
	local dialogueTree = dialogueTree
	if type(dialogueTree) == "string" then
		local firstChar = dialogueTree:sub(1,1)
		if firstChar == "/" then
			dialogueTree = root.assetJson(dialogueTree)
		else
			local found1 = dialogueTree:find("%.")
			local jump = {}
			while found1 do
				table.insert(jump, dialogueTree:sub(1,found1-1))
				dialogueTree = dialogueTree:sub(found1+1,-1)
				found1 = dialogueTree:find("%.")
			end
			table.insert(jump, dialogueTree)
			if recursionCount > 10 then return {} end -- protection against possible infinite loops of recusion
			recursionCount = recursionCount + 1
			dialogueTree = sbq.getDialogueBranch(jump)
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
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	sbq.prevDialogueBranch = dialogueTree
	sbq.dialogueTreeLocation = dialogueTreeLocation

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
	local i = 1
	while type(randomDialogue) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomDialogue))
		end
		randomDialogue = randomDialogue[randomRolls[i]]
		if type(randomDialogue) == "string" then
			local firstChars = randomDialogue:sub(1,2)
			if firstChars == "&&" then
				randomDialogue = sbq.getRedirectedDialogue(randomDialogue:sub(3,-1)).randomDialogue
			end
		end
		i = i + 1
	end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	i = 1
	while type(randomPortrait) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomPortrait))
		end
		randomPortrait = randomPortrait[randomRolls[i]]
		if type(randomPortrait) == "string" then
			local firstChars = randomPortrait:sub(1,2)
			if firstChars == "&&" then
				randomPortrait = sbq.getRedirectedDialogue(randomPortrait:sub(3,-1)).randomPortrait
			end
		end
		i = i + 1
	end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	i = 1
	while type(randomName) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomName))
		end
		randomName = randomName[randomRolls[i]]
		if type(randomName) == "string" then
			local firstChars = randomName:sub(1,2)
			if firstChars == "&&" then
				randomName = sbq.getRedirectedDialogue(randomName:sub(3,-1)).randomName
			end
		end
		i = i + 1
	end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	i = 1
	while type(randomButtonText) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomButtonText))
		end
		randomButtonText = randomButtonText[randomRolls[i]]
		if type(randomButtonText) == "string" then
			local firstChars = randomButtonText:sub(1,2)
			if firstChars == "&&" then
				randomButtonText = sbq.getRedirectedDialogue(randomButtonText:sub(3,-1)).randomButtonText
			end
		end
		i = i + 1
	end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	i = 1
	while type(randomEmote) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomEmote))
		end
		randomEmote = randomEmote[randomRolls[i]]
		if type(randomEmote) == "string" then
			local firstChars = randomEmote:sub(1,2)
			if firstChars == "&&" then
				randomEmote = sbq.getRedirectedDialogue(randomEmote:sub(3,-1)).randomEmote
			end
		end
		i = i + 1
	end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

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
				sbq.setPortrait( dialoguePortraitCanvas, world.entityPortrait( speaker, dialogueTree.portrait[dialoguePos] or sbq.data.defaultPortrait ), {32,8} )
			else
				imagePortrait = ((sbq.data.portraitPath or "")..(dialogueTree.portrait[dialoguePos] or sbq.data.defaultPortrait))
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

	if type(randomDialogue) == "string" then
		local randomDialogue = sbq.generateKeysmashes(randomDialogue, dialogueTree.keysmashMin, dialogueTree.keysmashMax)
		dialogueLabel:setText(sb.replaceTags(randomDialogue, tags))
		world.sendEntityMessage(speaker, "sbqSay", randomDialogue, tags, imagePortrait, randomEmote)
		finished = true
	elseif dialogueTree.dialogue ~= nil then
		local dialogue = sbq.generateKeysmashes(dialogueTree.dialogue[dialoguePos], dialogueTree.keysmashMin, dialogueTree.keysmashMax)
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
	if not sbq.data.settings then return "hidden" end
	if not (sbq.data.settings[voreType.."Pred"] or sbq.data.settings[voreType.."PredEnable"]) then return "hidden" end
	local currentData = player.getProperty( "sbqCurrentData") or {}

	local locationName = sbq.data.sbqData.voreTypes[voreType]
	if not locationName then return "hidden" end

	local locationData = sbq.data.sbqData.locations[locationName]
	if not locationData then return "hidden" end

	local return2 = "default"

	if locationData.digest then
		return2 = "bellyEffect"
	elseif sbq.data.settings[locationName.."Effect"] ~= nil then
		return2 = locationName.."Effect"
	end

	local preyEnabled = sb.jsonMerge( sbq.config.defaultPreyEnabled.player, (status.statusProperty("sbqPreyEnabled") or {}))
	if (sbq.data.settings[voreType.."PredEnable"] or sbq.data.settings[voreType.."Pred"]) and preyEnabled.preyEnabled and preyEnabled[voreType] and ( currentData.type ~= "prey" ) then
		if sbq.data.settings[voreType.."Pred"] then
			if currentData.type == "driver" and ((not currentData.edible) or (((sbq.occupants[locationName] + 1 + currentData.totalOccupants) > locationData.max)) and not (sbq.data.settings.hammerspace and not sbq.data.settings.hammerspaceDisabled[locationName]) ) then
				return "tooBig", return2
			elseif (sbq.occupants[locationName] >= locationData.max ) then
				if sbq.actualOccupants == 0 then
					return2 = "otherLocationFull"
				end
				return "full", return2
			else
				return "yes", return2
			end
		else
			return "notFeelingIt", return2
		end
	else
		return "hidden", return2
	end
end

function sbq.checkVoreButtonsEnabled()
	for voreType, data in pairs(sbq.data.icons or {}) do
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
	local active, active2 = sbq.checkVoreTypeActive(voreType)
	if active == "yes" then
		local dialogueTree = sbq.updateDialogueBox({ "vore", voreType, "race", "personality", "mood", "request", "before", active2 }) or {}
		sbq.timer("eatMessage", dialogueTree.delay or 2, function ()
			sbq.updateDialogueBox({ "vore", voreType, "race", "personality", "mood", "request", "after", "bellyEffect"})
			world.sendEntityMessage( sbq.data.occupantHolder, "requestTransition", voreType, { id =  player.id() } )
		end)
	else
		sbq.updateDialogueBox({ "vore", voreType, "race", "personality", "mood", active, active2 })
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
			if option[2].nearEntitiesNamed ~= nil and ((option[2].voreType == nil) or ( sbq.checkVoreTypeActive(option[2].voreType) ~= "hidden" )) then
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
			elseif ((option[2].voreType == nil) or ( sbq.checkVoreTypeActive(option[2].voreType) ~= "hidden" )) then
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
