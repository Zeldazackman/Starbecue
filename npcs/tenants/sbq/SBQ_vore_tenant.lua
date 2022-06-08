---@diagnostic disable: undefined-global

local oldinit = init
local oldupdate = update
local olduninit = uninit

sbq = {
	currentData = {},
	dialogueBoxOpen = 0,
	targetedEntities = {},
	queuedTransitions = {}
}

dialogueBoxScripts = {}

require("/scripts/SBQ_RPC_handling.lua")
require("/lib/stardust/json.lua")
require("/interface/scripted/sbq/sbqDialogueBox/sbqDialogueBoxScripts.lua")

local _npc_setItemSlot

function new_npc_setItemSlot(slot, data)
	storage.saveCosmeticSlots[slot] = data
	_npc_setItemSlot(slot, data)
	sbq.updateCosmeticSlots()
end

local _tenant_setHome = tenant.setHome
function tenant.setHome(position, boundary, deedUniqueId, skipNotification)
	if deedUniqueId and not storage.settings.dontSaveToDeed then
		sbq.timer("setHome", 0.5, function ()
			local id = world.loadUniqueEntity(deedUniqueId)
			if id and world.entityExists(id) then
				world.sendEntityMessage(id, "sbqSaveSettings", storage.settings)
				world.sendEntityMessage(id, "sbqSavePreySettings", status.statusProperty("sbqPreyEnabled") or {})
			end
		end)
	end
	_tenant_setHome(position, boundary, deedUniqueId, skipNotification)
end

function init()
	sbq.config = root.assetJson("/sbqGeneral.config")
	if type(_npc_setItemSlot) ~= "function" then
		_npc_setItemSlot = npc.setItemSlot
		npc.setItemSlot = new_npc_setItemSlot
	end

	sbq.getSpeciesConfig()

	if not storage.settings then
		storage.settings = sb.jsonMerge( sbq.config.defaultSettings, sb.jsonMerge(sbq.speciesConfig.sbqData.defaultSettings or {}, sb.jsonMerge( config.getParameter("sbqDefaultSettings") or {}, config.getParameter("sbqSettings") or {})))
	end
	if not storage.settings.firstLoadDone then
		storage.settings.firstLoadDone = true
		sbq.randomizeTenantSettings()
	end
	sbq.saveCosmeticSlots()

	sbq.setRelevantPredSettings()

	oldinit()

	sbq.dialogueTree = config.getParameter("dialogueTree")
	sbq.dialogueBoxScripts = config.getParameter("dialogueBoxScripts")
	for _, script in ipairs(sbq.dialogueBoxScripts or {}) do
		require(script)
	end

	message.setHandler("sbqRefreshDialogueBoxData", function (_,_, id, isPrey)
		sbq.talkingWithPrey = (isPrey == "prey")
		if not sbq.talkingWithPrey and type(id) == "number" then
			self.interacted = true
			self.board:setEntity("interactionSource", id)
		end
		sbq.dialogueBoxOpen = 0.5
		return { occupantHolder = sbq.occupantHolder }
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
	message.setHandler("sbqSaveSettings", function (_,_, settings)
		storage.settings = settings
		sbq.setRelevantPredSettings()
		if type(sbq.occupantHolder) == "number" and world.entityExists(sbq.occupantHolder) then
			world.sendEntityMessage(sbq.occupantHolder, "settingsMenuSet", storage.settings)
		end
	end)
	message.setHandler("sbqSavePreySettings", function (_,_, settings)
		status.setStatusProperty("sbqPreyEnabled", settings)
		if settings.digestImmunity then
			status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
		else
			status.clearPersistentEffects("digestImmunity")
		end
	end)
	message.setHandler("sbqSayRandomLine", function ( _,_, entity, settings, treestart, getVictimPreySettings )
		if getVictimPreySettings then
			sbq.addRPC(world.sendEntityMessage(entity, "sbqGetPreyEnabled" ), function (sbqPreyEnabled)
				sbq.getRandomDialogue( treestart, entity, sb.jsonMerge(storage.settings, sb.jsonMerge(sbqPreyEnabled or {}, settings or {})))
			end)
		else
			sbq.getRandomDialogue( treestart, entity, sb.jsonMerge(settings, sb.jsonMerge({personality = storage.settings.personality, mood = storage.settings.mood}, status.statusProperty("sbqPreyEnabled") or {})))
		end
	end)
	message.setHandler("requestTransition", function ( _,_, transition, args)
		if not sbq.occupantHolder then
			sbq.occupantHolder = world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { driver = entity.id(), settings = storage.settings, doExpandAnim = true } )
		end
		table.insert(sbq.queuedTransitions, {transition, args})
	end)
end

function sbq.getSpeciesConfig()
	sbq.speciesConfig = root.assetJson("/humanoid/sbqData.config")

	local species = npc.species()
	local registry = root.assetJson("/humanoid/sbqDataRegistry.config")
	local path = registry[species] or "/humanoid/sbqData.config"
	if path:sub(1,1) ~= "/" then
		path = "/humanoid/"..species.."/"..path
	end
	local speciesConfig = root.assetJson(path)
	if type(speciesConfig.sbqData) == "table" then
		sbq.speciesConfig.sbqData = speciesConfig.sbqData
	end
	if type(speciesConfig.states) == "table" then
		sbq.speciesConfig.states = speciesConfig.states
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

	sbq.sbqData = sbq.speciesConfig.sbqData

	local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}

	local effects = status.getPersistentEffects("speciesAnimOverride")
	if not effects[1] then
		status.setPersistentEffects("speciesAnimOverride", { speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride" })
	end
end

function update(dt)
	sbq.currentData = status.statusProperty("sbqCurrentData") or {}
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)

	sbq.occupantHolder = sbq.currentData.id
	sbq.loopedMessage("checkRefresh", sbq.occupantHolder, "settingsMenuRefresh", {}, function (result)
		if result ~= nil then
			sbq.occupants = result.occupants
			sbq.occupant = result.occupant
		end
	end)

	if type(sbq.occupantHolder) == "number" and world.entityExists(sbq.occupantHolder) then
		for _, transition in ipairs(sbq.queuedTransitions) do
			world.sendEntityMessage(sbq.occupantHolder, "requestTransition", transition[1], transition[2])
		end
		sbq.queuedTransitions = {}
	end

	sbq.dialogueBoxOpen = math.max(0, sbq.dialogueBoxOpen - dt)

	oldupdate(dt)
end

function uninit()
	olduninit()
end

function interact(args)
	local dialogueBoxData = { sbqData = sbq.speciesConfig.sbqData, dialogueBoxScripts = sbq.dialogueBoxScripts, settings = storage.settings, dialogueTree = sbq.dialogueTree, icons = config.getParameter("voreIcons"), entityPortrait = config.getParameter("entityPortrait"), defaultPortrait = config.getParameter("defaultPortrait"), portraitPath = config.getParameter("portraitPath"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }
	if sbq.currentData.type == "prey" then
		if args.predData then
			sbq.predData = args.predData
			local settings = args.predData.settings
			settings.location = args.predData.location
			settings.predator = args.predData.predator
			settings.isPrey = true

			settings.personality = storage.settings.personality
			settings.mood = storage.settings.mood
			settings.digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity or false

			dialogueBoxData.settings = settings
			dialogueBoxData.dialogueTreeStart = { "struggling" }
			return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
		else
			return
		end
	else
		local location = sbq.getOccupantArg(args.sourceId, "location")
		if location ~= nil then
			dialogueBoxData.dialogueTreeStart = { "struggle" }
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
	settings.race = npc.species()
	local dialogueTree = sbq.getDialogueBranch(dialogueTreeLocation, settings)
	if not dialogueTree then return false end
	recursionCount = 0 -- since we successfully made it here, reset the recursion count

	local randomRolls = {}
	local randomDialogue = dialogueTree.randomDialogue
	local randomPortrait = dialogueTree.randomPortrait
	local randomEmote = dialogueTree.randomEmote

	randomRolls, randomDialogue		= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomDialogue, "randomDialogue")
	randomRolls, randomPortrait		= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomPortrait, "randomPortrait")
	randomRolls, randomEmote		= sbq.getRandomDialogueTreeValue(settings, randomRolls, randomEmote, "randomEmote")

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
	if type(string) == "string" and string ~= "" then
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
	local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}

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
	if storage.settings.breasts or storage.settings.penis or storage.settings.balls or storage.settings.pussy
	or storage.settings.bra or storage.settings.underwear
	then
		local effects = status.getPersistentEffects("speciesAnimOverride")
		if not effects[1] then
			status.setPersistentEffects("speciesAnimOverride", { speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride" })
		end
		sbq.timer("setOverrideSettings", 0.5, function ()
			if storage.settings.penis then
				if storage.settings.underwear then
					sbq.setStatusValue( "cockVisible", "?crop;0;0;0;0")
				else
					sbq.setStatusValue( "cockVisible", "")
				end
			else
				sbq.setStatusValue( "cockVisible", "?crop;0;0;0;0")
			end
			if storage.settings.balls then
				if storage.settings.underwear then
					sbq.setStatusValue( "ballsVisible", "?crop;0;0;0;0")
				else
					sbq.setStatusValue( "ballsVisible", "")
				end
			else
				sbq.setStatusValue( "ballsVisible", "?crop;0;0;0;0")
			end
			if storage.settings.breasts then
				sbq.setStatusValue( "breastsVisible", "")
			else
				sbq.setStatusValue( "breastsVisible", "?crop;0;0;0;0")
			end
			if storage.settings.pussy then
				sbq.setStatusValue( "pussyVisible", "")
			else
				sbq.setStatusValue( "pussyVisible", "?crop;0;0;0;0")
			end
			sbq.handleUnderwear()
		end)
	elseif not sbq.occupantHolder and not speciesAnimOverrideData.permanent then
		status.clearPersistentEffects("speciesAnimOverride")
	end
	sbq.updateCosmeticSlots()
end

function sbq.handleUnderwear()
	world.sendEntityMessage(entity.id(), "sbqEnableUnderwear", storage.settings.underwear)
	world.sendEntityMessage(entity.id(), "sbqEnableBra", storage.settings.bra)
end

function sbq.setStatusValue(name, value)
	world.sendEntityMessage(entity.id(), "sbqSetStatusValue", name, value)
end

function sbq.updateCosmeticSlots()
	if type(storage.settings) == "table" then
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
