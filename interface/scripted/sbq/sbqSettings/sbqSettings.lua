
---@diagnostic disable:undefined-global

require( "/lib/stardust/json.lua" )

sbq = {}

sbq.extraTabs = root.assetJson("/interface/scripted/sbq/sbqSettings/sbqSettingsTabs.json")
sbq.customizeTab = mainTabField:newTab( sbq.extraTabs.customizeTab )
sbq.helpTab = mainTabField:newTab( sbq.extraTabs.helpTab )

function getPatronsString()
	local patronsString = ""
	for _, patron in ipairs(root.assetJson("/patrons.json")) do
		patronsString = patronsString..patron.."\n"
	end
	return patronsString
end
patronsLabel:setText(getPatronsString())

function init()
	sbq.sbqSettings = player.getProperty("sbqSettings") or {}

	sbq.sbqCurrentData = player.getProperty("sbqCurrentData") or {}
	sbq.lastSpecies = sbq.sbqCurrentData.species

	sbq.loungingIn = player.loungingIn()

	sbq.config = root.assetJson( "/sbqGeneral.config" )

	sbq.globalSettings = sbq.sbqSettings.global or {}

	if sbq.speciesHelpTab ~= nil then
		sbq.speciesHelpTab:delete()
	end
	if sbq.extraTabs.speciesHelpTabs[sbq.sbqCurrentData.species] ~= nil then
		sbq.speciesHelpTab = mainTabField:newTab( sbq.extraTabs.speciesHelpTabs[sbq.sbqCurrentData.species] )
	end

	if sbq.sbqCurrentData.species ~= nil then
		sbq.predatorConfig = root.assetJson("/vehicles/sbq/"..sbq.sbqCurrentData.species.."/"..sbq.sbqCurrentData.species..".vehicle").sbqData or {}
		sbq.predatorSettings = sb.jsonMerge(sb.jsonMerge(sb.jsonMerge(sbq.config.defaultSettings, sbq.predatorConfig.defaultSettings or {}), sbq.sbqSettings[sbq.sbqCurrentData.species] or {}), sbq.globalSettings)
	else
		sbq.predatorConfig = {}
		sbq.predatorSettings = sb.jsonMerge(sbq.config.defaultSettings, sbq.globalSettings)
	end

	if (sbq.predatorConfig.replaceColors ~= nil or sbq.predatorConfig.replaceSkin ~= nil) and sbq.sbqCurrentData.type == "driver" then
		sbq.customizeTab:setVisible(true)
		if sbq.predatorConfig.replaceColors ~= nil then
			colorsScrollArea:clearChildren()
			sbq.customizeColorsLayout = {}
			for i, colors in ipairs(sbq.predatorConfig.replaceColors) do
				sbq.customizeColorsLayout[i] = { layout = colorsScrollArea:addChild({ type = "layout", mode = "horizontal", children = {} }) }
				sbq.customizeColorsLayout[i].fullbright = sbq.customizeColorsLayout[i].layout:addChild({ type = "checkBox", id = "color"..i.."Fullbright", checked = (sbq.predatorSettings.fullbright or {})[i] or (sbq.predatorConfig.defaultSettings.fullbright or {})[i], toolTip = "Fullbright" })
				sbq.customizeColorsLayout[i].prev = sbq.customizeColorsLayout[i].layout:addChild({ type = "iconButton", id = "color"..i.."Prev", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png"})
				sbq.customizeColorsLayout[i].textBox = sbq.customizeColorsLayout[i].layout:addChild({ type = "textBox", id = "color"..i.."TextEntry", toolTip = "Edit the text here to define a custom palette, make sure to match the formatting." })
				sbq.customizeColorsLayout[i].next = sbq.customizeColorsLayout[i].layout:addChild({ type = "iconButton", id = "color"..i.."Next", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png"})
				sbq.customizeColorsLayout[i].label = sbq.customizeColorsLayout[i].layout:addChild({ type = "label", text = (sbq.predatorConfig.replaceColorNames or {})[i] or "Color "..i, size = {48, 10}})
				sbq.customizeColorsLayout[i].textBox:setText(sb.printJson( ( (sbq.predatorSettings.replaceColorTable or {})[i]) or ( sbq.predatorConfig.replaceColors[i][ (sbq.predatorSettings.replaceColors[i] or sbq.predatorConfig.defaultSettings.replaceColors[i] or 1 ) + 1 ] ) ) )
				local prevFunc = sbq.customizeColorsLayout[i].prev
				local textboxFunc = sbq.customizeColorsLayout[i].textBox
				local nextFunc = sbq.customizeColorsLayout[i].next
				local fullbrightFunc = sbq.customizeColorsLayout[i].fullbright

				function fullbrightFunc:onClick()
					sbq.predatorSettings.fullbright[i] = fullbrightFunc.checked
					sbq.saveSettings()
				end
				function prevFunc:onClick()
					sbq.changeColorSetting(sbq.customizeColorsLayout[i].textBox, i, -1)
				end
				function textboxFunc:onTextChanged()
					local decoded = json.decode(textboxFunc.text)
					if type(decoded) == "table" then
						sbq.predatorSettings.replaceColorTable[i] = decoded
					else
						sbq.predatorSettings.replaceColorTable[i] = nil
					end
					sbq.setColorReplaceDirectives()
					sbq.saveSettings()
				end
				function nextFunc:onClick()
					sbq.changeColorSetting(sbq.customizeColorsLayout[i].textBox, i, 1)
				end
			end
		end
		if sbq.predatorConfig.replaceSkin then
			skinsScrollArea:clearChildren()
			sbq.customizeSkinsLayout = {}
			for part, _ in pairs(sbq.predatorConfig.replaceSkin) do
				sbq.customizeSkinsLayout[part] = { layout = skinsScrollArea:addChild({ type = "layout", mode = "horizontal", children = {} }) }
				sbq.customizeSkinsLayout[part].prev = sbq.customizeSkinsLayout[part].layout:addChild({ type = "iconButton", id = part.."Prev", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png"})
				sbq.customizeSkinsLayout[part].textBox = sbq.customizeSkinsLayout[part].layout:addChild({ type = "textBox", id = part.."TextEntry", toolTip = "Edit the text here to define a specific skin, if it exists" })
				sbq.customizeSkinsLayout[part].next = sbq.customizeSkinsLayout[part].layout:addChild({ type = "iconButton", id = part.."Next", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png"})
				sbq.customizeSkinsLayout[part].label = sbq.customizeSkinsLayout[part].layout:addChild({ type = "label", text = sbq.predatorConfig.replaceSkin[part].name, size = {48, 10}})
				sbq.customizeSkinsLayout[part].textBox:setText((sbq.predatorSettings.skinNames or {})[part] or "default")
				local prevFunc = sbq.customizeSkinsLayout[part].prev
				local textboxFunc = sbq.customizeSkinsLayout[part].textBox
				local nextFunc = sbq.customizeSkinsLayout[part].next

				function prevFunc:onClick()
					sbq.changeSkinSetting(textboxFunc, part, -1)
				end
				function textboxFunc:onTextChanged()
					if textboxFunc.text ~= nil and textboxFunc.text ~= "" then
						for i, partname in ipairs(sbq.predatorConfig.replaceSkin[part].parts) do
							sbq.predatorSettings.skinNames[partname] = textboxFunc.text
						end
						sbq.saveSettings()
					end
				end
				function nextFunc:onClick()
					sbq.changeSkinSetting(textboxFunc, part, 1)
				end
			end
		end
	else
		sbq.customizeTab:setVisible(false)
	end

	sbq.predator = sbq.sbqCurrentData.species or "noPred"

	BENone:selectValue(sbq.globalSettings.bellyEffect or "sbqRemoveBellyEffects")
	EMEasy:selectValue(sbq.globalSettings.escapeModifier or "normal")

	displayDigest:setChecked(sbq.globalSettings.displayDigest or false)
	bellySounds:setChecked(sbq.globalSettings.bellySounds or sbq.globalSettings.bellySounds == nil)

	sbq.sbqPreyEnabled = sb.jsonMerge(sbq.config.defaultPreyEnabled.player, status.statusProperty("sbqPreyEnabled") or {})

	preyEnabled:setChecked(sbq.sbqPreyEnabled.enabled)

	oralVore:setChecked(sbq.sbqPreyEnabled.oralVore)
	tailVore:setChecked(sbq.sbqPreyEnabled.tailVore)
	absorbVore:setChecked(sbq.sbqPreyEnabled.absorbVore)

	analVore:setChecked(sbq.sbqPreyEnabled.analVore)
	cockVore:setChecked(sbq.sbqPreyEnabled.cockVore)
	breastVore:setChecked(sbq.sbqPreyEnabled.breastVore)
	unbirth:setChecked(sbq.sbqPreyEnabled.unbirth)

	held:setChecked(sbq.sbqPreyEnabled.held)


end
local init = init

function update()
	sbq.sbqCurrentData = player.getProperty("sbqCurrentData") or {}
	if sbq.sbqCurrentData.species ~= sbq.lastSpecies then
		init()
	end
end

--------------------------------------------------------------------------------------------------

function sbq.saveSettings()
	if sbq.loungingIn ~= nil and sbq.sbqCurrentData.type == "driver" then
		world.sendEntityMessage( sbq.loungingIn, "settingsMenuSet", sbq.predatorSettings )
	end

	sbq.sbqSettings[sbq.predator] = sbq.predatorSettings
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

function sbq.setBellyEffect()
	sbq.changeGlobalSetting("bellyEffect", BENone:getGroupValue())
end

function sbq.setEscapeModifier()
	sbq.changeGlobalSetting("escapeModifier", EMEasy:getGroupValue())
end

function sbq.changePreySetting(settingname, settingvalue)
	sbq.sbqPreyEnabled[settingname] = settingvalue
	status.setStatusProperty("sbqPreyEnabled", sbq.sbqPreyEnabled)
end

function sbq.setIconDirectives()
end

function sbq.changeColorSetting(textbox, color, inc)
	if sbq.predatorConfig.replaceColors == nil then return end

	sbq.predatorSettings.replaceColors[color] = ((sbq.predatorSettings.replaceColors[color] or sbq.predatorConfig.defaultSettings.replaceColors[color]) + inc)

	if sbq.predatorSettings.replaceColors[color] < 1 then
		sbq.predatorSettings.replaceColors[color] = (#sbq.predatorConfig.replaceColors[color] -1)
	elseif sbq.predatorSettings.replaceColors[color] > (#sbq.predatorConfig.replaceColors[color] -1) then
		sbq.predatorSettings.replaceColors[color] = 1
	end

	local colorTable = sbq.predatorConfig.replaceColors[color][ (sbq.predatorSettings.replaceColors[color] or sbq.predatorConfig.defaultSettings.replaceColors[color] or 1 ) + 1 ]

	textbox:setText(sb.printJson(colorTable))

	sbq.predatorSettings.replaceColorTable[color] = colorTable

	sbq.setColorReplaceDirectives()
	sbq.saveSettings()
end

function sbq.setColorReplaceDirectives()
	if sbq.predatorConfig.replaceColors ~= nil then
		local colorReplaceString = ""
		for i, colorGroup in ipairs(sbq.predatorConfig.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[(sbq.predatorSettings.replaceColors[i] or sbq.predatorConfig.defaultSettings.replaceColors[i] or 1) + 1]
			local fullbright = sbq.predatorSettings.fullbright[i]

			if sbq.predatorSettings.replaceColorTable ~= nil and sbq.predatorSettings.replaceColorTable[i] ~= nil then
				replacePalette = sbq.predatorSettings.replaceColorTable[i]
			else
				replacePalette = colorGroup[sbq.predatorConfig.defaultSettings.replaceColors[i] + 1]
			end

			for j, color in ipairs(replacePalette) do
				if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
					color = color.."fb"
				end
				colorReplaceString = colorReplaceString.."?replace;"..basePalette[j].."="..color
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

function EMEasy:onClick()
	sbq.setEscapeModifier()
end

function EMNormal:onClick()
	sbq.setEscapeModifier()
end

function EMHard:onClick()
	sbq.setEscapeModifier()
end

function EMImpossible:onClick()
	sbq.setEscapeModifier()
end

--------------------------------------------------------------------------------------------------

function displayDigest:onClick()
	sbq.changeGlobalSetting("displayDigest", displayDigest.checked)
end

function bellySounds:onClick()
	sbq.changeGlobalSetting("bellySounds", bellySounds.checked)
end

--------------------------------------------------------------------------------------------------

function preyEnabled:onClick()
	sbq.changePreySetting("enabled", preyEnabled.checked)
end

function oralVore:onClick()
	sbq.changePreySetting("oralVore", oralVore.checked)
end

function tailVore:onClick()
	sbq.changePreySetting("tailVore", tailVore.checked)
end

function absorbVore:onClick()
	sbq.changePreySetting("absorbVore", absorbVore.checked)
end

function analVore:onClick()
	sbq.changePreySetting("analVore", analVore.checked)
end

function cockVore:onClick()
	sbq.changePreySetting("cockVore", cockVore.checked)
end

function breastVore:onClick()
	sbq.changePreySetting("breastVore", breastVore.checked)
end

function unbirth:onClick()
	sbq.changePreySetting("unbirth", unbirth.checked)
end

function held:onClick()
	sbq.changePreySetting("held", held.checked)
end

--------------------------------------------------------------------------------------------------
