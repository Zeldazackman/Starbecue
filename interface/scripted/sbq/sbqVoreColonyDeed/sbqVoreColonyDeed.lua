---@diagnostic disable: undefined-global
sbq = {
	config = root.assetJson("/sbqGeneral.config"),
	tenantCatalogue = root.assetJson("/npcs/tenants/sbqTenantCatalogue.json"),
	storage = metagui.inputData,
	deedUI = true
}

indexes = {
	tenantIndex = 1
}

require("/interface/scripted/sbq/sbqSettings/extraTabs.lua")

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

require("/scripts/SBQ_RPC_handling.lua")
require("/interface/scripted/sbq/sbqSettings/sbqSettingsEffectsPanel.lua")
require("/scripts/SBQ_species_config.lua")
require("/interface/scripted/sbq/sbqSettings/autoSetSettings.lua")

function sbq.drawLocked(w, icon)
	local c = widget.bindCanvas(w.backingWidget)
	c:clear()
	local pos = vec2.mul(c:size(), 0.5)
	c:drawImageDrawable(icon, pos, 1)
end

sbq.selectedMainTabFieldTab = mainTabField.tabs.tenantTab

function init()
	local occupier = sbq.storage.occupier

	if type(occupier) == "table" and type(occupier.tenants) == "table" and
		type(occupier.tenants[indexes.tenantIndex]) == "table" and
		type(occupier.tenants[indexes.tenantIndex].species) == "string"
	then
		sbq.tenant = occupier.tenants[indexes.tenantIndex]
		sbq.npcConfig = root.npcConfig(sbq.tenant.type)

		sbq.sbqCurrentData = ((sbq.tenant.overrides.statusControllerSettings or {}).statusProperties or {}).sbqCurrentData or {}

		-- I do need to seperate the settings for the NPCs based on their pred species but thats for another time
		--[[if sbq.sbqCurrentData.species ~= nil then
			if sbq.sbqCurrentData.species == "sbqOccupantHolder" then
				sbq.getSpeciesConfig(sbq.tenant.species)
				sbq.predatorConfig = sbq.speciesConfig.sbqData
					else
				sbq.predatorConfig = root.assetJson("/vehicles/sbq/"..sbq.sbqCurrentData.species.."/"..sbq.sbqCurrentData.species..".vehicle").sbqData or {}
			end
		else
			sbq.getSpeciesConfig(sbq.tenant.species)
			sbq.predatorConfig = sbq.speciesConfig.sbqData
		end]]
		sbq.getSpeciesConfig(sbq.tenant.species)
		sbq.predatorConfig = sbq.speciesConfig.sbqData


		sbq.overrideSettings = sb.jsonMerge(sbq.predatorConfig.overrideSettings or {}, sbq.npcConfig.scriptConfig.sbqOverrideSettings or {})
		sbq.overridePreyEnabled = sb.jsonMerge(sbq.predatorConfig.overridePreyEnabled or {}, sbq.npcConfig.scriptConfig.sbqOverridePreyEnabled or {})

		sbq.tenant.overrides.statusControllerSettings = sbq.tenant.overrides.statusControllerSettings or {}
		sbq.tenant.overrides.statusControllerSettings.statusProperties = sbq.tenant.overrides.statusControllerSettings.statusProperties or {}
		sbq.tenant.overrides.statusControllerSettings.statusProperties.sbqPreyEnabled = sbq.tenant.overrides.statusControllerSettings.statusProperties.sbqPreyEnabled or {}

		sbq.predatorSettings = sb.jsonMerge( sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.predatorConfig.defaultSettings or {}), sbq.config.tenantDefaultSettings),
			sb.jsonMerge( sbq.npcConfig.scriptConfig.sbqDefaultSettings or {},
				sb.jsonMerge( sbq.tenant.overrides.scriptConfig.sbqSettings or {}, sbq.overrideSettings)
			)
		)
		sbq.tenant.overrides.scriptConfig.sbqSettings = sbq.predatorSettings
		sbq.predatorSettings.firstLoadDone = true

		sbq.preySettings = sb.jsonMerge( sbq.config.defaultPreyEnabled.player,
			sb.jsonMerge(sbq.tenant.overrides.statusControllerSettings.statusProperties.sbqPreyEnabled or {}, sbq.overridePreyEnabled or {})
		)

		sbq.animOverrideSettings = sb.jsonMerge(root.assetJson("/animOverrideDefaultSettings.config"), sbq.tenant.overrides.statusControllerSettings.statusProperties.speciesAnimOverrideSettings or {})
		sbq.animOverrideSettings.scale = ((sbq.tenant.overrides.statusControllerSettings or {}).statusProperties or {}).animOverrideScale or 1
		sbq.animOverrideOverrideSettings = sbq.tenant.overrides.statusControllerSettings.statusProperties.speciesAnimOverrideOverrideSettings or {}
		sbq.tenant.overrides.statusControllerSettings.statusProperties.speciesAnimOverrideSettings = sbq.animOverrideSettings

		sbq.globalSettings = sbq.predatorSettings
		escapeValue:setText(tostring(sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty or 0))
		escapeValueMin:setText(tostring(sbq.overrideSettings.escapeDifficultyMin or sbq.predatorSettings.escapeDifficultyMin or 0))
		escapeValueMax:setText(tostring(sbq.overrideSettings.escapeDifficultyMax or sbq.predatorSettings.escapeDifficultyMax or 0))
		sbq.numberBoxColor(escapeValue, sbq.overrideSettings.escapeDifficultyMin or sbq.predatorSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficultyMax or sbq.predatorSettings.escapeDifficultyMax)
		sbq.numberBoxColor(escapeValueMin, sbq.overrideSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty )
		sbq.numberBoxColor(escapeValueMax, sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty, sbq.overrideSettings.escapeDifficultyMax )

		personalityText:setText(sbq.predatorSettings.personality or "default")
		moodText:setText(sbq.predatorSettings.mood or "default")

		sbq.onTenantChanged()

		if not sbq.storage.crewUI then
			tenantNote:setVisible(occupier.tenantNote ~= nil)
			tenantNote.toolTip = occupier.tenantNote

			orderFurniture:setVisible(occupier.orderFurniture ~= nil)

			tenantText:setText(occupier.name or "")
			if not sbq.storage.crewUI then
				local tags = sbq.storage.house.contents
				local listed = { sbqVore = true }
				requiredTagsScrollArea:clearChildren()
				local colonyTagLabels = {}
				for tag, value in pairs(occupier.tagCriteria or {}) do
					if tag ~= "sbqVore" then
						listed[tag] = true
						local amount = tags[tag] or 0
						local string = "^green;" .. tag .. ": " .. amount
						if amount < value then
							string = "^red;" .. tag .. ": " .. amount .. " ^yellow;(Need " .. value .. ")"
						end
						table.insert(colonyTagLabels, { type = "label", text = string })
					end
				end
				for tag, value in pairs(tags or {}) do
					if not listed[tag] then
						table.insert(colonyTagLabels, { type = "label", text = tag .. ": " .. value })
					end
				end
				requiredTagsScrollArea:addChild({ type = "panel", style = "flat", children = colonyTagLabels })
			end
		end

		local sbqNPC = sbq.npcConfig.scriptConfig.sbqNPC or false
		globalTenantSettingsLayout:setVisible(sbqNPC)
		notStarbecueNPC:setVisible(not sbqNPC)
		if not sbqNPC then
			local convertible = sbq.config.vornyConvertTable[sbq.tenant.type]
			if convertible ~= nil then
				convertNPC:setVisible(true)
				convertNPC:setText("Convert")
				local applyCount = 0
				function convertNPC:onClick()
					applyCount = applyCount + 1

					if applyCount > 3 then
						world.sendEntityMessage(sbq.tenant.uniqueId, "sbqSetNPCType", convertible)
						if sbq.storage.crewUI then
							for i, follower in ipairs(sbq.followers) do
								if follower.uniqueId == sbq.tenant.uniqueId then
									follower.config.type = convertible
									break
								end
							end
							world.sendEntityMessage(player.id(), "sbqSetRecruits", "followers", sbq.followers)
						end
						pane.dismiss()
					end
					convertNPC:setText(tostring(4 - applyCount))
				end
			else
				convertNPC:setVisible(false)
			end
		else
			local visible = false
			for convertible, converted in pairs(sbq.config.vornyConvertTable) do
				if converted == sbq.tenant.type then
					visible = true
					local applyCount = 0

					function revertNPC:onClick()
						applyCount = applyCount + 1
						if applyCount > 3 then
							world.sendEntityMessage(sbq.tenant.uniqueId, "sbqSetNPCType", convertible)
							if sbq.storage.crewUI then
								for i, follower in ipairs(sbq.followers) do
									if follower.uniqueId == sbq.tenant.uniqueId then
										follower.config.type = convertible
										break
									end
								end
								world.sendEntityMessage(player.id(), "sbqSetRecruits", "followers", sbq.followers)
							end
							pane.dismiss()
						end
						revertNPC:setText(tostring(4 - applyCount))
					end
					break
				end
			end
			revertNPC:setVisible(visible)
		end

		local predTabVisible = (sbq.npcConfig.scriptConfig.isPredator or (sbq.npcConfig.scriptConfig.isPredator == nil)) and sbqNPC
		notPredText:setVisible(not predTabVisible)
		globalPredSettingsLayout:setVisible(predTabVisible)

		local preyTabVisible = sbq.npcConfig.scriptConfig.isPrey or (sbq.npcConfig.scriptConfig.isPrey == nil)
		notPreyText:setVisible(not preyTabVisible)
		globalPreySettingsLayout:setVisible(preyTabVisible)

		sbq.effectsPanel()

		sbq.setSpeciesHelpTab(species)
		sbq.setSpeciesSettingsTab(species)
		sbq.setHelpTab()

		sbq.checkLockedSettingsButtons("predatorSettings", "overrideSettings", "changePredatorSetting")
		--sbq.checkLockedSettingsButtons("globalSettings", "overrideSettings", "changeGlobalSetting")
		sbq.checkLockedSettingsButtons("preySettings", "overridePreyEnabled", "changePreySetting")
		sbq.checkLockedSettingsButtons("animOverrideSettings", "animOverrideOverrideSettings", "changeAnimOverrideSetting")

		if questParticipation ~= nil then
			if sbq.overrideSettings.questParticipation == nil then
				function questParticipation:onClick()
					sbq.changePredatorSetting("questParticipation", questParticipation.checked)

					world.sendEntityMessage(pane.sourceEntity(), "sbqSaveQuestGenSetting", "enableParticipation", questParticipation.checked, indexes.tenantIndex)
				end
			end
			if sbq.overrideSettings.crewmateGraduation == nil then
				function crewmateGraduation:onClick()
					sbq.changePredatorSetting("crewmateGraduation", crewmateGraduation.checked)

					local graduation = {
						["true"] = {
							nextNpcType =sbq.npcConfig.scriptConfig.questGenerator.graduation.nextNpcType
						},
						["false"] = {
							nextNpcType = {nil}
						}
					}
					world.sendEntityMessage(pane.sourceEntity(), "sbqSaveQuestGenSetting", "graduation", graduation[tostring(crewmateGraduation.checked or false)], indexes.tenantIndex)
				end
			end
		end
	end
end

function sbq.checkLockedSettingsButtons(settings, override, func)
	for setting, value in pairs(sbq[settings]) do
		if setting:sub(-1,-#"Enable") ~= "Enable" then
			local enable = _ENV[setting .. "Enable"]
			if enable ~= nil then
				sbq[settings][setting.."Enable"] = sbq[settings][setting.."Enable"] or false
			end
		end
	end
	for setting, value in pairs(sbq[settings] or {}) do
		local button = _ENV[setting]
		if button ~= nil and type(value) == "boolean" then
			if sbq[override][setting] ~= nil then
				if sbq[override][setting] then
					function button:draw() sbq.drawLocked(button, "/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png") end
				else
					function button:draw() sbq.drawLocked(button, "/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png") end
				end
				function button:onClick() end
			else
				if sbq.drawSpecialButtons[setting] then
					function button:draw() button.drawSpecial() end
				else
					function button:draw() theme.drawCheckBox(self) end
				end
				button:setChecked(value)
				function button:onClick()
					sbq[func](setting, button.checked)
				end
			end
		end
	end
end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)
end

function sbq.savePredSettings()
	sbq.tenant.overrides.scriptConfig.sbqSettings = sbq.predatorSettings
	world.sendEntityMessage(pane.sourceEntity(), "sbqSaveSettings", sbq.predatorSettings, indexes.tenantIndex)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.tenant.uniqueId, "sbqSaveSettings", sbq.predatorSettings)
	end
end
sbq.saveSettings = sbq.savePredSettings

function sbq.savePreySettings()
	sbq.tenant.overrides.statusControllerSettings.statusProperties.sbqPreyEnabled = sbq.preySettings
	world.sendEntityMessage(pane.sourceEntity(), "sbqSavePreySettings", sbq.preySettings, indexes.tenantIndex)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.tenant.uniqueId, "sbqSavePreySettings", sbq.preySettings)
	end
end

function sbq.changePredatorSetting(settingname, value)
	sbq.predatorSettings[settingname] = value
	sbq.autoSetSettings(settingname, value)
	-- a hack until I improve how sided locations are handled
	if (settingname:sub(1, #"balls") == "balls") then
		sbq.predatorSettings[settingname:gsub("balls", "ballsL")] = value
		sbq.predatorSettings[settingname:gsub("balls", "ballsR")] = value
	elseif (settingname:sub(1, #"breasts") == "breasts") then
		sbq.predatorSettings[settingname:gsub("breasts", "breastsL")] = value
		sbq.predatorSettings[settingname:gsub("breasts", "breastsR")] = value
	end
	sbq.savePredSettings()
end

function sbq.changePreySetting(settingname, value)
	sbq.preySettings[settingname] = value
	sbq.savePreySettings()
end

function sbq.changeAnimOverrideSetting(settingname, settingvalue)
	sbq.animOverrideSettings[settingname] = settingvalue
	sbq.tenant.overrides.statusControllerSettings.statusProperties.speciesAnimOverrideSettings = sbq.animOverrideSettings
	world.sendEntityMessage(pane.sourceEntity(), "sbqSaveAnimOverrideSettings", sbq.animOverrideSettings, indexes.tenantIndex)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.tenant.uniqueId, "sbqSaveAnimOverrideSettings", sbq.animOverrideSettings)
		world.sendEntityMessage(sbq.tenant.uniqueId, "speciesAnimOverrideRefreshSettings", sbq.animOverrideSettings)
		world.sendEntityMessage(sbq.tenant.uniqueId, "animOverrideScale", sbq.animOverrideSettings.scale)
	end
end

--------------------------------------------------------------------------------------------------

if callTenant ~= nil then
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

if decTenant ~= nil then
	function decTenant:onClick()
		sbq.changeSelectedFromList(sbq.validTenantCatalogueList, tenantText, "tenantSelectorIndex", -1)
	end

	function incTenant:onClick()
		sbq.changeSelectedFromList(sbq.validTenantCatalogueList, tenantText, "tenantSelectorIndex", 1)
	end
end


function sbq.onTenantChanged()
end

function decCurTenant:onClick()
	sbq.changeSelectedFromList(sbq.tenantList, curTenantName, "tenantIndex", -1)
	curTenantIndex:setText(indexes.tenantIndex)
	init()
end

function incCurTenant:onClick()
	sbq.changeSelectedFromList(sbq.tenantList, curTenantName, "tenantIndex", 1)
	curTenantIndex:setText(indexes.tenantIndex)
	init()
end

--------------------------------------------------------------------------------------------------

function decPersonality:onClick()
	if sbq.overrideSettings.personality ~= nil then return end
	sbq.changePredatorSetting("personality", sbq.changeSelectedFromList(sbq.config.npcPersonalities, personalityText, "personalityIndex", -1))
end

function incPersonality:onClick()
	if sbq.overrideSettings.personality ~= nil then return end
	sbq.changePredatorSetting("personality", sbq.changeSelectedFromList(sbq.config.npcPersonalities, personalityText, "personalityIndex", 1))
end

--------------------------------------------------------------------------------------------------

function decMood:onClick()
	if sbq.overrideSettings.mood ~= nil then return end
	sbq.changePredatorSetting("mood", sbq.changeSelectedFromList(sbq.config.npcMoods, moodText, "moodIndex", -1))
end

function incMood:onClick()
	if sbq.overrideSettings.mood ~= nil then return end
	sbq.changePredatorSetting("mood", sbq.changeSelectedFromList(sbq.config.npcMoods, moodText, "moodIndex", 1))
end

--------------------------------------------------------------------------------------------------

function escapeValue:onEnter() sbq.numberBox(escapeValue, "changePredatorSetting", "escapeDifficulty", "predatorSettings", "overrideSettings", sbq.overrideSettings.escapeDifficultyMin or sbq.predatorSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficultyMax or sbq.predatorSettings.escapeDifficultyMax ) end
function escapeValue:onTextChanged() sbq.numberBoxColor(escapeValue, sbq.overrideSettings.escapeDifficultyMin or sbq.predatorSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficultyMax or sbq.predatorSettings.escapeDifficultyMax ) end
function escapeValue:onEscape() self:onEnter() end
function escapeValue:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end

function escapeValueMin:onEnter() sbq.numberBox(escapeValueMin, "changePredatorSetting", "escapeDifficultyMin", "predatorSettings", "overrideSettings", sbq.overrideSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty ) end
function escapeValueMin:onTextChanged() sbq.numberBoxColor(escapeValueMin, sbq.overrideSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty ) end
function escapeValueMin:onEscape() self:onEnter() end
function escapeValueMin:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end

function escapeValueMax:onEnter() sbq.numberBox(escapeValueMax, "changePredatorSetting", "escapeDifficultyMax", "predatorSettings", "overrideSettings", sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty, sbq.overrideSettings.escapeDifficultyMax ) end
function escapeValueMax:onTextChanged() sbq.numberBoxColor(escapeValueMax, sbq.overrideSettings.escapeDifficulty or sbq.predatorSettings.escapeDifficulty, sbq.overrideSettings.escapeDifficultyMax ) end
function escapeValueMax:onEscape() self:onEnter() end
function escapeValueMax:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end

--------------------------------------------------------------------------------------------------

if orderFurniture ~= nil then
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
end

--------------------------------------------------------------------------------------------------

if sbq.storage.crewUI then
	require("/interface/scripted/sbq/sbqVoreColonyDeed/sbqVoreCrewMenu.lua")
end

sbq.tenantList = {}
if sbq.storage.occupier then
	local occupier = sbq.storage.occupier
	if type(occupier) == "table" and type(occupier.tenants) == "table" and
		type(occupier.tenants[indexes.tenantIndex]) == "table" and
		type(occupier.tenants[indexes.tenantIndex].species) == "string"
	then
		for i, tenant in ipairs(occupier.tenants) do
			local name = ((tenant.overrides or {}).identity or {}).name or ""
			table.insert(sbq.tenantList, name)
		end
	end
end
curTenantName:setText(sbq.tenantList[indexes.tenantIndex])
