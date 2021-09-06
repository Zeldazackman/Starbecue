
p.bellyEffects = {
	[-1] = "pvsoRemoveBellyEffects", [0] = "pvsoVoreHeal", [1] = "pvsoDigest", [2] = "pvsoSoftDigest",
	["pvsoRemoveBellyEffects"] = -1, ["pvsoVoreHeal"] = 0, ["pvsoDigest"] = 1, ["pvsoSoftDigest"] = 2 -- reverse lookup
}

function onInit()
	p.vsoSettings = player.getProperty("vsoSettings") or {}
	globalSettings = p.vsoSettings.global or {}
	settings = p.vsoSettings[p.vsoname] or {}

	p.occupantList = "occupantScrollArea.occupantList"
	p.vso = config.getParameter( "vso" )
	p.occupant = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	p.powerMultiplier = config.getParameter( "powerMultiplier" )

	enableActionButtons(false)
	readOccupantData()

	widget.setSelectedOption( "bellyEffect", p.bellyEffects[globalSettings.selectedBellyEffect or "pvsoRemoveBellyEffects"] )
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
	for i = 1, #p.occupant do
		if p.occupant[i] and p.occupant[i].id and world.entityExists( p.occupant[i].id ) then
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

function updateHPbars(dt)
	local listItem
	for i = 1, #p.occupant do
		for j = 1, #p.listItems do
			if p.listItems[j].id == p.occupant[i].id then
				listItem = p.listItems[j].listItem
			end
		end
		if p.occupant[i] and p.occupant[i].id and world.entityExists( p.occupant[i].id ) then
			local health = world.entityHealth( p.occupant[i].id )
			widget.setProgress( p.occupantList.."."..listItem..".healthbar", health[1] / health[2] )

			secondaryBar(i, listItem, dt)
		else
			p.refreshList = true
		end
	end
end

function secondaryBar(i, listItem, dt)
	if not p.occupant[i].progressBarActive then return end
	p.occupant[i].progressBar = p.occupant[i].progressBar + ((math.log(p.powerMultiplier)+1) * dt)
	widget.setProgress( p.occupantList.."."..listItem..".secondarybar", p.occupant[i].progressBar / 100 )
end

function getSelectedId()
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
	p.refreshList = false

	getSelectedId()

	p.listItems = {}
	widget.clearListItems(p.occupantList)
end

p.refreshtime = 0
p.rpc = nil

function checkRefresh(dt)
	if p.refreshtime >= 1 and p.rpc == nil then
		p.rpc = world.sendEntityMessage( p.vso, "settingsMenuRefresh")
	elseif p.rpc ~= nil and p.rpc:finished() then
		if p.rpc:succeeded() then
			local result = p.rpc:result()
			if result ~= nil then
				p.occupant = result.occupants
				p.powerMultiplier = result.powerMultiplier
				refreshListData()
				readOccupantData()
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

function setBellyEffect()
	local value = widget.getSelectedOption( "bellyEffect" )
	local bellyEffect = p.bellyEffects[value]
	globalSettings.selectedBellyEffect = bellyEffect
	if (bellyEffect == "pvsoDigest") or (bellyEffect == "pvsoSoftDigest") then
		settings.hungerEffect = 1
	else
		settings.hungerEffect = 0
	end
	if globalSettings.displayDamage then
		local bellyDisplayEffectList = root.assetJson("/vehicles/spov/pvso_general.config:bellyDisplayStatusEffects")
		if bellyDisplayEffectList[bellyEffect] ~= nil then
			bellyEffect = bellyDisplayEffectList[bellyEffect]
		end
	end
	globalSettings.bellyEffect = bellyEffect
	settings.bellyEffect = bellyEffect
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

function letOut()
	if p.refreshed then
		p.refreshed = false
		p.refreshtime = 0
		p.refreshList = true
		enableActionButtons(false)
		world.sendEntityMessage( p.vso, "letout", getSelectedId() )
	end
end

function transform()
end

function turboDigest()
	local selected = getSelectedId()
	if selected ~= nil then
		return sendturboDigestMessage(selected)
	else
		for i = 1, #p.occupant do
			sendturboDigestMessage(p.occupant[i].id)
		end
	end
end

function sendturboDigestMessage(eid)
	if eid ~= nil and world.entityExists(eid) then
		world.sendEntityMessage( eid, "pvsoTurboDigest" )
	end
end
