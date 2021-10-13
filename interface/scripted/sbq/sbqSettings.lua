p = {}

p.bellyEffects = {
	[-1] = "sbqRemoveBellyEffects", [0] = "sbqHeal", [1] = "sbqDigest", [2] = "sbqSoftDigest",
	["sbqRemoveBellyEffects"] = -1, ["sbqHeal"] = 0, ["sbqDigest"] = 1, ["sbqSoftDigest"] = 2 -- reverse lookup
}

p.escapeModifier = {
	[-1] = "easyEscape", [0] = "normal", [1] = "antiEscape", [2] = "noEscape",
	["easyEscape"] = -1, ["normal"] = 0, ["antiEscape"] = 1, ["noEscape"] = 2 -- reverse lookup
}

function init()
	p.sbqSettings = player.getProperty("sbqSettings") or {}

	p.occupantList = "occupantScrollArea.occupantList"
	p.vehicle = config.getParameter( "vehicle" )
	p.occupant = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	p.powerMultiplier = config.getParameter( "powerMultiplier" )
	p.config = root.assetJson( "/sbqGeneral.config")
	p.sbqConfig = root.assetJson( "/vehicles/sbq/"..world.entityName(p.vehicle).."/"..world.entityName(p.vehicle)..".vehicle" ).sbqData

	settings = sb.jsonMerge(sb.jsonMerge(p.config.defaultSettings, p.sbqConfig.defaultSettings or {}), p.sbqSettings[world.entityName(p.vehicle)] or {})
	globalSettings = p.sbqSettings.global or {}

	enableActionButtons(false)
	readOccupantData()
	setIconDirectives()

	widget.setSelectedOption( "bellyEffect", p.bellyEffects[globalSettings.bellyEffect or "sbqRemoveBellyEffects"] )
	widget.setSelectedOption( "escapeModifier", p.escapeModifier[globalSettings.escapeModifier or "normal"] )

	widget.setChecked( "displayDamage", globalSettings.displayDamage or false )
	widget.setChecked( "bellySounds", globalSettings.bellySounds or false )

	widget.setChecked( "autoDeploy", settings.autoDeploy or false )
	p.refreshed = true

	onInit()
end

function onInit()
end

function update( dt )
	checkRefresh(dt)
	updateHPbars(dt)
end

function enableActionButtons(enable) -- replace function on the specific settings menu if extra buttons are added
	widget.setButtonEnabled( "letOut", enable )
end

function setIconDirectives()
	if (not settings.directives) or settings.directives == "" then
		settings.directives = p.sbqConfig.defaultDirectives
	end
	local species = world.entityName(p.vehicle)
	local skin = (settings.skinNames or {}).head or "default"
	local directives = settings.directives or ""
	widget.setImage("icon", "/vehicles/sbq/"..species.."/skins/"..skin.."/icon.png"..directives)
end

p.listItems = {}

function checkIfIdListed(id, species)
	for i = 1, #p.listItems do
		if p.listItems[i].id == id then
			return i, p.listItems[i].listItem
		end
	end
	return #p.listItems+1, widget.addListItem(p.occupantList)
end

function readOccupantData()
	getSelectedId()

	local enable = false
	for i, occupant in pairs(p.occupant) do
		if not ((i == "0") or (i == 0)) and (p.occupant[i] ~= nil) and (p.occupant[i].id ~= nil) and (world.entityExists( p.occupant[i].id )) then
			if not p.locked then
				enable = true
			end
			local id = p.occupant[i].id
			local species = p.occupant[i].species
			local listEntry, listItem = checkIfIdListed(id, species)

			p.listItems[listEntry] = {
				id = id,
				listItem = listItem
			}
			if id == p.selectedId then
				widget.setListSelected(p.occupantList, listItem)
			end
			if species == nil then
				setPortrait(p.occupantList.."."..listItem, world.entityPortrait( id, "bust" ))
			else
				local skin = (p.occupant[i].smolPreyData.settings.skinNames or {}).head or "default"
				local directives = p.occupant[i].smolPreyData.settings.directives or ""
				widget.setImage(p.occupantList.."."..listItem..".portraitIcon", "/vehicles/sbq/"..species.."/skins/"..skin.."/icon.png"..directives)
			end
			widget.setText(p.occupantList.."."..listItem..".name", world.entityName( id ))
		end
	end
	enableActionButtons(enable)
end

function updateHPbars(dt)
	local listItem
	for i, occupant in pairs(p.occupant) do
		if not ((i == "0") or (i == 0)) then
			for j = 1, #p.listItems do
				if p.listItems[j].id == p.occupant[i].id then
					listItem = p.listItems[j].listItem
				end
			end
			if listItem ~= nil and (p.occupant[i] ~= nil) and (p.occupant[i].id ~= nil) and world.entityExists( p.occupant[i].id ) then
				local health = world.entityHealth( p.occupant[i].id )
				widget.setProgress( p.occupantList.."."..listItem..".healthbar", health[1] / health[2] )

				secondaryBar(i, listItem, dt)
			end
		end
	end
end

local bar = {
	empty = "/interface/scripted/sbq/barempty2.png",
	full = "/interface/scripted/sbq/barfull2.png",
	x = 0, y = 0, h = 5, w = 61,
	color = {"9e9e9e", "c4c4c4", "e4e4e4", "ffffff"}, -- defaults in barfull.png
}

function replace(from, to)
	if to == nil or #to == 0 then return "" end
	local directive = "?replace;"
	for i, f in ipairs(from) do
		directive = directive .. f .. "=" .. to[i] .. ";"
	end
	return directive
end

function secondaryBar(i, listItem, dt)
	local progressBar = widget.bindCanvas( p.occupantList.."."..listItem..".secondarybar" )

	local s = (p.occupant[i].progressBar or 0) / 100 * bar.w
	if s < bar.w then
		progressBar:drawImageRect(
			bar.empty,
			{s, 0, bar.w, bar.h},
			{bar.x + s, bar.y, bar.x + bar.w, bar.y + bar.h}
		)
	end
	if s > 0 then
		progressBar:drawImageRect(
			bar.full .. replace(bar.color, p.occupant[i].progressBarColor),
			{0, 0, s, bar.h},
			{bar.x, bar.y, bar.x + s, bar.y + bar.h}
		)
	end
end

function getSelectedId()
	if not p.occupantList then return end
	local selected = widget.getListSelected(p.occupantList)
	for j = 1, #p.listItems do
		if p.listItems[j].listItem == selected then
			p.selectedId = p.listItems[j].id
			return p.selectedId
		end
	end
end

function refreshListData()
	if not p.refreshList then return end
	p.refreshList = nil

	getSelectedId()

	p.listItems = {}
	widget.clearListItems(p.occupantList)
end

p.refreshtime = 0
p.rpc = nil

function checkRefresh(dt)
	if p.refreshtime >= 0.1 and p.rpc == nil then
		p.rpc = world.sendEntityMessage( p.vehicle, "settingsMenuRefresh")
	elseif p.rpc ~= nil and p.rpc:finished() then
		if p.rpc:succeeded() then
			local result = p.rpc:result()
			if result ~= nil then
				p.occupant = result.occupants
				p.powerMultiplier = result.powerMultiplier
				setIconDirectives()
				p.refreshtime = 0
				p.refreshList = result.refreshList or p.refreshList
				p.locked = result.locked

				refreshListData()
				readOccupantData()

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

function setBellyEffect()
	local value = widget.getSelectedOption( "bellyEffect" )
	local bellyEffect = p.bellyEffects[value]

	globalSettings.bellyEffect = bellyEffect
	settings.bellyEffect = bellyEffect
	saveSettings()
end

function setEscapeModifier()
	local value = widget.getSelectedOption( "escapeModifier" )
	local escapeModifier = p.escapeModifier[value]

	globalSettings.escapeModifier = escapeModifier
	settings.escapeModifier = escapeModifier
	saveSettings()
end


function changeSetting(settingname)
	local value = widget.getChecked( settingname )
	settings[settingname] = value
	saveSettings()
end

function changeGlobalSetting(settingname)
	local value = widget.getChecked( settingname )
	globalSettings[settingname] = value
	settings[settingname] = value
	saveSettings()
end
function bellySounds()
	changeGlobalSetting( "bellySounds" )
end
function displayDamage()
	changeGlobalSetting( "displayDamage" )
end

function autoDeploy()
	changeSetting( "autoDeploy" )
end

function saveSettings()
	world.sendEntityMessage( p.vehicle, "settingsMenuSet", settings )
	p.sbqSettings[world.entityName(p.vehicle)] = settings
	p.sbqSettings.global = globalSettings
	player.setProperty( "sbqSettings", p.sbqSettings )
end

function despawn()
	world.sendEntityMessage( p.vehicle, "despawn" )
end
function clearPortrait(canvasName)
	local canvas = widget.bindCanvas( canvasName..".portrait" )
	canvas:clear()
end

function setPortrait( canvasName, data )
	local canvas = widget.bindCanvas( canvasName..".portrait" )
	canvas:clear()
	for k,v in ipairs(data or {}) do
		local pos = v.position or {0, 0}
		canvas:drawImage(v.image, { -7 + pos[1], -19 + pos[2] } )
	end
end

function letOut()
	enableActionButtons(false)
	world.sendEntityMessage( p.vehicle, "letout", getSelectedId() )
end

function turboDigest()
	local selected = getSelectedId()
	if selected ~= nil then
		return sendturboDigestMessage(selected)
	else
		for i, occupant in pairs(p.occupant) do
			if not (i == 0 or i == "0") then
				sendturboDigestMessage(p.occupant[i].id)
			end
		end
	end
end

function sendturboDigestMessage(eid)
	if eid ~= nil and world.entityExists(eid) then
		world.sendEntityMessage( eid, "sbqTurboDigest" )
	end
end

function transform()
	local selected = getSelectedId()
	if selected ~= nil then
		return sendTransformMessage(selected)
	else
		for i, occupant in pairs(p.occupant) do
			if not (i == 0 or i == "0") then
				sendTransformMessage(p.occupant[i].id)
			end
		end
	end
end

function sendTransformMessage(eid)
-- we currently don't have any pathing behavior for this, but it does work, however it looks buggy so shall be disabled for non player entities for now
	if eid ~= nil and world.entityExists(eid) then
		world.sendEntityMessage( p.vehicle, "transform", p.getSmolPreyData(), eid, p.transformSpeedMultiplier or 3)
	end
end

function p.getSmolPreyData()
end


function customize()
	world.sendEntityMessage(
		player.id(), "sbqOpenInterface", world.entityName(p.vehicle).."Customize",
		{ vehicle = p.vehicle, occupants = p.occupant, maxOccupants = p.maxOccupants, powerMultiplier = p.powerMultiplier }, false, p.vehicle
	)
end
