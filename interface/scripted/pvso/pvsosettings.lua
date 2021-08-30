
p.bellyEffects = {
	[-1] = "pvsoRemoveBellyEffects", [0] = "pvsoVoreHeal", [1] = "pvsoDigest", [2] = "pvsoSoftDigest",
	["pvsoRemoveBellyEffects"] = -1, ["pvsoVoreHeal"] = 0, ["pvsoDigest"] = 1, ["pvsoSoftDigest"] = 2 -- reverse lookup
}

function onInit()
	p.occupantList = "occupantScrollArea.occupantList"
	p.vso = config.getParameter( "vso" )
	p.occupants = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	enableActionButtons(false)
	readOccupantData()
	p.vsoSettings = player.getProperty("vsoSettings") or {}
	globalSettings = p.vsoSettings.global or {}
	settings = p.vsoSettings[p.vsoname] or {}

	widget.setSelectedOption( "bellyEffect", p.bellyEffects[globalSettings.bellyEffect or "pvsoRemoveBellyEffects"] )
	widget.setChecked( "displayDamage", globalSettings.displayDamage or false )
	widget.setChecked( "bellySounds", globalSettings.bellySounds or false )

	widget.setChecked( "autoDeploy", settings.autoDeploy or false )
	widget.setChecked( "defaultSmall", settings.defaultSmall or false )
	p.refreshed = true
end

function enableActionButtons(enable) -- replace function on the specific settings menu if extra buttons are added
	widget.setButtonEnabled( "letOut", enable )
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
	enableActionButtons(false)
	for i = 1, #p.occupants do
		if p.occupants[i] and p.occupants[i].id and world.entityExists( p.occupants[i].id ) then
			local id = p.occupants[i].id
			local species = p.occupants[i].species
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
				setPortrait(p.occupantList.."."..listItem, {{
					image = "/vehicles/spov/"..species.."/"..species.."icon.png",
					position = {13, 12}
				}})
			end
			widget.setText(p.occupantList.."."..listItem..".name", world.entityName( id ))
		end
		enableActionButtons(true)
	end
end

function updateHPbars()
	local listItem
	for i = 1, #p.occupants do
		for j = 1, #p.listItems do
			if p.listItems[j].id == p.occupants[i].id then
				listItem = p.listItems[j].listItem
			end
		end
		if p.occupants[i] and p.occupants[i].id and world.entityExists( p.occupants[i].id ) then
			local health = world.entityHealth( p.occupants[i].id )
			widget.setProgress( p.occupantList.."."..listItem..".healthbar", health[1] / health[2] )

			secondaryBar(i, listItem)
		else
			p.refreshList = true
		end
	end
end

function secondaryBar(occupant, listItem)
end

function getSelectedId()
	local selected = widget.getListSelected(p.occupantList)
	for j = 1, #p.listItems do
		if p.listItems[j].listItem == selected then
			p.selectedId = p.listItems[j].id
		end
	end
end

function refreshListData()
	if not p.refreshList then return end
	p.refreshList = false

	getSelectedId()

	p.listItems = {}
	widget.clearListItems(p.occupantList)
end

p.refreshtime = 0
p.rpc = nil

function checkRefresh(dt)
	if p.refreshtime >= 3 and p.rpc == nil then
		p.rpc = world.sendEntityMessage( p.vso, "settingsMenuRefresh")
	elseif p.rpc ~= nil and p.rpc:finished() then
		if p.rpc:succeeded() then
			local result = p.rpc:result()
			if result ~= nil then
				p.occupants = result
				refreshListData()
				readOccupantData()
				p.refreshtime = 0
				p.refreshed = true
				--sb.logInfo( "Refreshed Settings Menu" )
			end
		else
			sb.logError( "Couldn't refresh settings." )
			sb.logError( p.rpc:error() )
		end
		--sb.logInfo( "Reset Settings Menu RPC" )
		p.rpc = nil
	else
		--[[if p.rpc then
			sb.logInfo( "Waiting for RPC" )
		else
			sb.logInfo( "Waiting for refresh for"..p.refreshtime )
		end]]
		p.refreshtime = p.refreshtime + dt
	end
end

function setBellyEffect()
	local value = widget.getSelectedOption( "bellyEffect" )
	local bellyEffect = p.bellyEffects[value]
	globalSettings.bellyEffect = bellyEffect
	if (bellyEffect == "pvsoDigest") or (bellyEffect == "pvsoSoftDigest") then
		settings.hungerEffect = 1
	else
		settings.hungerEffect = 0
	end
	if widget.getChecked( "displayDamage" ) then
		local bellyDisplayEffectList = root.assetJson("/vehicles/spov/pvso_general.config:bellyDisplayStatusEffects")
		if bellyDisplayEffectList[bellyEffect] ~= nil then
			bellyEffect = bellyDisplayEffectList[bellyEffect]
		end
	end
	settings.bellyEffect = bellyEffect
	saveSettings()
end

function changeSetting(settingname)
	local value = widget.getChecked( settingname )
	settings[string.lower(settingname)] = value
	saveSettings()
end

function changeGlobalSetting(settingname)
	local value = widget.getChecked( settingname )
	globalSettings[string.lower(settingname)] = value
	settings[string.lower(settingname)] = value
	saveSettings()
end

function displayDamage()
	changeGlobalSetting( "displayDamage" )
end

function autoDeploy()
	changeSetting( "autoDeploy" )
end
function defaultSmall()
	changeSetting( "defaultSmall" )
end

function saveSettings()
	world.sendEntityMessage( p.vso, "settingsMenuSet", settings )
	p.vsoSettings[p.vsoname] = settings
	p.vsoSettings.global = globalSettings
	player.setProperty( "vsoSettings", p.vsoSettings )
end

function despawn()
	world.sendEntityMessage( p.vso, "despawn" )
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

function getWhich()
	getSelectedId()
	for i = 1, #p.occupants do
		if p.selectedId == p.occupants[i].id then
			return i
		end
	end
	return #p.occupants
end

function letOut()
	if p.refreshed then
		p.refreshed = false
		p.refreshtime = 0
		p.refreshList = true
		local which = getWhich()
		enableActionButtons(false)
		world.sendEntityMessage( p.vso, "letout", which )
	end
end
