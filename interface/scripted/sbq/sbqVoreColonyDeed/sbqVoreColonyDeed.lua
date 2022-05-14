---@diagnostic disable: undefined-global
sbq = {
	config = root.assetJson("/sbqGeneral.config"),
	tenantCatalogue = root.assetJson("/npcs/tenants/sbqTenantCatalogue.json"),
	extraTabs = root.assetJson("/interface/scripted/sbq/sbqSettings/sbqSettingsTabs.json")
}

require("/scripts/SBQ_RPC_handling.lua")

function init()
	sbq.settings = sb.jsonMerge( sb.jsonMerge(sbq.config.defaultSettings, sbq.config.tenantDefaultSettings), metagui.inputData.settings or {} )
	sbq.preySettings = sb.jsonMerge( sbq.config.defaultPreyEnabled.npc, (metagui.inputData.preySettings or {}) )
	sbq.storage = metagui.inputData
	BENone:selectValue(sbq.settings.bellyEffect or "sbqRemoveBellyEffects")
	escapeValue:setText(tostring(sbq.settings.escapeDifficulty or 0))
	escapeValueMin:setText(tostring(sbq.settings.escapeDifficultyMin or 0))
	escapeValueMax:setText(tostring(sbq.settings.escapeDifficultyMax or 0))

	personalityText:setText(sbq.settings.personality or "default")
	moodText:setText(sbq.settings.mood or "default")

	local occupier = sbq.storage.occupier

	if type(occupier) == "table" then
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

		local speciesSettings = sbq.extraTabs.speciesSettingsTabs[occupier.tenants[1].species] or sbq.extraTabs.speciesSettingsTabs.sbqOccupantHolder

		mainTabField:newTab( speciesSettings.tab )
		for i, script in ipairs( speciesSettings.scripts ) do
			require(script)
		end
		if bodyPartsPanel ~= nil then
			bodyPartsPanel:setVisible(false)
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

	for setting, value in pairs(sbq.settings) do
		if (setting:sub(-6,-1) ~= "Locked") then
			local button = _ENV[setting]
			if button ~= nil and type(value) == "boolean" then
				button:setChecked(value)
				function button:onClick()
					sbq.changePredSetting(setting, button.checked)
				end

				if sbq.settings[setting.."Locked"] then
					button:setVisible(false)
					local locked = _ENV[setting.."Locked"]
					if locked ~= nil then
						locked:setVisible(true)
						if value then
							locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
						else
							locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
						end
					end
				end
			end
		end
	end

	for setting, value in pairs(sbq.config.defaultPreyEnabled.npc) do
		if (setting:sub(-6,-1) ~= "Locked") and (setting:sub(-6,-1) ~= "Enable") and type(value) == "boolean" then
			if sbq.preySettings[setting.."Enable"] == nil then
				sbq.preySettings[setting.."Enable"] = sbq.preySettings[setting]
			end
			if sbq.preySettings[setting.."Locked"] then
				sbq.preySettings[setting.."EnableLocked"] = true
			end
		end
	end

	for setting, value in pairs(sbq.preySettings) do
		if (setting:sub(-6,-1) ~= "Locked") and (setting:sub(-6,-1) ~= "Enable") then
			local button = _ENV[setting]
			if button ~= nil and type(value) == "boolean" then
				button:setChecked(value)
				function button:onClick()
					sbq.changePreySetting(setting, button.checked)
				end
				if sbq.preySettings[setting.."Locked"] then
					button:setVisible(false)
					local locked = _ENV[setting.."Locked"]
					if locked ~= nil then
						locked:setVisible(true)
						if value then
							locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
							locked.toolTip = "This setting is locked as enabled for this NPC"
						else
							locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
							locked.toolTip = "This setting is locked as disabled for this NPC"
						end
					end
				end
				local enable = _ENV[setting.."Enable"]
				if enable ~= nil then
					enable:setChecked(sbq.preySettings[setting.."Enable"])
					function enable:onClick()
						sbq.changePreySetting(setting.."Enable", enable.checked)
					end
					if sbq.preySettings[setting.."EnableLocked"] then
						enable:setVisible(false)
						local locked = _ENV[setting.."EnableLocked"]
						if locked ~= nil then
							locked:setVisible(true)
							if value then
								locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedEnabled.png")
								locked.toolTip = "This setting is locked as enabled for this NPC"
							else
								locked:setImage("/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png")
								locked.toolTip = "This setting is locked as disabled for this NPC"
							end
						end
					end
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
	world.sendEntityMessage(pane.sourceEntity(), "sbqSaveSettings", sbq.settings)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[1].uniqueId, "sbqSaveSettings", sbq.settings)
	end
end

function sbq.savePreySettings()
	world.sendEntityMessage(pane.sourceEntity(), "sbqSavePreySettings", sbq.preySettings)
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[1].uniqueId, "sbqSavePreySettings", sbq.preySettings)
	end
end

function sbq.changePredSetting(settingname, value)
	sbq.settings[settingname] = value
	sbq.savePredSettings()
end

function sbq.changePreySetting(settingname, value)
	sbq.preySettings[settingname] = value
	sbq.savePreySettings()
end

function sbq.setBellyEffect()
	if not sbq.settings.BELock then
		sbq.changePredSetting("bellyEffect", BENone:getGroupValue())
	else
		BENone:selectValue(sbq.settings.bellyEffect or "sbqRemoveBellyEffects")
	end
end

function sbq.changeEscapeModifier( settingname, label, inc )
	sbq.changePredSetting(settingname, (sbq.settings[settingname] or 0) + inc)
	label:setText(tostring(sbq.settings[settingname] or 0))
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
	sbq.changeSelectedFromList(sbq.validTenantCatalogueList, tenantText, "tenantIndex", -1)
end

function incTenant:onClick()
	sbq.changeSelectedFromList(sbq.validTenantCatalogueList, tenantText, "tenantIndex", 1)
end

--------------------------------------------------------------------------------------------------

function decPersonality:onClick()
	sbq.changePredSetting("personality", sbq.changeSelectedFromList(sbq.config.npcPersonalities, personalityText, "personalityIndex", -1))
end

function incPersonality:onClick()
	sbq.changePredSetting("personality", sbq.changeSelectedFromList(sbq.config.npcPersonalities, personalityText, "personalityIndex", 1))
end

--------------------------------------------------------------------------------------------------

function decMood:onClick()
	sbq.changePredSetting("mood", sbq.changeSelectedFromList(sbq.config.npcMoods, moodText, "moodIndex", -1))
end

function incMood:onClick()
	sbq.changePredSetting("mood", sbq.changeSelectedFromList(sbq.config.npcMoods, moodText, "moodIndex", 1))
end

--------------------------------------------------------------------------------------------------

function BENone:onClick()
	sbq.setBellyEffect()
end

function BEHeal:onClick()
	sbq.setBellyEffect()
end

function BEDigest:onClick()
	sbq.setBellyEffect()
end

function BESoftDigest:onClick()
	sbq.setBellyEffect()
end

--------------------------------------------------------------------------------------------------

function decEscape:onClick()
	sbq.changeEscapeModifier("escapeDifficulty", escapeValue, -1)
end

function incEscape:onClick()
	sbq.changeEscapeModifier("escapeDifficulty", escapeValue, 1)
end

function decEscapeMin:onClick()
	sbq.changeEscapeModifier("escapeDifficultyMin", escapeValueMin, -1)
end

function incEscapeMin:onClick()
	sbq.changeEscapeModifier("escapeDifficultyMin", escapeValueMin, 1)
end

function decEscapeMax:onClick()
	sbq.changeEscapeModifier("escapeDifficultyMax", escapeValueMax, -1)
end

function incEscapeMax:onClick()
	sbq.changeEscapeModifier("escapeDifficultyMax", escapeValueMax, 1)
end

--------------------------------------------------------------------------------------------------
