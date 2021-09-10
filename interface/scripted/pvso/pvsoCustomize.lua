p = {}

function init()
	p.vsoSettings = player.getProperty("vsoSettings") or {}
	p.vso = config.getParameter( "vso" )
	p.occupant = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	p.powerMultiplier = config.getParameter( "powerMultiplier" )

	settings = sb.jsonMerge( root.assetJson( "/vehicles/spov/pvso_general.config:defaultSettings"), p.vsoSettings[p.vsoname] or {})
	setIconDirectives()

	p.vsoConfig = root.assetJson( "/vehicles/spov/"..p.vsoname.."/"..p.vsoname..".vehicle" ).vso
	p.replaceColors = p.vsoConfig.replaceColors
	p.replaceSkin = p.vsoConfig.replaceSkin

	setLabels()
end

function update(dt)
	checkRefresh(dt)
end

p.refreshtime = 0
function checkRefresh(dt)
	if p.refreshtime >= 0.1 and p.rpc == nil then
		p.rpc = world.sendEntityMessage( p.vso, "settingsMenuRefresh")
	elseif p.rpc ~= nil and p.rpc:finished() then
		if p.rpc:succeeded() then
			local result = p.rpc:result()
			if result ~= nil then
				p.occupant = result.occupants
				p.powerMultiplier = result.powerMultiplier
				settings = result.settings
				setIconDirectives()
				p.refreshtime = 0
				p.refreshed = true
			end
		else
			sb.logError( "Couldn't refresh settings." )
			sb.logError( p.rpc:error() )
		end
		p.rpc = nil
	else
		p.refreshtime = p.refreshtime + dt
	end
end

function setIconDirectives()
	local species = p.vsoname
	local skin = settings.skinNames.head or "default"
	local directives = settings.directives or ""
	widget.setImage("icon", "/vehicles/spov/"..species.."/spov/"..skin.."/icon.png"..directives)
end

function settingsMenu()
	world.sendEntityMessage(
		player.id(), "openPVSOInterface", p.vsoname.."Settings",
		{ vso = p.vso, occupants = p.occupant, maxOccupants = p.maxOccupants, powerMultiplier = p.powerMultiplier }, false, p.vso
	)
end

function saveSettings()
	world.sendEntityMessage( p.vso, "settingsMenuSet", settings )
	p.vsoSettings[p.vsoname] = settings
	player.setProperty( "vsoSettings", p.vsoSettings )
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
