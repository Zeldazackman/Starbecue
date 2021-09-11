require("/interface/scripted/pvso/pvsoSettings.lua")

function init()
	p.vsoSettings = player.getProperty("vsoSettings") or {}
	p.vso = config.getParameter( "vso" )
	p.occupant = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	p.powerMultiplier = config.getParameter( "powerMultiplier" )
	p.config = root.assetJson( "/vehicles/spov/pvso_general.config")
	p.vsoConfig = root.assetJson( "/vehicles/spov/"..p.vsoname.."/"..p.vsoname..".vehicle" ).vso

	p.config.defaultSettings.replaceColors = p.vsoConfig.defaultReplaceColors or {}
	settings = sb.jsonMerge(p.config.defaultSettings, p.vsoSettings[p.vsoname] or {})

	setIconDirectives()

	p.replaceColors = p.vsoConfig.replaceColors
	p.replaceSkin = p.vsoConfig.replaceSkin

	setLabels()
end

function update(dt)
	checkRefresh(dt)
end

function p.setColorReplaceDirectives()
	if p.vsoConfig.replaceColors ~= nil then
		local colorReplaceString = "?replace"
		for i, colorGroup in ipairs(p.vsoConfig.replaceColors) do
			local basePalette = colorGroup[1]
			local replacePalette = colorGroup[settings.replaceColors[i] + 1]

			if settings.customDirectives then
				replacePalette = settings.customPalette[i]
			end

			if (replacePalette == nil) or (replacePalette == {}) then
				replacePalette = colorGroup[p.vsoConfig.defaultReplaceColors[i] + 1]
			end

			for j, color in ipairs(replacePalette) do
				colorReplaceString = colorReplaceString..";"..basePalette[j].."="..color
			end
		end
		settings.directives = colorReplaceString
	end
end

function settingsMenu()
	saveSettings()
	world.sendEntityMessage(
		player.id(), "openPVSOInterface", p.vsoname.."Settings",
		{ vso = p.vso, occupants = p.occupant, maxOccupants = p.maxOccupants, powerMultiplier = p.powerMultiplier }, false, p.vso
	)
end

function adjustColor(i, inc)
	if p.replaceColors == nil then return end
	settings.replaceColors[i] = (settings.replaceColors[i] + inc)
	if settings.replaceColors[i] < 1 then
		settings.replaceColors[i] = #p.replaceColors[i] -1
	elseif settings.replaceColors[i] > #p.replaceColors[i] -1 then
		settings.replaceColors[i] = 1
	end
	widget.setText("labelColor"..i, tostring(settings.replaceColors[i]))
	p.setColorReplaceDirectives()
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
	widget.setText("label"..part, p.replaceSkin[part].skins[i])
	saveSettings()
end

function setLabels()
	for i = 1, #settings.replaceColors do
		widget.setText("labelColor"..i, tostring(settings.replaceColors[i]))
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
