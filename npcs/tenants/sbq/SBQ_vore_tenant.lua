local oldinit = init
local oldupdate = update
local olduninit = uninit

sbq = {
	currentData = {},
	timeUntilNewHolder = 0,
	dialogueBoxOpen = 0
}

require("/scripts/SBQ_RPC_handling.lua")


function init()
	oldinit()
	sbq.config = root.assetJson("/sbqGeneral.config")
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
		return { dialogueTreeStart = dialogueTreeStart, sbqData = sbq.speciesConfig.sbqData, settings = storage.sbqSettings, dialogueTree = config.getParameter("dialogueTree"), icons = config.getParameter("voreIcons"), defaultPortrait = config.getParameter("defaultPortrait"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }
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
end

function update(dt)
	sbq.currentData = status.statusProperty("sbqCurrentData") or {}
	sbq.checkRPCsFinished(dt)
	sbq.occupantHolder = sbq.currentData.id

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
	local dialogueBoxData = { sbqData = sbq.speciesConfig.sbqData, settings = storage.sbqSettings, dialogueTree = config.getParameter("dialogueTree"), icons = config.getParameter("voreIcons"), defaultPortrait = config.getParameter("defaultPortrait"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }

	sb.logInfo(sb.printJson(args))
	if sbq.currentData.type == "prey" then
		if args.predData then
			sbq.predData = args.predData
			local settings = args.predData.settings
			settings.location = args.predData.location
			settings.predator = args.predData.predator
			settings.predEnabled = storage.sbqSettings.predEnabled

			settings.personality = storage.sbqSettings.personality or "default"
			settings.mood = storage.sbqSettings.mood or "neutral"
			settings.digestionImmunity = status.statusProperty("sbqPreyEnabled").digestionImmunity or false

			dialogueBoxData.settings = settings
			dialogueBoxData.dialogueTreeStart = { "prey", "location", "predator", "bellyEffect", "digestionImmunity" }
			return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
		else
			return
		end
	else
		local location = sbq.getOccupantArg(args.sourceId, "location")
		if location ~= nil then
			dialogueBoxData.dialogueTreeStart = { location, storage.sbqSettings.bellyEffect }
		end
		return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
	end
end

function sbq.preyDialogue()


end

function sbq.getOccupantArg(id, arg)
	if sbq.occupant == nil then return end
	for i, occupant in pairs(sbq.occupant) do
		if occupant.id == id then
			return occupant[arg]
		end
	end
end
