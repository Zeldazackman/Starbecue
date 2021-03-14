
p.bellyeffects = {
	[-1] = "", [0] = "heal", [1] = "digest", [2] = "softdigest",
	[""] = -1, ["heal"] = 0, ["digest"] = 1, ["softdigest"] = 2 -- reverse lookup
}

function onInit()
	p.vso = config.getParameter( "vso" )
	p.occupants = config.getParameter( "occupants" )
	p.maxOccupants = config.getParameter( "maxOccupants" )
	readOccupantData()
	p.vsosettings = player.getProperty("vsoSettings") or {}
	settings = p.vsosettings[p.vsoname] or {}
	widget.setChecked( "autoDeploy", settings.autodeploy or false )
	widget.setChecked( "displayDamage", settings.displaydamage or false )
	widget.setChecked( "defaultSmall", settings.defaultsmall or false )
	widget.setSelectedOption( "bellyEffect", p.bellyeffects[settings.bellyeffect or ""] )
	p.refreshed = true
end

function readOccupantData()
	for i = 1, p.maxOccupants do
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
		else
			widget.setButtonEnabled( "occupant"..i..".letOut", false )
		end
	end
end

p.refreshframes = 0
p.rpc = nil

function checkRefresh(dt)
	if p.refreshframes >= 180 and p.rpc == nil then
		p.rpc = world.sendEntityMessage( p.vso, "settingsMenuRefresh")
	elseif p.rpc ~= nil and p.rpc:finished() then
		if p.rpc:succeeded() then
			local result = p.rpc:result()
			if result ~= nil then
				p.occupants = result
				readOccupantData()
				p.refreshframes = 0
				p.refreshed = true
			end
		else
			sb.logError( "Couldn't refresh settings." )
			sb.logError( p.rpc:error() )
		end
		p.rpc = nil
	else
		p.refreshframes = p.refreshframes + dt
	end
end

function updateHPbars()
	for i = 1, p.maxOccupants do
		if p.occupants[i] and p.occupants[i].id and world.entityExists( p.occupants[i].id ) then
			local health = world.entityHealth( p.occupants[i].id )
			widget.setProgress( "occupant"..i..".healthbar", health[1] / health[2] )
		else
			widget.setProgress( "occupant"..i..".healthbar", 0)
		end
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
	p.vsosettings[p.vsoname] = settings
	player.setProperty( "vsoSettings", p.vsosettings )
end

function despawn()
	world.sendEntityMessage( p.vso, "despawn" )
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
		world.sendEntityMessage( p.vso, "settingsMenuSet", "letout", which )
	end
end
