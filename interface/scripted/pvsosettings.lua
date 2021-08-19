
p.bellyeffects = {
	[-1] = "", [0] = "heal", [1] = "digest", [2] = "softdigest",
	[""] = -1, ["heal"] = 0, ["digest"] = 1, ["softdigest"] = 2 -- reverse lookup
}

function onInit()
	p.occupantList = "occupantScrollArea.occupantList"
	p.vso = config.getParameter( "vso" )
	p.occupants = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	readOccupantData()
	p.vsoSettings = player.getProperty("vsoSettings") or {}
	settings = p.vsoSettings[p.vsoname] or {}
	widget.setChecked( "autoDeploy", settings.autodeploy or false )
	widget.setChecked( "displayDamage", settings.displaydamage or false )
	widget.setChecked( "defaultSmall", settings.defaultsmall or false )
	widget.setSelectedOption( "bellyEffect", p.bellyeffects[settings.bellyeffect or ""] )
	p.refreshed = true
end

function readOccupantData()
	widget.clearListItems(p.occupantList)

	for i = 1, p.occupants do
		--[[
		if p.occupants[i] and p.occupants[i].id and world.entityExists( p.occupants[i].id ) then
			local id = p.occupants[i].id
			local species = p.occupants[i].species
			if species == nil then
				setPortrait( "occupant"..i, world.entityPortrait( id, "bust" ) )
			else
				setPortrait( "occupant"..i, {{
					image = "/vehicles/spov/"..species.."/"..species.."icon.png",
					position = {13, 19}
				}})
			end
			widget.setText( "occupant"..i..".name", world.entityName( id ) )
			widget.setButtonEnabled( "occupant"..i..".letOut", true )
		else
			clearPortrait( "occupant"..i )
			widget.setText( "occupant"..i..".name", "" )
			widget.setButtonEnabled( "occupant"..i..".letOut", false )
		end
		]]
	end
end

function updateHPbars()
	for i = 1, p.occupants do
		if p.occupants[i] and p.occupants[i].id and world.entityExists( p.occupants[i].id ) then
			local health = world.entityHealth( p.occupants[i].id )
			--widget.setProgress( "occupant"..i..".healthbar", health[1] / health[2] )
		else
			--widget.setProgress( "occupant"..i..".healthbar", 0)
		end
	end
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
	local bellyeffect = p.bellyeffects[value]
	settings.bellyeffect = bellyeffect
	saveSettings()
end

function changeSetting(settingname)
	local value = widget.getChecked( settingname )
	settings[string.lower(settingname)] = value
	saveSettings()
end

function displayDamage()
	changeSetting( "displayDamage" )
end

function autoDeploy()
	changeSetting( "autoDeploy" )
end
function defaultSmall()
	changeSetting( "defaultSmall" )
end

function saveSettings()
	world.sendEntityMessage( p.vso, "settingsMenuSet", "saveSettings", settings )
	p.vsoSettings[p.vsoname] = settings
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
function letOut(_, which )
	if p.refreshed then
		p.refreshed = false
		p.refreshtime = 0
		for i = 1, p.maxOccupants do
			widget.setButtonEnabled( "occupant"..i..".letOut", false )
		end
		world.sendEntityMessage( p.vso, "settingsMenuSet", "letout", which )
	end
end
