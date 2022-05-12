---@diagnostic disable: undefined-global

local oldinit = init
local oldupdate = update
local olduninit = uninit

sbq = {
	currentData = {},
	timeUntilNewHolder = 1,
	dialogueBoxOpen = 0,
	targetedEntities = {}
}

require("/scripts/SBQ_RPC_handling.lua")
require( "/lib/stardust/json.lua" )

local _npc_setItemSlot

function new_npc_setItemSlot(slot, data)
	storage.saveCosmeticSlots[slot] = data
	_npc_setItemSlot(slot, data)
	sbq.updateCosmeticSlots()
end

local _tenant_setHome = tenant.setHome
function tenant.setHome(position, boundary, deedUniqueId, skipNotification)
	if deedUniqueId and not storage.settings.dontSaveToDeed then
		local id = world.loadUniqueEntity(deedUniqueId)
		if id and world.entityExists(id) then
			world.sendEntityMessage(id, "sbqSaveSettings", storage.settings)
			world.sendEntityMessage(id, "sbqSavePreySettings", status.statusProperty("sbqPreyEnabled") or {})
		end
	end
	_tenant_setHome(position, boundary, deedUniqueId, skipNotification)
end

function init()
	sbq.saveCosmeticSlots()
	_npc_setItemSlot = npc.setItemSlot
	npc.setItemSlot = new_npc_setItemSlot

	oldinit()

	sbq.config = root.assetJson("/sbqGeneral.config")
	sbq.dialogueTree = config.getParameter("dialogueTree")

	sbq.getSpeciesConfig()

	if not storage.settings then
		storage.settings = sb.jsonMerge( sbq.config.defaultSettings, sb.jsonMerge(sbq.speciesConfig.sbqData.defaultSettings or {}, sb.jsonMerge( config.getParameter("sbqDefaultSettings") or {}, config.getParameter("sbqSettings") or {})))
	end
	if not storage.settings.firstLoadDone then
		storage.settings.firstLoadDone = true
		sbq.randomizeTenantSettings()
	end
	sbq.setRelevantPredSettings()

	message.setHandler("sbqRefreshDialogueBoxData", function (_,_, id, isPrey)
		sbq.talkingWithPrey = (isPrey == "prey")
		if not sbq.talkingWithPrey and type(id) == "number" then
			self.interacted = true
			self.board:setEntity("interactionSource", id)
		end
		sbq.dialogueBoxOpen = 0.5
		return { settings = storage.settings, occupantHolder = sbq.occupantHolder }
	end)
	message.setHandler("sbqSay", function (_,_, string, tags, imagePortrait, emote)
		sbq.say(string, tags, imagePortrait, emote)
	end)
	message.setHandler("sbqSetInteracted", function (_,_, id)
		self.interacted = true
		self.board:setEntity("interactionSource", id)
	end)
	message.setHandler("sbqGetSpeciesVoreConfig", function (_,_)
		sbq.getSpeciesConfig()
		return sbq.speciesConfig
	end)
	message.setHandler("sbqPredatorSpeak", function (_,_, entity, location )
		sbq.addRPC(world.sendEntityMessage(entity, "sbqIsPreyEnabled", "digestionImmunity"), function (immune)
			local effect = "default"
			if sbq.speciesConfig.sbqData.locations[location].digest then
				effect = "bellyEffect"
			elseif storage.settings[location.."Effect"] ~= nil then
				effect = location.."Effect"
			end
			sbq.getRandomDialogue({ "pred", "location", "race", "personality", "mood", effect or "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(storage.settings, {location = location, digestionImmunity = immune or false}))
		end)
	end)
	message.setHandler("sbqStrugglerSpeak", function (_,_, entity, location, settings, predator, effect)
		sbq.getRandomDialogue({ "prey", "location", "predator", "race", "personality", "mood", effect or "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(settings, {location = location, predator = predator, digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity, personality = storage.settings.personality, mood = storage.settings.mood}))
	end)
	message.setHandler("sbqVoredSpeak", function (_,_, entity, voreType, settings, predator, effect)
		sbq.getRandomDialogue({ "vored", "voreType", "predator", "race", "personality", "mood", effect or "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(settings, {voreType = voreType, predator = predator, digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity, personality = storage.settings.personality, mood = storage.settings.mood}))
	end)
	message.setHandler("sbqLetoutSpeak", function (_,_, entity, voreType, effect, struggleTrigger)
		sbq.addRPC(world.sendEntityMessage(entity, "sbqIsPreyEnabled", "digestionImmunity"), function (immune)
			sbq.getRandomDialogue({ "letout", "voreType", "struggleTrigger", "race", "personality", "mood", effect or "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(storage.settings, {voreType = voreType, digestionImmunity = immune or false, struggleTrigger = struggleTrigger or false}))
		end)
	end)
	message.setHandler("sbqEscapeSpeak", function (_,_, entity, voreType, settings, predator, effect, struggleTrigger)
		sbq.getRandomDialogue({ "escape", "voreType", "predator", "struggleTrigger", "race", "personality", "mood", effect or "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(settings, {voreType = voreType, predator = predator, digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity, personality = storage.settings.personality, mood = storage.settings.mood, struggleTrigger = struggleTrigger or false}))
	end)
	message.setHandler("sbqSaveSettings", function (_,_, settings)
		storage.settings = settings
		sbq.setRelevantPredSettings()
		world.sendEntityMessage(sbq.occupantHolder, "settingsMenuSet", storage.settings)
	end)
	message.setHandler("sbqSavePreySettings", function (_,_, settings)
		status.setStatusProperty("sbqPreyEnabled", settings)
		if sbqPreyEnabled.digestImmunity then
			status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
		else
			status.clearPersistentEffects("digestImmunity")
		end
	end)
end

function sbq.getSpeciesConfig()
	sbq.speciesConfig = root.assetJson("/humanoid/sbqData.config")

	local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}
	local species = speciesAnimOverrideData.species or npc.species()
	local success, data = pcall(root.assetJson, "/humanoid/"..species.."/sbqData.config")
	if success then
		if type(data.sbqData) == "table" then
			sbq.speciesConfig.sbqData = data.sbqData
		end
		if type(data.states) == "table" then
			sbq.speciesConfig.states = data.states
		end
	end
	sbq.speciesConfig.species = species
	local mergeConfigs = sbq.speciesConfig.sbqData.merge or {}
	local configs = { sbq.speciesConfig.sbqData }
	while type(mergeConfigs[#mergeConfigs]) == "string" do
		local insertPos = #mergeConfigs
		local newConfig = root.assetJson(mergeConfigs[#mergeConfigs]).sbqData
		for i = #(newConfig.merge or {}), 1, -1 do
			table.insert(mergeConfigs, insertPos, newConfig.merge[i])
		end

		table.insert(configs, 1, newConfig)

		table.remove(mergeConfigs, #mergeConfigs)
	end
	local scripts = {}
	local finalConfig = {}
	for i, config in ipairs(configs) do
		finalConfig = sb.jsonMerge(finalConfig, config)
		for j, script in ipairs(config.scripts or {}) do
			table.insert(scripts, script)
		end
	end
	sbq.speciesConfig.sbqData = finalConfig
	sbq.speciesConfig.sbqData.scripts = scripts

	local mergeConfigs = sbq.speciesConfig.states.merge or {}
	local configs = { sbq.speciesConfig.states }
	while type(mergeConfigs[#mergeConfigs]) == "string" do
		local insertPos = #mergeConfigs
		local newConfig = root.assetJson(mergeConfigs[#mergeConfigs]).states
		for i = #(newConfig.merge or {}), 1, -1 do
			table.insert(mergeConfigs, insertPos, newConfig.merge[i])
		end

		table.insert(configs, 1, newConfig)

		table.remove(mergeConfigs, #mergeConfigs)
	end
	local finalConfig = {}
	for i, config in ipairs(configs) do
		finalConfig = sb.jsonMerge(finalConfig, config)
	end
	sbq.speciesConfig.states = finalConfig
end

function update(dt)
	sbq.currentData = status.statusProperty("sbqCurrentData") or {}
	sbq.checkRPCsFinished(dt)
	sbq.occupantHolder = sbq.currentData.id
	sbq.loopedMessage("checkRefresh", sbq.occupantHolder, "settingsMenuRefresh", {}, function (result)
		if result ~= nil then
			sbq.occupants = result.occupants
			sbq.occupant = result.occupant
		end
	end)


	if (not sbq.occupantHolder) and (sbq.timeUntilNewHolder <= 0) then
		sbq.occupantHolder = world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { driver = entity.id(), settings = storage.settings } )
		sbq.timeUntilNewHolder = 5
	end

	if sbq.currentData.type == nil then
		sbq.timeUntilNewHolder = math.max(0, sbq.timeUntilNewHolder - dt)
	else
		sbq.timeUntilNewHolder = 5
	end

	sbq.dialogueBoxOpen = math.max(0, sbq.dialogueBoxOpen - dt)

	oldupdate(dt)
end

function uninit()
	olduninit()
end

function interact(args)
	local dialogueBoxData = { sbqData = sbq.speciesConfig.sbqData, settings = storage.settings, dialogueTree = sbq.dialogueTree, icons = config.getParameter("voreIcons"), entityPortrait = config.getParameter("entityPortrait"), defaultPortrait = config.getParameter("defaultPortrait"), portraitPath = config.getParameter("portraitPath"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }
	if sbq.currentData.type == "prey" then
		if args.predData then
			sbq.predData = args.predData
			local settings = args.predData.settings
			settings.location = args.predData.location
			settings.predator = args.predData.predator

			settings.personality = storage.settings.personality
			settings.mood = storage.settings.mood
			settings.digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity or false

			dialogueBoxData.settings = settings
			dialogueBoxData.dialogueTreeStart = { "prey", "location", "predator", "race", "personality", "mood", "bellyEffect", "digestionImmunity" }
			return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
		else
			return
		end
	else
		local location = sbq.getOccupantArg(args.sourceId, "location")
		if location ~= nil then
			dialogueBoxData.dialogueTreeStart = { "pred", "location", "race", "personality", "mood", "bellyEffect", "digestionImmunity" }
			dialogueBoxData.settings.location = location
		end
		return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
	end
end

function sbq.getOccupantArg(id, arg)
	if sbq.occupant == nil then return end
	for i, occupant in pairs(sbq.occupant) do
		if occupant.id == id then
			return occupant[arg]
		end
	end
end

function sbq.getRandomDialogue(dialogueTreeLocation, entity, settings)
	local dialogueTree = sbq.getDialogueBranch(dialogueTreeLocation, settings)
	if not dialogueTree then return false end
	local randomRolls = {}
	local randomDialogue = dialogueTree.randomDialogue
	local randomPortrait = dialogueTree.randomPortrait
	local randomEmote = dialogueTree.randomEmote

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
	while type(randomEmote) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomEmote))
		end
		randomEmote = randomEmote[randomRolls[i]]
		i = i + 1
	end

	local imagePortrait
	if not config.getParameter("entityPortrait") then
		imagePortrait = ((config.getParameter("portraitPath") or "")..(randomPortrait or config.getParameter("defaultPortrait")))
	end

	local playerName

	if type(entity) == "number" then
		playerName = world.entityName(entity)
	end

	local tags = { entityname = playerName }

	if type(randomDialogue) == "string" then
		sbq.say( sbq.generateKeysmashes(randomDialogue, dialogueTree.keysmashMin, dialogueTree.keysmashMax), tags, imagePortrait, randomEmote )
	end
end

function sbq.say(string, tags, imagePortrait, emote)
	if type(string) == "string" then
		if type(imagePortrait) == "string" and config.getParameter("sayPortrait") then
			npc.sayPortrait(string, imagePortrait, tags)
		else
			npc.say(string, tags)
		end
		if type(emote) == "string" then
			npc.emote(emote)
		end
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

function sbq.getDialogueBranch(dialogueTreeLocation, settings)
	local dialogueTree = sbq.getRedirectedDialogue(sbq.dialogueTree) or {}

	for _, branch in ipairs(dialogueTreeLocation) do
		if settings[branch] ~= nil then
			dialogueTree =  dialogueTree[tostring(settings[branch])] or dialogueTree.default or dialogueTree
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


function sbq.saveCosmeticSlots()
	if not storage.saveCosmeticSlots then
		storage.saveCosmeticSlots = {}
		local slots = { "headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic" }
		for i, slot in ipairs(slots) do
			storage.saveCosmeticSlots[slot] = npc.getItemSlot(slot)
		end
	end
end

function sbq.randomizeTenantSettings()
	local randomizeSettings = config.getParameter("sbqRandomizeSettings") or {}
	for setting, values in pairs(randomizeSettings) do
		storage.settings[setting] = values[math.random(#values)]
	end
	local randomizePreySettings = config.getParameter("sbqRandomizePreySettings") or {}
	local preySettings = status.statusProperty("sbqPreyEnabled") or {}
	for setting, values in pairs(randomizePreySettings) do
		preySettings[setting] = values[math.random(#values)]
	end
	status.setStatusProperty("sbqPreyEnabled", preySettings)
	if preySettings.digestImmunity then
		status.setPersistentEffects("digestImmunity", { "sbqDigestImmunity" })
	else
		status.clearPersistentEffects("digestImmunity")
	end
end

function sbq.setRelevantPredSettings()
	if storage.settings.unbirthPred or storage.settings.unbirthPredEnable then
		storage.settings.pussy = true
	else
		storage.settings.pussy = false
	end
	if storage.settings.cockVorePred or storage.settings.cockVorePredEnable then
		storage.settings.penis = true
		storage.settings.balls = true
	else
		storage.settings.penis = false
		storage.settings.balls = false
	end
	if storage.settings.navelVorePred or storage.settings.navelVorePredEnable then
		storage.settings.navel = true
	else
		storage.settings.navel = false
	end
	if storage.settings.breastVorePred or storage.settings.breastVorePredEnable then
		storage.settings.breasts = true
	else
		storage.settings.breasts = false
	end
	sbq.updateCosmeticSlots()
end

function sbq.updateCosmeticSlots()
	if storage.settings.breastVorePred then
		_npc_setItemSlot("chestCosmetic", "sbq_nude_chest")
	else
		_npc_setItemSlot("chestCosmetic", storage.saveCosmeticSlots.chestCosmetic)
	end

	if storage.settings.unbirthPred or storage.settings.cockVorePred or storage.settings.analVorePred then
		_npc_setItemSlot("legsCosmetic", "sbq_nude_legs")
	else
		_npc_setItemSlot("legsCosmetic", storage.saveCosmeticSlots.legsCosmetic)
	end
end

function sbq.searchForValidPrey(voreType)
	local players = world.playerQuery(mcontroller.position(), 50)
	local npcs = world.npcQuery(mcontroller.position(), 50, { withoutEntityId = npc.id() })
	local monsters = world.monsterQuery(mcontroller.position(), 50)

	if storage.settings.huntFriendlyPlayers or storage.settings.huntHostilePlayers then
		for i, entity in ipairs(players) do
			sbq.addRPC(world.sendEntityMessage(entity, "sbqIsPreyEnabled", voreType), function (enabled)
				if enabled then
					table.insert(sbq.targetedEntities, {entity, voreType})
				end
			end)
		end
	end
	if storage.settings.huntHostileNPCs or storage.settings.huntFriendlyNPCs then
		for i, entity in ipairs(npcs) do
			sbq.addRPC(world.sendEntityMessage(entity, "sbqIsPreyEnabled", voreType), function (enabled)
				if enabled then
					table.insert(sbq.targetedEntities, {entity, voreType})
				end
			end)
		end
	end
	if storage.settings.huntHostileMonsters or storage.settings.huntFriendlyMonsters then
		for i, entity in ipairs(monsters) do
			sbq.addRPC(world.sendEntityMessage(entity, "sbqIsPreyEnabled", voreType), function (enabled)
				if enabled then
					table.insert(sbq.targetedEntities, {entity, voreType})
				end
			end)
		end
	end


end

function sbq.searchForValidPred(setting)

end
