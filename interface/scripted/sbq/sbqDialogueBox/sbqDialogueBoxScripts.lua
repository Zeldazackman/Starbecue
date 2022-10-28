---@diagnostic disable: undefined-global

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

function sbq.getDialogueBranch(dialogueTreeLocation, settings, dialogueTree)
	local dialogueTree = sbq.getRedirectedDialogue(dialogueTree or sbq.dialogueTree, settings) or {}

	for _, branch in ipairs(dialogueTreeLocation) do
		dialogueTree = sbq.checkDialogueBranch(dialogueTree, settings, branch)
	end

	local continue = true
	while continue and type(dialogueTree) == "table" do
		continue = false
		local nextType = type(dialogueTree.next)
		sb.logInfo(tostring(dialogueTree.next))
		if nextType == "string" then
			dialogueTree = sbq.checkDialogueBranch(dialogueTree, settings, dialogueTree.next)
			continue = true
		elseif nextType == "table" then
			dialogueTree = sbq.checkDialogueBranch(dialogueTree, settings, dialogueTree.next[math.random(#dialogueTree.next)])
			continue = true
		end
	end

	return dialogueTree
end

function sbq.checkDialogueBranch(dialogueTree, settings, branch)
	local dialogueTree = dialogueTree
	if type(dialogueTree) == "table" then
		if type(dialogueBoxScripts[branch]) == "function" then
			dialogueTree = dialogueBoxScripts[branch](dialogueTree, settings, branch)
		elseif settings[branch] ~= nil then
			dialogueTree = dialogueTree[tostring(settings[branch])] or dialogueTree[branch] or dialogueTree.default
		else
			dialogueTree = dialogueTree[branch]
		end
	end
	return sbq.getRedirectedDialogue(dialogueTree, settings)
end

local recursionCount = 0
-- for dialog in other files thats been pointed to
function sbq.getRedirectedDialogue(dialogueTree, settings)
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
			dialogueTree = sbq.getDialogueBranch(jump, settings)
		end
	end
	return dialogueTree or {}
end

function sbq.getRandomDialogueTreeValue(settings, randomRolls, randomTable, name)
	local randomRolls = randomRolls
	local randomTable = randomTable
	local i = 1
	local prevTable
	while type(randomTable) == "table" do
		if randomTable.add then
			if randomTable.check then
				if sbq.checkSettings(randomTable.check, settings) then
					if type(randomTable.add) == "string" then
						randomTable = sbq.getRedirectedDialogue(randomTable.add, settings)[name]
					else
						randomTable = randomTable.add
					end
				else
					i = i - 1
					randomRolls[i] = nil -- clear the saved random value so it chooses a different one next round
					randomTable = prevTable
				end
			else
				if type((randomTable or {}).add) == "string" then
					randomTable = sbq.getRedirectedDialogue((randomTable or {}).add, settings)[name]
				else
					randomTable = (randomTable or {}).add
				end
			end
		else
			if randomRolls[i] == nil then
				table.insert(randomRolls, math.random(#randomTable))
			end
			prevTable = randomTable
			randomTable = randomTable[randomRolls[i]] or randomTable[1]
			i = i + 1
		end
	end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count
	return randomRolls, randomTable
end

function sbq.checkSettings(checkSettings, settings)
	for setting, value in pairs(checkSettings) do
		if type(value) == "table" then
			local match = false
			for i, value in ipairs(value) do if (settings[setting] or false) == value then
				match = true
				break
			end end
			if not match then return false end
		elseif (settings[setting] or false) ~= value then return false
		end
	end
	return true
end


function dialogueBoxScripts.getLocationEffect(dialogueTree, settings, branch)
	local dialogueTree = dialogueTree
	local options = {}
	local effect = settings[settings.location.."Effect"]
	if settings.digested then
		return dialogueTree.digested or dialogueTree.default
	end

	if settings.cumDigesting or settings.digesting then
		effect = ((settings.locationsData[settings.location] or {}).digest).effect or "sbqDigest"
	end
	table.insert(options, effect or "default")

	if settings[settings.location.."Compression"] then
		table.insert(options, settings.location.."Compression")
	end
	if settings.transformed and dialogueTree.transformed then
		table.insert(options, "transformed")
	elseif not settings.transformed and settings.progressBarType == "transforming" and dialogueTree.transform then
		table.insert(options, "transform")
	end
	if settings.egged and dialogueTree.egged then
		table.insert(options, "egged")
	elseif not settings.egged and settings.progressBarType == "eggifying" and dialogueTree.eggify then
		table.insert(options, "eggify")
	end

	return dialogueTree[options[math.random(#options)]] or dialogueTree.default
end

function dialogueBoxScripts.locationEffect(dialogueTree, settings, branch)
	local dialogueTree = dialogueTree
	local effect = settings[settings.location.."Effect"]
	if settings.digested then
		return dialogueTree.digested or dialogueTree.default
	end
	if settings.cumDigesting or settings.digesting then
		effect = ((settings.locationsData[settings.location] or {}).digest).effect or "sbqDigest"
	end

	return dialogueTree[effect] or dialogueTree.default
end

function dialogueBoxScripts.digestImmunity(dialogueTree, settings, branch)
	if settings.digestImmunity and (settings.allowSoftDigest and settings[settings.location.."Effect"] == "sbqSoftDigest") then
		return dialogueTree["false"] or dialogueTree.default
	elseif settings.digestImmunity then
		return dialogueTree["true"] or dialogueTree.default
	else
		return dialogueTree["false"] or dialogueTree.default
	end
end

function dialogueBoxScripts.cumDigestImmunity(dialogueTree, settings, branch)
	if settings.cumDigestImmunity and (settings.allowCumSoftDigest and settings[settings.location.."Effect"] == "sbqCumSoftDigest") then
		return dialogueTree["false"] or dialogueTree.default
	elseif settings.cumDigestImmunity then
		return dialogueTree["true"] or dialogueTree.default
	else
		return dialogueTree["false"] or dialogueTree.default
	end
end

function dialogueBoxScripts.femcumDigestImmunity(dialogueTree, settings, branch)
	if settings.femcumDigestImmunity and (settings.allowFemcumSoftDigest and settings[settings.location.."Effect"] == "sbqFemcumSoftDigest") then
		return dialogueTree["false"] or dialogueTree.default
	elseif settings.femcumDigestImmunity then
		return dialogueTree["true"] or dialogueTree.default
	else
		return dialogueTree["false"] or dialogueTree.default
	end
end

function dialogueBoxScripts.milkDigestImmunity(dialogueTree, settings, branch)
	if settings.milkDigestImmunity and (settings.allowMilkSoftDigest and settings[settings.location.."Effect"] == "sbqMilkSoftDigest") then
		return dialogueTree["false"] or dialogueTree.default
	elseif settings.milkDigestImmunity then
		return dialogueTree["true"] or dialogueTree.default
	else
		return dialogueTree["false"] or dialogueTree.default
	end
end

function dialogueBoxScripts.openNewDialogueBox(dialogueTree, settings, branch, ...)
	player.interact("ScriptPane", { data = sb.jsonMerge(metagui.inputData, dialogueTree.inputData), gui = { }, scripts = {"/metagui.lua"}, ui = dialogueTree.ui }, pane.sourceEntity())
	pane.dismiss()
end
