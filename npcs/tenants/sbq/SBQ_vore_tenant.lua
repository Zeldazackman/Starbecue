---@diagnostic disable: undefined-global

local oldinit = init
local oldupdate = update
local olduninit = uninit

sbq = {
	currentData = {},
	timeUntilNewHolder = 0,
	dialogueBoxOpen = 0
}

require("/scripts/SBQ_RPC_handling.lua")
require( "/lib/stardust/json.lua" )


function init()
	oldinit()
	sbq.config = root.assetJson("/sbqGeneral.config")
	sbq.speciesConfig = root.assetJson("/humanoid/sbqData.config")
	sbq.dialogueTree = config.getParameter("dialogueTree")


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

	storage.sbqSettings = sb.jsonMerge( sbq.config.defaultSettings, sb.jsonMerge(sbq.speciesConfig.sbqData.defaultSettings or {}, sb.jsonMerge( config.getParameter("sbqDefaultSettings") or {}, storage.sbqSettings or {})))

	message.setHandler("sbqGetDialogueBoxData", function (_,_, id)
		local location = sbq.getOccupantArg(id, "location")
		local dialogueTreeStart
		if location ~= nil then
			dialogueTreeStart = { location, storage.sbqSettings.bellyEffect }
		end
		return { dialogueTreeStart = dialogueTreeStart, sbqData = sbq.speciesConfig.sbqData, settings = storage.sbqSettings, dialogueTree = sbq.dialogueTree, icons = config.getParameter("voreIcons"), defaultPortrait = config.getParameter("defaultPortrait"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }
	end)
	message.setHandler("sbqRefreshDialogueBoxData", function (_,_, id, isPrey)
		sbq.talkingWithPrey = (isPrey == "prey")
		if not sbq.talkingWithPrey and type(id) == "number" then
			self.interacted = true
			self.board:setEntity("interactionSource", id)
		end
		sbq.dialogueBoxOpen = 0.5
		return { settings = storage.sbqSettings, occupantHolder = sbq.occupantHolder }
	end)
	message.setHandler("sbqSay", function (_,_, string, tags)
		npc.say(string, tags)
	end)
	message.setHandler( "sbqPredatorDespawned", function (_,_)
		sbq.occupantHolder = nil
		status.setStatusProperty( "sbqCurrentData", nil)
	end)
	message.setHandler("sbqSetInteracted", function (_,_, id)
		self.interacted = true
		self.board:setEntity("interactionSource", id)
	end)
	message.setHandler("sbqGetSpeciesVoreConfig", function (_,_)
		return sbq.speciesConfig
	end)
	message.setHandler("sbqPredatorSpeak", function (_,_, entity, location, settings, predator)
		sb.logInfo("got the message")
		sbq.addRPC(world.sendEntityMessage(entity, "sbqIsPreyEnabled", "digestionImmunity"), function (immune)
			sb.logInfo("got here")
			sbq.getRandomDialogue({ "pred", "location", "personality", "mood", "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(storage.sbqSettings, {location = location, digestionImmunity = immune}))
		end)
	end)
	message.setHandler("sbqStrugglerSpeak", function (_,_, entity, location, settings, predator)
		sbq.getRandomDialogue({ "prey", "location", "predator", "personality", "mood", "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(settings, {location = location, predator = predator, digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity, personality = storage.sbqSettings.personality, mood = storage.sbqSettings.mood}))
	end)
	message.setHandler("sbqVoredSpeak", function (_,_, entity, voreType, settings, predator)
		sbq.getRandomDialogue({ "vored", "voreType", "predator", "personality", "mood", "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(settings, {voreType = voreType, predator = predator, digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity, personality = storage.sbqSettings.personality, mood = storage.sbqSettings.mood}))
	end)
	message.setHandler("sbqEscapeSpeak", function (_,_, entity, voreType, settings, predator)
		sbq.getRandomDialogue({ "escape", "voreType", "predator", "personality", "mood", "bellyEffect", "digestionImmunity" }, entity, sb.jsonMerge(settings, {voreType = voreType, predator = predator, digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity, personality = storage.sbqSettings.personality, mood = storage.sbqSettings.mood}))
	end)


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
	end )


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
	local dialogueBoxData = { sbqData = sbq.speciesConfig.sbqData, settings = storage.sbqSettings, dialogueTree = sbq.dialogueTree, icons = config.getParameter("voreIcons"), defaultPortrait = config.getParameter("defaultPortrait"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }
	if sbq.currentData.type == "prey" then
		if args.predData then
			sbq.predData = args.predData
			local settings = args.predData.settings
			settings.location = args.predData.location
			settings.predator = args.predData.predator

			settings.personality = storage.sbqSettings.personality
			settings.mood = storage.sbqSettings.mood
			settings.digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity or false

			dialogueBoxData.settings = settings
			dialogueBoxData.dialogueTreeStart = { "prey", "location", "predator", "personality", "mood", "bellyEffect", "digestionImmunity" }
			return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
		else
			return
		end
	else
		local location = sbq.getOccupantArg(args.sourceId, "location")
		if location ~= nil then
			dialogueBoxData.dialogueTreeStart = { "pred", "location", "personality", "mood", "bellyEffect", "digestionImmunity" }
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
	sb.logInfo(sb.printJson(dialogueTreeLocation))
	local dialogueTree = sbq.getDialogueBranch(dialogueTreeLocation, settings)
	sb.logInfo(sb.printJson(dialogueTree))
	if not dialogueTree then return false end
	local randomRolls = {}
	local randomDialogue = dialogueTree.randomDialogue
	local i = 1
	while type(randomDialogue) == "table" do
		if randomRolls[i] == nil then
			table.insert(randomRolls, math.random(#randomDialogue))
		end
		randomDialogue = randomDialogue[randomRolls[i]]
		i = i + 1
	end
	local playerName

	if type(entity) == "number" then
		playerName = world.entityName(entity)
	end

	local tags = { entityname = playerName }

	if type(randomDialogue) == "string" then
		npc.say( randomDialogue, tags )
	end
end

function sbq.getDialogueBranch(dialogueTreeLocation, settings)
	local dialogueTree = sbq.dialogueTree
	for _, branch in ipairs(dialogueTreeLocation) do
		if settings[branch] ~= nil then
			dialogueTree =  dialogueTree[tostring(settings[branch])] or dialogueTree.default or dialogueTree
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
