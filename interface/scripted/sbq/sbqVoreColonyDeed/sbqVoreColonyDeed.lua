---@diagnostic disable: undefined-global
sbq = {
	config = root.assetJson("/sbqGeneral.config"),
	tenantCatalogue = root.assetJson("/npcs/tenants/sbqTenantCatalogue.json"),
	extraTabs = root.assetJson("/interface/scripted/sbq/sbqSettings/sbqSettingsTabs.json"),
	tenantIndex = 1,
	deedUI = true
}

require("/scripts/SBQ_RPC_handling.lua")
require("/interface/scripted/sbq/sbqSettings/sbqSettingsLocationPanel.lua")
require("/interface/scripted/sbq/sbqSettings/sbqSettingsEffectsPanel.lua")
require("/scripts/SBQ_species_config.lua")

function init()
	sbq.storage = metagui.inputData

	local occupier = sbq.storage.occupier

	if type(occupier) == "table" and type(occupier.tenants) == "table" and type(occupier.tenants[sbq.tenantIndex]) == "table" and type(occupier.tenants[sbq.tenantIndex].species) == "string" then
		sbq.tenant = occupier.tenants[sbq.tenantIndex]

		sbq.npcConfig = root.npcConfig(sbq.tenant.type)
		sbq.overrideSettings = sbq.npcConfig.scriptConfig.sbqOverrideSettings or {}
		sbq.overridePreyEnabled = sbq.npcConfig.scriptConfig.sbqOverridePreyEnabled or {}

		sbq.predatorSettings = sb.jsonMerge( sb.jsonMerge(sbq.config.defaultSettings, sbq.config.tenantDefaultSettings),
			sb.jsonMerge( sbq.npcConfig.scriptConfig.sbqDefaultSettings or {},
				sb.jsonMerge( sbq.tenant.overrides.scriptConfig.sbqSettings or {}, sbq.overrideSettings)
			)
		)
		sbq.preySettings = sb.jsonMerge( sbq.config.defaultPreyEnabled.player,
			sb.jsonMerge(((sbq.tenant.overrides.statusControllerSettings or {}).statusProperties or {}).sbqPreyEnabled or {}, sbq.overridePreyEnabled or {})
		)
		sbq.animOverrideSettings = ((sbq.tenant.overrides.statusControllerSettings or {}).statusProperties or {}).speciesAnimOverrideSettings or {}
		sbq.animOverrideSettings.scale = ((sbq.tenant.overrides.statusControllerSettings or {}).statusProperties or {}).animOverrideScale or 1
		sbq.animOverrideOverrideSettings = ((sbq.tenant.overrides.statusControllerSettings or {}).statusProperties or {}).speciesAnimOverrideOverrideSettings or {}

		sbq.globalSettings = sbq.predatorSettings
		escapeValue:setText(tostring(sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty or 0))
		escapeValueMin:setText(tostring(sbq.overrideSettings.escapeDifficultyMin or sbq.predatorSettings.escapeDifficultyMin or 0))
		escapeValueMax:setText(tostring(sbq.overrideSettings.escapeDifficultyMax or sbq.predatorSettings.escapeDifficultyMax or 0))

		personalityText:setText(sbq.predatorSettings.personality or "default")
		moodText:setText(sbq.predatorSettings.mood or "default")

		tenantNote:setVisible(occupier.tenantNote ~= nil)
		tenantNote.toolTip = occupier.tenantNote

		orderFurniture:setVisible(occupier.orderFurniture ~= nil)

		tenantText:setText( occupier.name or "")
		local tags = sbq.storage.house.contents
		local listed = { sbqVore = true }
		for tag, value in pairs(occupier.tagCriteria or {}) do
			if tag ~= "sbqVore" then
				listed[tag] = true
				local amount = tags[tag] or 0
				local string = "^green;"..tag..": "..amount
				if amount < value then
					string = "^red;"..tag..": "..amount.." ^yellow;(Need "..value..")"
				end
				requiredTagsScrollArea:addChild({ type = "label", text = string })
			end
		end
		for tag, value in pairs(tags or {}) do
			if not listed[tag] then
				requiredTagsScrollArea:addChild({ type = "label", text = tag..": "..value })
			end
		end

		local species = occupier.tenants[sbq.tenantIndex].species
		local speciesSettings = sbq.extraTabs.speciesSettingsTabs[species] or sbq.extraTabs.speciesSettingsTabs.sbqOccupantHolder
		if speciesSettings.tab then
			mainTabField:newTab( speciesSettings.tab )
			for i, script in ipairs( speciesSettings.scripts ) do
				require(script)
			end
		end

		sbq.getSpeciesConfig(species)
		sbq.predatorConfig = sbq.speciesConfig.sbqData

		sbq.locationPanel()
		sbq.effectsPanel()

		local settingsDealtWith = {}
		for setting, value in pairs(sbq.predatorSettings) do
			if setting:sub(-6,-1) ~= "Locked" and not settingsDealtWith[setting] then
				local button = _ENV[setting]
				local label = _ENV[setting .. "Label"]
				local locked = _ENV[setting .. "Locked"]
				local enable = _ENV[setting.."Enable"]
				local enableLocked = _ENV[setting .. "EnableLocked"]
				settingsDealtWith[setting] = true
				settingsDealtWith[setting.."Enable"] = true

				if button ~= nil and type(value) == "boolean" then
					if label ~= nil then
						label:setVisible(true)
					end

					if sbq.overrideSettings[setting] ~= nil then
						button:setVisible(false)
						if locked ~= nil then
							locked:setVisible(true)
							if sbq.overrideSettings[setting] then
								locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
							else
								locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
							end
							locked.toolTip = (button.toolTip or "").." (Locked)"

							if enable ~= nil then
								enable:setVisible(false)
								if enableLocked ~= nil then
									enableLocked:setVisible(true)
									if sbq.overrideSettings[setting.."Enable"] then
										enableLocked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
									else
										enableLocked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
									end
									enableLocked.toolTip = (enable.toolTip or "").." (Locked)"
								end
							end
						end
					else
						button:setVisible(true)
						button:setChecked(value)
						function button:onClick()
							sbq.changePredSetting(setting, button.checked)
						end
						if enable ~= nil then
							enable:setVisible(true)
							enable:setChecked(sbq.predatorSettings[setting.."Enable"] or false)
							function enable:onClick()
								sbq.changePredSetting(setting.."Enable", enable.checked)
							end
						end
					end
				end
			end
		end
		function hammerspace:onClick() -- only one that has unique logic
			sbq.changePredSetting("hammerspace", hammerspace.checked)
			sbq.locationPanel()
		end


		settingsDealtWith = {}
		for setting, value in pairs(sbq.preySettings) do
			if setting:sub(-6,-1) ~= "Locked" and not settingsDealtWith[setting] then
				local button = _ENV[setting]
				local label = _ENV[setting .. "Label"]
				local locked = _ENV[setting .. "Locked"]
				local enable = _ENV[setting.."Enable"]
				local enableLocked = _ENV[setting .. "EnableLocked"]

				settingsDealtWith[setting] = true
				settingsDealtWith[setting.."Enable"] = true

				if button ~= nil and type(value) == "boolean" then
					if label ~= nil then
						label:setVisible(true)
					end
					if sbq.overridePreyEnabled[setting] ~= nil then
						button:setVisible(false)
						if locked ~= nil then
							locked:setVisible(true)
							if sbq.overridePreyEnabled[setting] then
								locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
							else
								locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
							end
							locked.toolTip = (button.toolTip or "").." (Locked)"

							if enable ~= nil then
								enable:setVisible(false)
								if enableLocked ~= nil then
									enableLocked:setVisible(true)
									if sbq.overridePreyEnabled[setting.."Enable"] then
										enableLocked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
									else
										enableLocked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
									end
									enableLocked.toolTip = (enable.toolTip or "").." (Locked)"
								end
							end
						end
					else
						button:setVisible(true)
						button:setChecked(value)
						function button:onClick()
							sbq.changePreySetting(setting, button.checked)
						end
						if enable ~= nil then
							enable:setVisible(true)
							enable:setChecked(sbq.preySettings[setting.."Enable"] or false)
							function enable:onClick()
								sbq.changePreySetting(setting.."Enable", enable.checked)
							end
						end
					end
				end
			end
		end

		local list = {"None","Heal","SoftDigest","Digest","TF","Eggify"}
		for location, data in pairs(sbq.predatorConfig.locations) do
			for i, effect in ipairs(list) do
				if sbq.overrideSettings[location..effect.."Enable"] == false then
					local button = _ENV[location..effect.."EnableLocked"]
					if button then button:setVisible(false) end
				end
			end
		end

		function questParticipation:onClick()
			sbq.changePredSetting("questParticipation", questParticipation.checked)

			world.sendEntityMessage(pane.sourceEntity(), "sbqSaveQuestGenSetting", "enableParticipation", questParticipation.checked, sbq.tenantIndex)
		end
		function crewmateGraduation:onClick()
			sbq.changePredSetting("crewmateGraduation", crewmateGraduation.checked)

			local graduation = {
				["true"] = {
					nextNpcType =sbq.npcConfig.scriptConfig.questGenerator.graduation.nextNpcType
				},
				["false"] = {
					nextNpcType = {nil}
				}
			}

			world.sendEntityMessage(pane.sourceEntity(), "sbqSaveQuestGenSetting", "graduation", graduation[tostring(crewmateGraduation.checked or false)], sbq.tenantIndex)
		end
	end

	sbq.validTenantCatalogueList = {}
	for name, tenant in pairs(sbq.tenantCatalogue) do
		local tenant = tenant
		if type(tenant) == "table" then
			tenant = tenant[1]
		end
		local data = root.tenantConfig(tenant).checkRequirements or {}
		local addToList = true
		if addToList and data.checkItems then
			for i, item in ipairs(data.checkItems) do
				addToList = root.itemConfig(item)
				if not addToList then break end
			end
		end
		if addToList and data.checkJson then
			addToList, json = pcall(root.assetJson, data.checkJson)
		end
		if addToList and data.checkImage then
			success, notEmpty = pcall(root.nonEmptyRegion, data.checkImage)
			addToList = (success and notEmpty ~= nil)
		end
		if addToList then
			table.insert(sbq.validTenantCatalogueList, name)
		end
	end
	table.sort(sbq.validTenantCatalogueList)
end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)
end

function sbq.savePredSettings()
	world.sendEntityMessage(pane.sourceEntity(), "sbqSaveSettings", sbq.predatorSettings, sbq.tenantIndex)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[sbq.tenantIndex].uniqueId, "sbqSaveSettings", sbq.predatorSettings)
	end
end
sbq.saveSettings = sbq.savePredSettings

function sbq.savePreySettings()
	world.sendEntityMessage(pane.sourceEntity(), "sbqSavePreySettings", sbq.preySettings, sbq.tenantIndex)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[sbq.tenantIndex].uniqueId, "sbqSavePreySettings", sbq.preySettings)
	end
end

function sbq.changePredSetting(settingname, value)
	sbq.predatorSettings[settingname] = value
	sbq.savePredSettings()
end

function sbq.changePreySetting(settingname, value)
	sbq.preySettings[settingname] = value
	sbq.savePreySettings()
end

function sbq.changeAnimOverrideSetting(settingname, settingvalue)
	sbq.animOverrideSettings[settingname] = settingvalue
	world.sendEntityMessage(pane.sourceEntity(), "sbqSaveAnimOverrideSettings", sbq.animOverrideSettings, sbq.tenantIndex)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[sbq.tenantIndex].uniqueId, "sbqSaveAnimOverrideSettings", sbq.animOverrideSettings)
		world.sendEntityMessage(sbq.storage.occupier.tenants[sbq.tenantIndex].uniqueId, "speciesAnimOverrideRefreshSettings", sbq.animOverrideSettings)
		world.sendEntityMessage(sbq.storage.occupier.tenants[sbq.tenantIndex].uniqueId, "animOverrideScale", sbq.animOverrideSettings.scale)
	end
end


indexes = {

}
function sbq.changeSelectedFromList(list, label, indexName, inc )
	indexes[indexName] = (indexes[indexName] or 1) + inc
	if indexes[indexName] < 1 then
		indexes[indexName] = #list
	elseif indexes[indexName] > #list then
		indexes[indexName] = 1
	end
	label:setText(list[indexes[indexName]])
	return list[indexes[indexName]]
end

--------------------------------------------------------------------------------------------------

function callTenant:onClick()
	world.sendEntityMessage(pane.sourceEntity(), "sbqDeedInteract", {sourceId = player.id(), sourcePosition = world.entityPosition(player.id())})
end

local applyCount = 0
function summonTenant:onClick()
	applyCount = applyCount + 1

	if applyCount > 3 or sbq.storage.occupier == nil then
		world.sendEntityMessage(pane.sourceEntity(), "sbqSummonNewTenant", sbq.getGuardTier() or tenantText.text)
		pane.dismiss()
	end
	summonTenant:setText(tostring(4 - applyCount))
end

function sbq.getGuardTier()
	local remap = (sbq.tenantCatalogue[tenantText.text])
	if type(remap) == "table" then
		local tags = sbq.storage.house.contents
		local index = 1
		if type(tags.tier2) == "number" and tags.tier2 >= 12 then
			index = 2
		end
		if type(tags.tier3) == "number" and tags.tier3 >= 12 then
			index = 3
		end
		if type(tags.tier4) == "number" and tags.tier4 >= 12 then
			index = 3
		end
		return remap[index]
	else
		return remap
	end
end

--------------------------------------------------------------------------------------------------

function decTenant:onClick()
	sbq.changeSelectedFromList(sbq.validTenantCatalogueList, tenantText, "tenantSelectorIndex", -1)
end

function incTenant:onClick()
	sbq.changeSelectedFromList(sbq.validTenantCatalogueList, tenantText, "tenantSelectorIndex", 1)
end

--------------------------------------------------------------------------------------------------

function decPersonality:onClick()
	if sbq.overrideSettings.personality ~= nil then return end
	sbq.changePredSetting("personality", sbq.changeSelectedFromList(sbq.config.npcPersonalities, personalityText, "personalityIndex", -1))
end

function incPersonality:onClick()
	if sbq.overrideSettings.personality ~= nil then return end
	sbq.changePredSetting("personality", sbq.changeSelectedFromList(sbq.config.npcPersonalities, personalityText, "personalityIndex", 1))
end

--------------------------------------------------------------------------------------------------

function decMood:onClick()
	if sbq.overrideSettings.mood ~= nil then return end
	sbq.changePredSetting("mood", sbq.changeSelectedFromList(sbq.config.npcMoods, moodText, "moodIndex", -1))
end

function incMood:onClick()
	if sbq.overrideSettings.mood ~= nil then return end
	sbq.changePredSetting("mood", sbq.changeSelectedFromList(sbq.config.npcMoods, moodText, "moodIndex", 1))
end

--------------------------------------------------------------------------------------------------

function escapeValue:onEnter()
	local value = tonumber(escapeValue.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.overrideSettings.escapeDifficulty == nil and value > 0
	and (
		(sbq.overrideSettings.escapeDifficultyMin == nil and sbq.overrideSettings.escapeDifficultyMax == nil)
		or (sbq.overrideSettings.escapeDifficultyMin <= value and sbq.overrideSettings.escapeDifficultyMax == nil)
		or (sbq.overrideSettings.escapeDifficultyMin == nil and sbq.overrideSettings.escapeDifficultyMax >= value)
		or (sbq.overrideSettings.escapeDifficultyMin <= value and sbq.overrideSettings.escapeDifficultyMax >= value)
	)
	then
		sbq.changePredSetting("escapeDifficulty", value)
	else
		escapeValue:setText(tostring(sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty or 0))
	end
end

function escapeValueMin:onEnter()
	local value = tonumber(escapeValueMin.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.overrideSettings.escapeDifficulty == nil and sbq.overrideSettings.escapeDifficultyMin == nil and value > 0 then
		sbq.changePredSetting("escapeDifficultyMin", value)
	else
		escapeValueMin:setText(tostring(sbq.overrideSettings.escapeDifficultyMin or sbq.predatorSettings.escapeDifficultyMin or 0))
	end
end

function escapeValueMax:onEnter()
	local value = tonumber(escapeValueMax.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.overrideSettings.escapeDifficulty == nil and sbq.overrideSettings.escapeDifficultyMax == nil and value > 0 then
		sbq.changePredSetting("escapeDifficultyMax", value)
	else
		escapeValueMax:setText(tostring(sbq.overrideSettings.escapeDifficultyMax or sbq.predatorSettings.escapeDifficultyMax or 0))
	end
end

--------------------------------------------------------------------------------------------------

function orderFurniture:onClick()
	local occupier = sbq.storage.occupier
	local contextMenu = {}
	for i, item in pairs(occupier.orderFurniture or {}) do
		local itemConfig = root.itemConfig(item)
		if not itemConfig then
			sb.logInfo(item.name.." can't be ordered: doesn't exist")
		elseif (type(item.price) ~= "number" and type((itemConfig.config or {}).price) ~= "number") then
			sb.logInfo(item.name.." can't be ordered: has no price")
		else
			local actionLabel = itemConfig.config.shortdescription.."^reset;"
			if item.count ~= nil and item.count > 1 then
				actionLabel = actionLabel.." x"..item.count
			end

			local price = ((item.count or 1)*(item.price or itemConfig.config.price))
			actionLabel = actionLabel..", Price: ^yellow;"..price.."^reset;"

			local comma = ""
			local gotReqTag = false
			for reqTag, value in pairs(occupier.tagCriteria or {}) do
				for j, tag in ipairs(itemConfig.config.colonyTags or {}) do
					if tag == reqTag then
						if not gotReqTag then
							actionLabel = actionLabel..", Tags:"
							gotReqTag = true
						end
						actionLabel = actionLabel..comma.." ^green;"..tag.."^reset;"
						comma = ","
						break
					end
				end
			end

			table.insert(contextMenu, {actionLabel, function () sbq.orderItem(item, price) end})
		end
	end
	metagui.contextMenu(contextMenu)
end

function sbq.orderItem(item, price)
	if player.isAdmin() or player.consumeCurrency( "money", price ) then
		player.giveItem(item)
	else
		pane.playSound("/sfx/interface/clickon_error.ogg")
	end
end

--------------------------------------------------------------------------------------------------
