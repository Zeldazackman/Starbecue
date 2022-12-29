
---@diagnostic disable:undefined-global

require( "/lib/stardust/json.lua" )

sbq = {
	config = root.assetJson( "/sbqGeneral.config" ),
	overrideSettings = {}
}
speciesOverride = {}

function speciesOverride._species()
	return (status.statusProperty("speciesAnimOverrideData") or {}).species or speciesOverride.species()
end

function speciesOverride._gender()
	return (status.statusProperty("speciesAnimOverrideData") or {}).gender or speciesOverride.gender()
end
speciesOverride.species = player.species
player.species = speciesOverride._species

speciesOverride.gender = player.gender
player.gender = speciesOverride._gender

require("/scripts/SBQ_RPC_handling.lua")
require("/interface/scripted/sbq/sbqSettings/sbqSettingsEffectsPanel.lua")
require("/scripts/SBQ_species_config.lua")
require("/interface/scripted/sbq/sbqSettings/extraTabs.lua")
require("/interface/scripted/sbq/sbqSettings/autoSetSettings.lua")

sbq.selectedMainTabFieldTab = mainTabField.tabs.globalPredSettings

function sbq.getInitialData()
	sbq.sbqSettings = player.getProperty("sbqSettings") or {}

	sbq.sbqCurrentData = player.getProperty("sbqCurrentData") or {}
	sbq.lastSpecies = sbq.sbqCurrentData.species
	sbq.lastType = sbq.sbqCurrentData.type

	sbq.storedDigestedPrey = status.statusProperty("sbqStoredDigestedPrey") or {}

	sbq.predatorEntity = sbq.sbqCurrentData.id

	sbq.animOverrideSettings = sb.jsonMerge(root.assetJson("/animOverrideDefaultSettings.config"), status.statusProperty("speciesAnimOverrideSettings") or {})
	sbq.animOverrideSettings.scale = status.statusProperty("animOverrideScale") or 1
	sbq.animOverrideOverrideSettings = status.statusProperty("speciesAnimOverrideOverrideSettings") or {}

	sbq.sbqCurrentData.species = sbq.sbqCurrentData.species or "sbqOccupantHolder"
end

function sbq.getPlayerOccupantHolderData()
	sbq.getSpeciesConfig(player.species(), sbq.sbqSettings.global)
	sbq.predatorConfig = sbq.speciesConfig.sbqData
end

function sbq.drawLocked(w, icon)
	local c = widget.bindCanvas(w.backingWidget)
	c:clear()
	local pos = vec2.mul(c:size(), 0.5)
	c:drawImageDrawable(icon, pos, 1)
end

function init()

	sbq.getInitialData()

	sbq.globalSettings = sb.jsonMerge(sbq.config.globalSettings, sbq.sbqSettings.global)

	if sbq.sbqCurrentData.species ~= nil then
		if sbq.sbqCurrentData.species == "sbqOccupantHolder" then
			sbq.getPlayerOccupantHolderData()
		else
			sbq.predatorConfig = root.assetJson("/vehicles/sbq/" .. sbq.sbqCurrentData.species .. "/" .. sbq.sbqCurrentData.species .. ".vehicle").sbqData or {}
			for location, data in pairs(sbq.predatorConfig.locations or {}) do
				sbq.predatorConfig.locations[location] = sb.jsonMerge(sbq.config.defaultLocationData[location] or {}, data)
			end
		end
		sbq.predatorSettings = sb.jsonMerge(sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.predatorConfig.defaultSettings or {}), sbq.sbqSettings[sbq.sbqCurrentData.species] or {}), sbq.globalSettings)
	else
		sbq.getPlayerOccupantHolderData()
		sbq.predatorSettings = sb.jsonMerge(sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.predatorConfig.defaultSettings or {}), sbq.sbqSettings.sbqOccupantHolder or {}), sbq.globalSettings)
	end
	sbq.overrideSettings = sbq.predatorConfig.overrideSettings or {}

	sbq.effectsPanel()

	if ((sbq.sbqCurrentData.type ~= "prey") or (sbq.sbqCurrentData.type == "object")) then
		mainTabField.tabs.customizeTab:setVisible(true)

		if sbq.predatorConfig.customizePresets ~= nil then
			presetsPanel:setVisible(true)
			sbq.preset = 1
			presetText:setText(sbq.predatorSettings.presetText or sbq.predatorConfig.presetList[sbq.preset])
		else
			presetsPanel:setVisible(false)
		end
		if not player.loungingIn() and sbq.sbqCurrentData.type ~= "object" and (sbq.sbqCurrentData.species == nil or sbq.sbqCurrentData.species == "sbqOccupantHolder") then
			speciesLayout:setVisible( not sbq.hideSpeciesPanel )
		elseif sbq.sbqCurrentData.type ~= "object" then
			speciesLayout:setVisible(false)
		end


		if sbq.predatorConfig.replaceColors ~= nil then
			colorsPanel:setVisible(true)
			colorsScrollArea:clearChildren()
			for i, colors in ipairs(sbq.predatorConfig.replaceColors) do
				colorsScrollArea:addChild({ type = "layout", mode = "horizontal", children = {
					{{size = {48,10}},{ type = "label", text = (sbq.predatorConfig.replaceColorNames or {})[i] or ("Color "..i), inline = true}},
					{ type = "checkBox", id = "color"..i.."Fullbright", checked = (sbq.predatorSettings.fullbright or {})[i] or (sbq.predatorConfig.defaultSettings.fullbright or {})[i], toolTip = "Fullbright" },
					{ type = "iconButton", id = "color"..i.."Prev", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png"},
					{ type = "textBox", id = "color"..i.."TextEntry", toolTip = "Edit the text here to define a custom palette, make sure to match the formatting.", expandMode = {2,2} },
					{ type = "iconButton", id = "color"..i.."Next", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png"}
				}})
				local fullbright = _ENV["color"..i.."Fullbright"]
				local prev = _ENV["color"..i.."Prev"]
				local textbox = _ENV["color"..i.."TextEntry"]
				local next = _ENV["color"..i.."Next"]

				if type((sbq.predatorSettings.replaceColorTable or {})[i]) == "string" then
					textbox:setText((sbq.predatorSettings.replaceColorTable or {})[i])
				else
					textbox:setText(sb.printJson( ( (sbq.predatorSettings.replaceColorTable or {})[i]) or ( sbq.predatorConfig.replaceColors[i][ (sbq.predatorSettings.replaceColors[i] or (sbq.predatorConfig.defaultSettings.replaceColors or {})[i] or 1 ) + 1 ] ) ) )
				end

				function fullbright:onClick()
					sbq.predatorSettings.fullbright[i] = fullbright.checked
					sbq.saveSettings()
				end
				function prev:onClick()
					sbq.changeColorSetting(textbox, i, -1)
				end
				function textbox:onTextChanged()
					local decoded = json.decode(textbox.text)
					if type(decoded) == "table" then
						sbq.predatorSettings.replaceColorTable[i] = decoded
					else
						sbq.predatorSettings.replaceColorTable[i] = nil
					end
					sbq.setColorReplaceDirectives()
					sbq.saveSettings()
				end
				function next:onClick()
					sbq.changeColorSetting(textbox, i, 1)
				end
			end
		else
			colorsScrollArea:clearChildren()
			colorsPanel:setVisible(false)
		end
		if sbq.predatorConfig.replaceSkin then
			skinsPanel:setVisible(true)
			skinsScrollArea:clearChildren()
			for part, _ in pairs(sbq.predatorConfig.replaceSkin) do
				skinsScrollArea:addChild({ type = "layout", mode = "horizontal", children = {
					{{size = {48,10}},{ type = "label", text = " "..sbq.predatorConfig.replaceSkin[part].name, inline = true}},
					{ type = "iconButton", id = part.."Prev", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png"},
					{ type = "textBox", id = part.."TextEntry", toolTip = "Edit the text here to define a specific skin, if it exists", expandMode = {2,2} },
					{ type = "iconButton", id = part.."Next", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png"}
				}})
				local prev = _ENV[part.."Prev"]
				local textbox = _ENV[part.."TextEntry"]
				local next = _ENV[part.."Next"]

				textbox:setText((sbq.predatorSettings.skinNames or {})[part] or "default")

				function prev:onClick()
					sbq.changeSkinSetting(textbox, part, -1)
				end
				function textbox:onTextChanged()
					if textbox.text ~= nil and textbox.text ~= "" then
						for i, partname in ipairs(sbq.predatorConfig.replaceSkin[part].parts) do
							sbq.predatorSettings.skinNames[partname] = textbox.text
						end
						sbq.saveSettings()
					end
				end
				function next:onClick()
					sbq.changeSkinSetting(textbox, part, 1)
				end
			end
		else
			skinsScrollArea:clearChildren()
			skinsPanel:setVisible(false)
		end
	else
		mainTabField.tabs.customizeTab:setVisible(false)
		presetsPanel:setVisible(false)
		colorsScrollArea:clearChildren()
		skinsScrollArea:clearChildren()
	end

	local species = player.species()
	sbq.setSpeciesHelpTab(species)
	sbq.setSpeciesSettingsTab(species)
	sbq.setHelpTab()

	escapeValue:setText(tostring(sbq.globalSettings.escapeDifficulty or 0))
	sbq.numberBoxColor(escapeValue, sbq.overrideSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficultyMax)
	sbq.refreshButtons()
	sbq.checkLockedSettingsButtons("animOverrideSettings", "animOverrideOverrideSettings", "changeAnimOverrideSetting")

	if mainTabField.tabs.globalPreySettings ~= nil then
		sbq.sbqPreyEnabled = sb.jsonMerge(sbq.config.defaultPreyEnabled.player, status.statusProperty("sbqPreyEnabled") or {})
		sbq.overridePreyEnabled = status.statusProperty("sbqOverridePreyEnabled") or {}
		sbq.checkLockedSettingsButtons("sbqPreyEnabled", "overridePreyEnabled", "changePreySetting")
	end
end
local init = init

function sbq.refreshButtons()
	sbq.checkLockedSettingsButtons("predatorSettings", "overrideSettings", "changePredatorSetting")
	sbq.checkLockedSettingsButtons("globalSettings", "overrideSettings", "changeGlobalSetting")
end

function sbq.checkLockedSettingsButtons(settings, override, func)
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
					function button:draw() button:drawSpecial() end
				else
					function button:draw() theme.drawCheckBox(self) end
				end
				button:setChecked(value)
				function button:onClick()
					sbq[func](setting, button.checked)
					if type(settingsButtonScripts[setting]) == "function" then
						settingsButtonScripts[setting](setting, button.checked)
					end
				end
			end
		end
	end
end

function update()
	sbq.sbqCurrentData = player.getProperty("sbqCurrentData") or {}
	sbq.sbqSettings = player.getProperty("sbqSettings") or {}
	sbq.globalSettings = sb.jsonMerge(sbq.config.globalSettings, sbq.sbqSettings.global or {})

	if sbq.sbqCurrentData.id ~= sbq.predatorEntity then
		init()
	end
end

--------------------------------------------------------------------------------------------------

function sbq.saveSettings()
	if type(sbq.sbqCurrentData.id) == "number" and sbq.sbqCurrentData.type == "driver" and world.entityExists(sbq.sbqCurrentData.id) then
		world.sendEntityMessage( sbq.sbqCurrentData.id, "settingsMenuSet", sb.jsonMerge(sbq.predatorSettings, sbq.globalSettings))
	end

	sbq.sbqSettings[sbq.sbqCurrentData.species or "sbqOccupantHolder"] = sbq.predatorSettings
	sbq.sbqSettings.global = sbq.globalSettings
	player.setProperty( "sbqSettings", sbq.sbqSettings )
	world.sendEntityMessage( player.id(), "sbqRefreshSettings", sbq.sbqSettings )
end

function sbq.changeGlobalSetting(settingname, settingvalue)
	sbq.globalSettings[settingname] = settingvalue
	sbq.predatorSettings[settingname] = settingvalue
	sbq.autoSetSettings(settingname, settingvalue)

	sbq.saveSettings()
end

function sbq.changePredatorSetting(settingname, settingvalue)
	sbq.predatorSettings[settingname] = settingvalue
	sbq.autoSetSettings(settingname, settingvalue)

	sbq.saveSettings()
end

function sbq.changeAnimOverrideSetting(settingname, settingvalue)
	sbq.animOverrideSettings[settingname] = settingvalue
	status.setStatusProperty("speciesAnimOverrideSettings", sbq.animOverrideSettings)
	world.sendEntityMessage(player.id(), "speciesAnimOverrideRefreshSettings", sbq.animOverrideSettings)
	world.sendEntityMessage(player.id(), "animOverrideScale", sbq.animOverrideSettings.scale)
end

function sbq.changePreySetting(settingname, settingvalue)
	sbq.sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	sbq.sbqPreyEnabled[settingname] = settingvalue
	status.setStatusProperty("sbqPreyEnabled", sbq.sbqPreyEnabled)
	status.clearPersistentEffects("digestImmunity")
	status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
end

function sbq.changeColorSetting(textbox, color, inc)
	if sbq.predatorConfig.replaceColors == nil then return end

	sbq.predatorSettings.replaceColors[color] = ((sbq.predatorSettings.replaceColors[color] or ((sbq.predatorConfig.defaultSettings.replaceColorTable or {})[color]) or 1 ) + inc)

	if sbq.predatorSettings.replaceColors[color] < 1 then
		sbq.predatorSettings.replaceColors[color] = (#sbq.predatorConfig.replaceColors[color] -1)
	elseif sbq.predatorSettings.replaceColors[color] > (#sbq.predatorConfig.replaceColors[color] -1) then
		sbq.predatorSettings.replaceColors[color] = 1
	end

	local colorTable = sbq.predatorConfig.replaceColors[color][ (sbq.predatorSettings.replaceColors[color] or ((sbq.predatorConfig.defaultSettings.replaceColorTable or {})[color]) or 1 ) + 1 ]

	textbox:setText(sb.printJson(colorTable))

	sbq.predatorSettings.replaceColorTable[color] = colorTable

	sbq.setColorReplaceDirectives()
	sbq.setIconDirectives()
	sbq.saveSettings()
end

function sbq.setColorReplaceDirectives()
	if sbq.predatorConfig.replaceColors ~= nil then
		local colorReplaceString = ""
		for i, colorGroup in ipairs(sbq.predatorConfig.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[((sbq.predatorSettings.replaceColors or {})[i] or (sbq.predatorConfig.defaultSettings.replaceColors or {})[i] or 1) + 1]
			local fullbright = (sbq.predatorSettings.fullbright or {})[i]

			if sbq.predatorSettings.replaceColorTable and sbq.predatorSettings.replaceColorTable[i] then
				replacePalette = sbq.predatorSettings.replaceColorTable[i]
				if type(replacePalette) == "string" then
					sbq.predatorSettings.directives = replacePalette
					return
				end
			end

			for j, color in ipairs(replacePalette) do
				if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
					color = color.."fe"
				end
				colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")
			end
		end
		sbq.predatorSettings.directives = colorReplaceString
	end
end

function sbq.changeSkinSetting(textbox, part, inc)
	local skinIndex = (sbq.predatorSettings.replaceSkin[part] or 1) + inc
	if skinIndex > #sbq.predatorConfig.replaceSkin[part].skins then
		skinIndex = 1
	elseif skinIndex < 1 then
		skinIndex = #sbq.predatorConfig.replaceSkin[part].skins
	end

	sbq.predatorSettings.replaceSkin[part] = skinIndex

	textbox:setText(sbq.predatorConfig.replaceSkin[part].skins[skinIndex])

	for i, partname in ipairs(sbq.predatorConfig.replaceSkin[part].parts) do
		sbq.predatorSettings.skinNames[partname] = sbq.predatorConfig.replaceSkin[part].skins[skinIndex]
	end
	sbq.saveSettings()
end

function sbq.changePreset(inc)
	local presetIndex = (sbq.preset or 1) + inc
	if presetIndex > #sbq.predatorConfig.presetList then
		presetIndex = 1
	elseif presetIndex < 1 then
		presetIndex = #sbq.predatorConfig.presetList
	end
	sbq.preset = presetIndex
	presetText:setText(sbq.predatorConfig.presetList[sbq.preset])
end

--------------------------------------------------------------------------------------------------


function escapeValue:onEnter()
	sbq.numberBox(self, "changeGlobalSetting", "escapeDifficulty", "predatorSettings", "overrideSettings", sbq.overrideSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficultyMax)
end
function escapeValue:onTextChanged()
	sbq.numberBoxColor(self, sbq.overrideSettings.escapeDifficultyMin, sbq.overrideSettings.escapeDifficultyMax)
end
function escapeValue:onEscape() self:onEnter() end
function escapeValue:onUnfocus() self.focused = false self:queueRedraw() self:onEnter() end


--------------------------------------------------------------------------------------------------

function decPreset:onClick()
	sbq.changePreset(-1)
end

function incPreset:onClick()
	sbq.changePreset(1)
end

function applyPreset:onClick()
	local preset = sbq.predatorConfig.customizePresets[presetText.text]
	if preset then
		sbq.predatorSettings = sb.jsonMerge(sbq.predatorSettings, preset)
		if preset.replaceColors then
			sbq.predatorSettings.replaceColorTable = {}
		end
		sbq.predatorSettings.presetText = presetText.text
		sbq.setColorReplaceDirectives()
		sbq.setIconDirectives()
		sbq.saveSettings()
	end
end

function presetText:onEnter()
	applyPreset:onClick()
end

--------------------------------------------------------------------------------------------------
if speciesLayout ~= nil then
	function refreshOccupantHolder()
		local currentData = status.statusProperty("sbqCurrentData") or {}
		if type(currentData.id) == "number" and world.entityExists(currentData.id) then
			world.sendEntityMessage(currentData.id, "reversion")
			if currentData.species == "sbqOccupantHolder" then
				world.spawnProjectile("sbqWarpInEffect", world.entityPosition(player.id()), player.id(), { 0, 0 }, true)
			elseif type(currentData.species) == "nil" then
				world.sendEntityMessage(entity.id(), "sbqGetSpeciesVoreConfig")
			end
		else
			world.spawnProjectile("sbqWarpInEffect", world.entityPosition(player.id()), player.id(), { 0, 0 }, true)
		end
	end

	function decSpecies:onClick()
		sbq.changeSpecies(-1)
	end

	function incSpecies:onClick()
		sbq.changeSpecies(1)
	end

	function applySpecies:onClick()
		if speciesText.text ~= "" and type(sbq.customizedSpecies[speciesText.text]) == "table" then
			local species = player.species()
			if species ~= speciesText.text then
				status.setStatusProperty("speciesAnimOverrideData", sbq.currentCustomSpecies)

				local currentEffect = (status.getPersistentEffects("speciesAnimOverride") or {})[1]
				local resultEffect = sbq.speciesFile.customAnimStatus or "speciesAnimOverride"
				if resultEffect == currentEffect then
					world.sendEntityMessage(player.id(), "refreshAnimOverrides")
				else
					status.clearPersistentEffects("speciesAnimOverride")
					status.setPersistentEffects("speciesAnimOverride", { resultEffect })
				end
				init()
				refreshOccupantHolder()
			else
				status.setStatusProperty("speciesAnimOverrideData", sbq.currentCustomSpecies)
				world.sendEntityMessage(player.id(), "refreshAnimOverrides")
			end
		elseif player.isAdmin() and pcall(root.assetJson, ("/species/"..speciesText.text..".species")) then
			world.sendEntityMessage(player.id(), "sbqMysteriousPotionTF", { species = speciesText.text, gender = sbq.currentCustomSpecies.gender })
		else
			status.clearPersistentEffects("speciesAnimOverride")
			status.setStatusProperty("speciesAnimOverrideData", nil)
			status.setStatusProperty("oldSpeciesAnimOverrideData", nil)
			status.setStatusProperty("sbqMysteriousPotionTFDuration", nil)
			status.setStatusProperty("frontarmAnimOverrideArmOffset", nil)
			status.setStatusProperty("backarmAnimOverrideArmOffset", nil)
		end
	end
	function speciesText:onEnter() applySpecies:onClick() end
	function speciesBodyColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesHairColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesFacialHairColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesFacialMaskColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesEmoteColorText:onEnter() sbq.saveSpeciesCustomize() end

	local originalSpecies = world.entitySpecies(player.id())
	sbq.unlockedSpeciesList = {originalSpecies}
	sbq.customizedSpecies = status.statusProperty("sbqCustomizedSpecies") or {}
	sbq.currentCustomSpecies = {}
	for species, data in pairs(sbq.customizedSpecies) do
		if species ~= originalSpecies then
			table.insert(sbq.unlockedSpeciesList, species)
		end
	end
	if player.isAdmin() then
		sbq.unlockedSpeciesList = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	end
	table.sort(sbq.unlockedSpeciesList)
	for i, species in ipairs(sbq.unlockedSpeciesList) do
		if species == player.species() then
			sbq.speciesOverrideIndex = i
		end
	end
	function speciesGenderToggle:onClick()
		local table = {
			male = "female",
			female = "male"
		}
		sbq.currentCustomSpecies.gender = table[sbq.currentCustomSpecies.gender or world.entityGender(player.id())]
		for i, data in ipairs(sbq.speciesFile.genders or {}) do
			if data.name == sbq.currentCustomSpecies.gender then
				sbq.genderTable = data
				speciesGenderToggle:setImage(data.image)
			end
		end
		sbq.saveSpeciesCustomize()
	end
	function sbq.changeSpecies(inc)
		local index = (sbq.speciesOverrideIndex or 1) + inc
		local list = sbq.unlockedSpeciesList
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.speciesOverrideIndex = index
		local selectedSpecies = sbq.unlockedSpeciesList[sbq.speciesOverrideIndex]
		sbq.currentCustomSpecies = sbq.customizedSpecies[selectedSpecies] or {gender = player.gender(), identity = {}}
		if not selectedSpecies then
			sbq.hideSpeciesPanel = true
			return
		end
		local hidePanels = (selectedSpecies ~= originalSpecies) and type(sbq.customizedSpecies[selectedSpecies]) == "table"
		speciesColorPanel:setVisible(hidePanels)
		speciesStylePanel:setVisible(hidePanels)
		speciesManualColorPanel:setVisible(hidePanels)

		local success, speciesFile = pcall(root.assetJson, ("/species/"..selectedSpecies..".species"))
		if success then
			sbq.speciesFile = speciesFile
			speciesText:setText(selectedSpecies)

			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == sbq.currentCustomSpecies.gender then
					sbq.genderTable = data
					for i, type in ipairs(data.hair) do
						if sbq.currentCustomSpecies.identity.hairType == type then
							sbq.hairTypeIndex = i
						end
					end
					for i, type in ipairs(data.facialHair) do
						if sbq.currentCustomSpecies.identity.facialHairType == type then
							sbq.facialHairTypeIndex = i
						end
					end
					for i, type in ipairs(data.facialMask) do
						if sbq.currentCustomSpecies.identity.facialMaskType == type then
							sbq.facialMaskTypeIndex = i
						end
					end
					speciesGenderToggle:setImage(data.image)
				end
			end

			if not hidePanels then return end

			speciesCustomColorText:setText(sbq.currentCustomSpecies.directives)
			speciesBodyColorText:setText(sbq.currentCustomSpecies.identity.bodyDirectives)
			speciesHairColorText:setText(sbq.currentCustomSpecies.identity.hairDirectives)
			speciesFacialHairColorText:setText(sbq.currentCustomSpecies.identity.facialHairDirectives)
			speciesFacialMaskColorText:setText(sbq.currentCustomSpecies.identity.facialMaskDirectives)
			speciesEmoteColorText:setText(sbq.currentCustomSpecies.identity.emoteDirectives)

			speciesHairTypeLabel:setText(sbq.currentCustomSpecies.identity.hairType)
			speciesFacialHairTypeLabel:setText(sbq.currentCustomSpecies.identity.facialHairType)
			speciesFacialMaskTypeLabel:setText(sbq.currentCustomSpecies.identity.facialMaskType)

			speciesBodyColorNameLabel:setText(speciesFile.charGenTextLabels[1])
			speciesHairTypeNameLabel:setText(speciesFile.charGenTextLabels[2])
			local visible = false
			if speciesFile.altOptionAsFacialMask then
				visible = true
				speciesFacialMaskTypeNameLabel:setText(speciesFile.charGenTextLabels[5])
			end
			speciesFacialMaskTypeNameLabel:setVisible(visible)
			speciesFacialMaskTypeLabel:setVisible(visible)
			incSpeciesFacialMaskType:setVisible(visible)
			decSpeciesFacialMaskType:setVisible(visible)

			visible = false
			if speciesFile.altOptionAsUndyColor then
				visible = true
				speciesUndyColorNameLabel:setText(speciesFile.charGenTextLabels[5])
			end
			speciesUndyColorNameLabel:setVisible(visible)
			speciesUndyColorLabel:setVisible(visible)
			incSpeciesUndyColor:setVisible(visible)
			decSpeciesUndyColor:setVisible(visible)

			visible = false
			if speciesFile.headOptionAsFacialhair then
				visible = true
				speciesFacialHairTypeNameLabel:setText(speciesFile.charGenTextLabels[6])
			end
			speciesFacialHairTypeNameLabel:setVisible(visible)
			speciesFacialHairTypeLabel:setVisible(visible)
			incSpeciesFacialHairType:setVisible(visible)
			decSpeciesFacialHairType:setVisible(visible)

			visible = false
			if speciesFile.headOptionAsHairColor then
				visible = true
				speciesHairColorNameLabel:setText(speciesFile.charGenTextLabels[6])
			end
			speciesHairColorNameLabel:setVisible(visible)
			speciesHairColorLabel:setVisible(visible)
			incSpeciesHairColor:setVisible(visible)
			decSpeciesHairColor:setVisible(visible)

			speciesBodyColorLabel:setText(sbq.currentCustomSpecies.identity.bodyColorIndex or 1)
			speciesUndyColorLabel:setText(sbq.currentCustomSpecies.identity.undyColorIndex or 1)
			speciesHairColorLabel:setText(sbq.currentCustomSpecies.identity.hairColorIndex or 1)
		end
	end

	function sbq.changeHairType(inc)
		local index = (sbq.hairTypeIndex or 1) + inc
		local list = sbq.genderTable.hair
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.hairTypeIndex = index
		sbq.currentCustomSpecies.identity.hairType = list[index]
		speciesHairTypeLabel:setText(list[index])
		sbq.saveSpeciesCustomize()
	end
	function decSpeciesHairType:onClick() sbq.changeHairType(-1) end
	function incSpeciesHairType:onClick() sbq.changeHairType(1) end

	function sbq.changeFacialHairType(inc)
		local index = (sbq.facialHairTypeIndex or 1) + inc
		local list = sbq.genderTable.facialHair
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.facialHairTypeIndex = index
		sbq.currentCustomSpecies.identity.facialHairType = list[index]
		speciesFacialHairTypeLabel:setText(list[index])
		sbq.saveSpeciesCustomize()
	end
	function decSpeciesFacialHairType:onClick() sbq.changeFacialHairType(-1) end
	function incSpeciesFacialHairType:onClick() sbq.changeFacialHairType(1) end

	function sbq.changeFacialMaskType(inc)
		local index = (sbq.facialMaskTypeIndex or 1) + inc
		local list = sbq.genderTable.facialMask
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.facialMaskTypeIndex = index
		sbq.currentCustomSpecies.identity.facialMaskType = list[index]
		speciesFacialMaskTypeLabel:setText(list[index])
		sbq.saveSpeciesCustomize()
	end
	function decSpeciesFacialMaskType:onClick() sbq.changeFacialMaskType(-1) end
	function incSpeciesFacialMaskType:onClick() sbq.changeFacialMaskType(1) end

	function sbq.applySpeciesColors()
		local bodyColor = ""
		local undyColor = ""
		local hairColor = ""
		local overrideData = sbq.currentCustomSpecies
		local speciesFile = sbq.speciesFile

		local index = overrideData.identity.undyColorIndex
		local colorTable = (speciesFile.undyColor or {})[index]
		if type(colorTable) == "table" then
			undyColor = "?replace"
			for color, replace in pairs(colorTable) do
				undyColor = undyColor..";"..color.."="..replace
			end
		end
		overrideData.identity.undyColor = undyColor

		local index = overrideData.identity.bodyColorIndex
		local colorTable = (speciesFile.bodyColor or {})[index]
		if type(colorTable) == "table" then
			bodyColor = "?replace"
			for color, replace in pairs(colorTable) do
				bodyColor = bodyColor..";"..color.."="..replace
			end
		end
		overrideData.identity.bodyDirectives = bodyColor

		if speciesFile.altOptionAsUndyColor then
			overrideData.identity.bodyDirectives = overrideData.identity.bodyDirectives..undyColor
		end

		local index = overrideData.identity.hairColorIndex
		local colorTable = (speciesFile.hairColor or {})[index]
		if type(colorTable) == "table" then
			hairColor = "?replace"
			for color, replace in pairs(colorTable) do
				hairColor = hairColor..";"..color.."="..replace
			end
		end
		if speciesFile.headOptionAsHairColor then
			overrideData.identity.hairDirectives = hairColor
		else
			overrideData.identity.hairDirectives = overrideData.identity.bodyDirectives
		end
		if speciesFile.altOptionAsHairColor then
			overrideData.identity.hairDirectives = overrideData.identity.hairDirectives..undyColor
		end
		if speciesFile.hairColorAsBodySubColor then
			overrideData.identity.bodyDirectives = overrideData.identity.bodyDirectives..hairColor
		end
		if speciesFile.bodyColorAsHairSubColor then
			overrideData.identity.hairDirectives = overrideData.identity.hairDirectives..overrideData.identity.bodyDirectives
		end

		overrideData.identity.facialHairDirectives = overrideData.identity.hairDirectives
		if speciesFile.bodyColorAsFacialHairSubColor then
			overrideData.identity.facialMaskDirectives = overrideData.identity.facialMaskDirectives..overrideData.identity.bodyDirectives
		end

		overrideData.identity.facialMaskDirectives = overrideData.identity.hairDirectives
		if speciesFile.bodyColorAsFacialMaskSubColor then
			overrideData.identity.facialMaskDirectives = overrideData.identity.facialMaskDirectives..overrideData.identity.bodyDirectives
		end

		overrideData.identity.emoteDirectives = overrideData.identity.bodyDirectives

		speciesBodyColorText:setText(sbq.currentCustomSpecies.identity.bodyDirectives)
		speciesHairColorText:setText(sbq.currentCustomSpecies.identity.hairDirectives)
		speciesFacialHairColorText:setText(sbq.currentCustomSpecies.identity.facialHairDirectives)
		speciesFacialMaskColorText:setText(sbq.currentCustomSpecies.identity.facialMaskDirectives)
		speciesEmoteColorText:setText(sbq.currentCustomSpecies.identity.emoteDirectives)

		sbq.saveSpeciesCustomize()
	end

	function sbq.changeSpeciesBodyColor(inc)
		local index = (sbq.currentCustomSpecies.identity.bodyColorIndex or 1) + inc
		local list = sbq.speciesFile.bodyColor
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.currentCustomSpecies.identity.bodyColorIndex = index
		speciesBodyColorLabel:setText(index)
		sbq.applySpeciesColors()
	end
	function decSpeciesBodyColor:onClick() sbq.changeSpeciesBodyColor(-1) end
	function incSpeciesBodyColor:onClick() sbq.changeSpeciesBodyColor(1) end

	function sbq.changeSpeciesUndyColor(inc)
		local index = (sbq.currentCustomSpecies.identity.undyColorIndex or 1) + inc
		local list = sbq.speciesFile.undyColor
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.currentCustomSpecies.identity.undyColorIndex = index
		speciesUndyColorLabel:setText(index)
		sbq.applySpeciesColors()
	end
	function decSpeciesUndyColor:onClick() sbq.changeSpeciesUndyColor(-1) end
	function incSpeciesUndyColor:onClick() sbq.changeSpeciesUndyColor(1) end

	function sbq.changeSpeciesHairColor(inc)
		local index = (sbq.currentCustomSpecies.identity.hairColorIndex or 1) + inc
		local list = sbq.speciesFile.hairColor
		if index > #list then
			index = 1
		elseif index < 1 then
			index = #list
		end
		sbq.currentCustomSpecies.identity.hairColorIndex = index
		speciesHairColorLabel:setText(index)
		sbq.applySpeciesColors()
	end
	function decSpeciesHairColor:onClick() sbq.changeSpeciesHairColor(-1) end
	function incSpeciesHairColor:onClick() sbq.changeSpeciesHairColor(1) end

	function speciesCustomColorText:onEnter() sbq.saveSpeciesCustomize() end


	function sbq.saveSpeciesCustomize()
		sbq.currentCustomSpecies.identity.bodyDirectives = speciesBodyColorText.text
		sbq.currentCustomSpecies.identity.hairDirectives = speciesHairColorText.text
		sbq.currentCustomSpecies.identity.facialHairDirectives = speciesFacialHairColorText.text
		sbq.currentCustomSpecies.identity.facialMaskDirectives = speciesFacialMaskColorText.text
		sbq.currentCustomSpecies.identity.emoteDirectives = speciesEmoteColorText.text
		sbq.currentCustomSpecies.directives = speciesCustomColorText.text

		status.setStatusProperty("sbqCustomizedSpecies", sbq.customizedSpecies )
		applySpecies:onClick()
	end

	sbq.changeSpecies(0)
end

--------------------------------------------------------------------------------------------------

function sbq.saveDigestedPrey()
	status.setStatusProperty("sbqStoredDigestedPrey", sbq.storedDigestedPrey)
end
