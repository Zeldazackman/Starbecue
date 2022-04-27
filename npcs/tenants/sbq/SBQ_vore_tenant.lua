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
			if type(data.sbqData.merge) == "table" then
				for i, path in ipairs(data.sbqData.merge) do
					sbq.speciesConfig.sbqData = sb.jsonMerge(root.assetJson(path).sbqData, sbq.speciesConfig.sbqData)
				end
			end
		end
		if type(data.states) == "table" then
			sbq.speciesConfig.states = data.states
			if type(data.states.merge) == "table" then
				for i, path in ipairs(data.states.merge) do
					sbq.speciesConfig.states = sb.jsonMerge(root.assetJson(path).states, sbq.speciesConfig.states)
				end
			end
		end
	end

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
	message.setHandler( "sbqOccupantHolderExists", function (_,_, occupantHolderId, occupancyData, current )

		sbq.occupantHolder = occupantHolderId
		sbq.timeUntilNewHolder = 5

		sbq.occupant = occupancyData.occupant
		sbq.occupants = occupancyData.occupants

		status.setStatusProperty( "sbqCurrentData", current)

		return {
			head = npc.getItemSlot("head"),
			chest = npc.getItemSlot("chest"),
			legs = npc.getItemSlot("legs"),
			back = npc.getItemSlot("back"),
			headCosmetic = npc.getItemSlot("headCosmetic"),
			chestCosmetic = npc.getItemSlot("chestCosmetic"),
			legsCosmetic = npc.getItemSlot("legsCosmetic"),
			backCosmetic = npc.getItemSlot("backCosmetic"),
		}
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

	if (not sbq.occupantHolder) and (sbq.timeUntilNewHolder <= 0) then
		sbq.occupantHolder = world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { spawner = entity.id(), settings = storage.settings } )
	end

	if sbq.currentData.type == nil then
		sbq.timeUntilNewHolder = math.max(0, sbq.timeUntilNewHolder - dt)
	end

	if sbq.occupantHolder ~= nil and world.entityExists(sbq.occupantHolder) then
		world.sendEntityMessage(sbq.occupantHolder, "faceDirection", mcontroller.facingDirection())
	end

	sbq.dialogueBoxOpen = math.max(0, sbq.dialogueBoxOpen - dt)

	oldupdate(dt)
end

function uninit()
	olduninit()
end

function interact(args)
	local location = sbq.getOccupantArg(args.sourceId, "location")
	local dialogueTreeStart
	if location ~= nil then
		dialogueTreeStart = { location, storage.sbqSettings.bellyEffect }
	end
	local dialogueBoxData = { dialogueTreeStart = dialogueTreeStart, sbqData = sbq.speciesConfig.sbqData, settings = storage.sbqSettings, dialogueTree = config.getParameter("dialogueTree"), icons = config.getParameter("voreIcons"), defaultPortrait = config.getParameter("defaultPortrait"), defaultName = config.getParameter("defaultName"), occupantHolder = sbq.occupantHolder }

	return {"ScriptPane", { data = dialogueBoxData, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:dialogueBox" }}
end

function sbq.getOccupantArg(id, arg)
	if sbq.occupant == nil then return end
	for i, occupant in pairs(sbq.occupant) do
		if occupant.id == id then
			return occupant[arg]
		end
	end
end
