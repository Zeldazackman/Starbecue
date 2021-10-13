require("/interface/scripted/sbq/sbqSettings.lua")

function init()
	p.sbqSettings = player.getProperty("sbqSettings") or {}
	p.vehicle = config.getParameter( "vehicle" )
	p.occupant = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	p.powerMultiplier = config.getParameter( "powerMultiplier" )
	p.config = root.assetJson( "/sbqGeneral.config")
	p.sbqConfig = root.assetJson( "/vehicles/sbq/"..world.entityName(p.vehicle).."/"..world.entityName(p.vehicle)..".vehicle" ).sbqData

	settings = sb.jsonMerge(sb.jsonMerge(p.config.defaultSettings, p.sbqConfig.defaultSettings or {}), p.sbqSettings[world.entityName(p.vehicle)] or {})

	setIconDirectives()

	p.replaceColors = p.sbqConfig.replaceColors
	p.replaceSkin = p.sbqConfig.replaceSkin

	setLabels()
end

function update(dt)
	checkRefresh(dt)
end

function p.setColorReplaceDirectives()
	if p.sbqConfig.replaceColors ~= nil then
		local colorReplaceString = ""
		for i, colorGroup in ipairs(p.sbqConfig.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[(settings.replaceColors[i] or p.sbqConfig.defaultSettings.replaceColors[i] or 1) + 1]

			if settings.customDirectives then
				replacePalette = settings.customPalette[i]
			end

			if (replacePalette == nil) or (replacePalette == {}) then
				replacePalette = colorGroup[p.sbqConfig.defaultReplaceColors[i] + 1]
			end

			for j, color in ipairs(replacePalette) do
				colorReplaceString = colorReplaceString.."?replace;"..basePalette[j].."="..color
			end
		end
		settings.directives = colorReplaceString
	end
end

function settingsMenu()
	saveSettings()
	world.sendEntityMessage(
		player.id(), "sbqOpenInterface", world.entityName(p.vehicle).."Settings",
		{ vehicle = p.vehicle, occupants = p.occupant, maxOccupants = p.maxOccupants, powerMultiplier = p.powerMultiplier }, false, p.vehicle
	)
end

function adjustColor(i, inc)
	if p.replaceColors == nil then return end
	settings.replaceColors[i] = ((settings.replaceColors[i] or p.sbqConfig.defaultSettings.replaceColors[i]) + inc)
	if settings.replaceColors[i] < 1 then
		settings.replaceColors[i] = (#p.replaceColors[i] -1)
	elseif settings.replaceColors[i] > (#p.replaceColors[i] -1) then
		settings.replaceColors[i] = 1
	end
	widget.setText("labelColor"..i, tostring(settings.replaceColors[i]))
	p.setColorReplaceDirectives()
	saveSettings()
end

function adjustFullbright(i)
	local value = widget.getChecked( "glowColor"..i )
	settings.fullbright[i] = value
	saveSettings()
end

function adjustSkin(part, inc)
	if p.replaceSkin == nil or p.replaceSkin[part] == nil then return end
	local i = settings.replaceSkin[part] or 1
	i = i + inc
	if i < 1 then
		i = #p.replaceSkin[part].skins
	elseif i > #p.replaceSkin[part].skins then
		i = 1
	end
	settings.replaceSkin[part] = i

	for _, animPart in ipairs(p.replaceSkin[part].parts) do
		if not settings.skinNames then settings.skinNames = {} end
		settings.skinNames[animPart] = p.replaceSkin[part].skins[i]
	end

	widget.setText("label"..part, p.replaceSkin[part].skins[i])
	saveSettings()
end

function setLabels()
	for i = 1, #settings.replaceColors do
		widget.setText("labelColor"..i, tostring(settings.replaceColors[i]))
		widget.setChecked("glowColor"..i, settings.fullbright[i] or false)
	end
	for part, data in pairs(p.replaceSkin) do
		local i = settings.replaceSkin[part] or 1
		widget.setText("label"..part, data.skins[i])
	end
end

function prevColor1()
	adjustColor(1, -1)
end

function prevColor2()
	adjustColor(2, -1)
end

function prevColor3()
	adjustColor(3, -1)
end

function prevColor4()
	adjustColor(4, -1)
end

function prevColor5()
	adjustColor(5, -1)
end

function prevColor6()
	adjustColor(6, -1)
end

function nextColor1()
	adjustColor(1, 1)
end

function nextColor2()
	adjustColor(2, 1)
end

function nextColor3()
	adjustColor(3, 1)
end

function nextColor4()
	adjustColor(4, 1)
end

function nextColor5()
	adjustColor(5, 1)
end

function nextColor6()
	adjustColor(6, 1)
end

function glowColor1()
	adjustFullbright(1)
end

function glowColor2()
	adjustFullbright(2)
end

function glowColor3()
	adjustFullbright(3)
end

function glowColor4()
	adjustFullbright(4)
end

function glowColor5()
	adjustFullbright(5)
end

function glowColor6()
	adjustFullbright(6)
end

function prevhead()
	adjustSkin("head", -1)
end

function nexthead()
	adjustSkin("head", 1)
end

function prevbody()
	adjustSkin("body", -1)
end

function nextbody()
	adjustSkin("body", 1)
end

function prevlegs()
	adjustSkin("legs", -1)
end

function nextlegs()
	adjustSkin("legs", 1)
end

function prevtail()
	adjustSkin("tail", -1)
end

function nexttail()
	adjustSkin("tail", 1)
end
