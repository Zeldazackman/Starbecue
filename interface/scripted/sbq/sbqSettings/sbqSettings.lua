
---@diagnostic disable:undefined-global

require( "/lib/stardust/json.lua" )

sbq = {
	extraTabs = root.assetJson("/interface/scripted/sbq/sbqSettings/sbqSettingsTabs.json"),
	config = root.assetJson( "/sbqGeneral.config" ),
	overrideSettings = {}
}

require("/scripts/SBQ_RPC_handling.lua")
require("/scripts/speciesAnimOverride_player_species.lua")
require("/interface/scripted/sbq/sbqSettings/sbqSettingsLocationPanel.lua")
require("/interface/scripted/sbq/sbqSettings/sbqSettingsEffectsPanel.lua")

function sbq.getPatronsString()
	local patronsString = ""
	for _, patron in ipairs(root.assetJson("/patrons.json")) do
		patronsString = patronsString..patron.."^reset;\n"
	end
	return patronsString
end
sbq.patronsString = sbq.getPatronsString()

function sbq.getInitialData()
	sbq.sbqSettings = player.getProperty("sbqSettings") or {}

	sbq.sbqCurrentData = player.getProperty("sbqCurrentData") or {}
	sbq.lastSpecies = sbq.sbqCurrentData.species
	sbq.lastType = sbq.sbqCurrentData.type

	sbq.predatorEntity = sbq.sbqCurrentData.id
end

function sbq.getHelpTab()
	if sbq.extraTabs.speciesHelpTabs[sbq.sbqCurrentData.species] ~= nil then
		sbq.speciesHelpTab = mainTabField:newTab( sbq.extraTabs.speciesHelpTabs[sbq.sbqCurrentData.species] )
	end
end

function sbq.getPlayerOccupantHolderData()
	local species = player.species()
	local registry = root.assetJson("/humanoid/sbqDataRegistry.config")
	local path = registry[species] or "/humanoid/sbqData.config"
	if path:sub(1,1) ~= "/" then
		path = "/humanoid/"..species.."/"..path
	end
	sbq.predatorConfig = root.assetJson(path).sbqData


	local mergeConfigs = sbq.predatorConfig.merge or {}
	local configs = { sbq.predatorConfig }
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
	sbq.predatorConfig = finalConfig
	sbq.predatorConfig.scripts = scripts
end

function init()

	sbq.getInitialData()

	sbq.globalSettings = sb.jsonMerge(sbq.config.globalSettings, sbq.sbqSettings.global)

	if sbq.sbqCurrentData.species ~= nil then
		if sbq.sbqCurrentData.species == "sbqOccupantHolder" then
			sbq.getPlayerOccupantHolderData()
		else
			sbq.predatorConfig = root.assetJson("/vehicles/sbq/"..sbq.sbqCurrentData.species.."/"..sbq.sbqCurrentData.species..".vehicle").sbqData or {}
		end
		sbq.predatorSettings = sb.jsonMerge(sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.predatorConfig.defaultSettings or {}), sbq.sbqSettings[sbq.sbqCurrentData.species] or {}), sbq.globalSettings)
	else
		sbq.getPlayerOccupantHolderData()
		sbq.predatorSettings = sb.jsonMerge(sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.predatorConfig.defaultSettings or {}), sbq.sbqSettings.sbqOccupantHolder or {}), sbq.globalSettings)
	end

	sbq.locationPanel()
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

	if sbq.speciesSettingsTab ~= nil then
		sbq.speciesSettingsTab:setVisible(false)
		sbq.speciesSettingsTab = nil
	end
	local species = sbq.sbqCurrentData.species
	local playerSpecies = player.species()
	if (species == "sbqOccupantHolder" or species == nil) and sbq.extraTabs.speciesSettingsTabs[playerSpecies] ~= nil then
		species = playerSpecies
	end
	if sbq.extraTabs.speciesSettingsTabs[species] ~= nil then
		sbq.speciesSettingsTab = mainTabField:newTab( sbq.extraTabs.speciesSettingsTabs[species].tab )
		sbq.setIconDirectives()
		if sbq.extraTabs.speciesSettingsTabs[species].scripts ~= nil then
			for _, script in ipairs(sbq.extraTabs.speciesSettingsTabs[species].scripts) do
				require(script)
			end
		end
	end

	if sbq.speciesHelpTab ~= nil then
		sbq.speciesHelpTab:setVisible(false)
		sbq.speciesHelpTab = nil
	end

	sbq.getHelpTab()

	if sbq.helpTab ~= nil then
		sbq.helpTab:setVisible(false)
		sbq.helpTab = nil
	end

	sbq.helpTab = mainTabField:newTab( sbq.extraTabs.helpTab )
	patronsLabel:setText(sbq.patronsString)

	if root.itemConfig("vorechipkit") ~= nil then
		helpTabs:newTab(sbq.extraTabs.SSVMOverridesTab)
		SSVMTargetCreatures:setChecked(status.statusProperty("sbqSSVMTargeting") == "creature")

		function SSVMTargetCreatures:onClick()
			if SSVMTargetCreatures.checked then
				status.setStatusProperty("sbqSSVMTargeting", "creature")
			else
				status.setStatusProperty("sbqSSVMTargeting", nil)
			end
		end
	end

	escapeValue:setText(tostring(sbq.globalSettings.escapeDifficulty or 0))

	for setting, value in pairs(sbq.predatorSettings) do
		local button = _ENV[setting]
		if button ~= nil and type(value) == "boolean" then
			button:setChecked(value)
			function button:onClick()
				sbq.changePredatorSetting(setting, button.checked)
			end
		end
	end
	for setting, value in pairs(sbq.globalSettings) do
		local button = _ENV[setting]
		if button ~= nil and type(value) == "boolean" then
			button:setChecked(value)
			function button:onClick()
				sbq.changeGlobalSetting(setting, button.checked)
			end
		end
	end

	function hammerspace:onClick() -- only one that has unique logic
		sbq.changeGlobalSetting("hammerspace", hammerspace.checked)
		sbq.locationPanel()
	end

	require("/interface/scripted/sbq/sbqSettings/sbqResetSettings.lua")
end
local init = init

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

	sbq.saveSettings()
end

function sbq.changePredatorSetting(settingname, settingvalue)
	sbq.predatorSettings[settingname] = settingvalue

	sbq.saveSettings()
end

function sbq.changeEscapeModifier(inc)
	sbq.changeGlobalSetting("escapeDifficulty", (sbq.globalSettings.escapeDifficulty or 0) + inc)
	escapeValue:setText(tostring(sbq.globalSettings.escapeDifficulty or 0))
end

function sbq.changePreySetting(settingname, settingvalue)
	sbq.sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	sbq.sbqPreyEnabled[settingname] = settingvalue
	status.setStatusProperty("sbqPreyEnabled", sbq.sbqPreyEnabled)
end

function sbq.setIconDirectives()
	if sbq.speciesSettingsTab ~= nil then
		sbq.speciesSettingsTab:setTitle("Config", "/vehicles/sbq/"..sbq.sbqCurrentData.species.."/skins/"..((sbq.predatorSettings.skinNames or {}).head or "default").."/icon.png"..(sbq.predatorSettings.directives or ""))
	end
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

function decEscape:onClick()
	sbq.changeEscapeModifier(-1)
end

function incEscape:onClick()
	sbq.changeEscapeModifier(1)
end

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
	function decSpecies:onClick()
		sbq.changeSpecies(-1)
	end

	function incSpecies:onClick()
		sbq.changeSpecies(1)
	end

	function applySpecies:onClick()
		if speciesText.text ~= "" and type(sbq.customizedSpecies[speciesText.text]) == "table" then
			status.clearPersistentEffects("speciesAnimOverride")
			status.setStatusProperty("speciesAnimOverrideData", sbq.currentCustomSpecies)
			status.setPersistentEffects("speciesAnimOverride", {  sbq.currentCustomSpecies.customAnimStatus or "speciesAnimOverride"})
		else
			status.clearPersistentEffects("speciesAnimOverride")
			status.setStatusProperty("speciesAnimOverrideData", nil)
			status.setStatusProperty("oldSpeciesAnimOverrideData", nil)
			status.setStatusProperty("sbqMysteriousPotionTF", nil)
			status.setStatusProperty("sbqMysteriousPotionTFDuration", nil)
		end
	end
	function speciesText:onEnter() applySpecies:onClick() end
	function speciesBodyColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesHairColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesFacialHairColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesFacialMaskColorText:onEnter() sbq.saveSpeciesCustomize() end
	function speciesEmoteColorText:onEnter() sbq.saveSpeciesCustomize() end

	sbq.unlockedSpeciesList = {}
	sbq.customizedSpecies = status.statusProperty("sbqCustomizedSpecies") or {}
	sbq.currentCustomSpecies = {}
	local originalSpecies = world.entitySpecies(player.id())
	for species, data in pairs(sbq.customizedSpecies) do
		if species ~= originalSpecies then
			table.insert(sbq.unlockedSpeciesList, species)
		end
	end
	table.sort(sbq.unlockedSpeciesList)
	sbq.currentPlayerSpecies = player.species()
	for i, species in ipairs(sbq.unlockedSpeciesList) do
		if species == player.species then
			sbq.speciesOverrideIndex = i
		end
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
		sbq.currentCustomSpecies = sbq.customizedSpecies[selectedSpecies]
		if not selectedSpecies then
			sbq.hideSpeciesPanel = true
			return
		end

		local success, speciesFile = pcall(root.assetJson, ("/species/"..selectedSpecies..".species"))
		if success then
			sbq.speciesFile = speciesFile
			speciesText:setText(selectedSpecies)
			speciesCustomColorText:setText(sbq.currentCustomSpecies.directives)
			speciesBodyColorText:setText(sbq.currentCustomSpecies.identity.bodyDirectives)
			speciesHairColorText:setText(sbq.currentCustomSpecies.identity.hairDirectives)
			speciesFacialHairColorText:setText(sbq.currentCustomSpecies.identity.facialHairDirectives)
			speciesFacialMaskColorText:setText(sbq.currentCustomSpecies.identity.facialMaskDirectives)
			speciesEmoteColorText:setText(sbq.currentCustomSpecies.identity.emoteDirectives)

			speciesHairTypeLabel:setText(sbq.currentCustomSpecies.identity.hairType)
			speciesFacialHairTypeLabel:setText(sbq.currentCustomSpecies.identity.facialHairType)
			speciesFacialMaskTypeLabel:setText(sbq.currentCustomSpecies.identity.facialMaskType)
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
				end
			end
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


if mainTabField.tabs.globalPreySettings ~= nil then
	sbq.sbqPreyEnabled = sb.jsonMerge(sbq.config.defaultPreyEnabled.player, status.statusProperty("sbqPreyEnabled") or {})

	for setting, value in pairs(sbq.sbqPreyEnabled) do
		local button = _ENV[setting]
		if button ~= nil and type(value) == "boolean" then
			button:setChecked(value)
			function button:onClick()
				sbq.changePreySetting(setting, button.checked)
			end
		end
	end

	function digestImmunity:onClick()
		sbq.changePreySetting("digestImmunity", digestImmunity.checked)
		if digestImmunity.checked then
			status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
		else
			status.clearPersistentEffects("digestImmunity")
		end
	end

	function cumDigestImmunity:onClick()
		sbq.changePreySetting("cumDigestImmunity", cumDigestImmunity.checked)
		if cumDigestImmunity.checked then
			status.setPersistentEffects("cumDigestImmunity", {"sbqCumDigestImmunity"})
		else
			status.clearPersistentEffects("cumDigestImmunity")
		end
	end
end
--------------------------------------------------------------------------------------------------
