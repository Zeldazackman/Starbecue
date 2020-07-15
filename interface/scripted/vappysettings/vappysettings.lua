local vappy
local firstOccupant
local secondOccupant
local settings
local bellyeffects = {
	[-1] = "", [0] = "heal", [1] = "digest", [2] = "softdigest",
	[""] = -1, ["heal"] = 0, ["digest"] = 1, ["softdigest"] = 2 -- reverse lookup
}
local clickmodes = {
	[-1] = "attack", [0] = "build",
	["attack"] = -1, ["build"] = 0

}

function init()
	vappy = config.getParameter( "vappy" )
	firstOccupant = config.getParameter( "firstOccupant" )
	local firstSpecies = config.getParameter( "firstSpecies" )
	if firstOccupant ~= nil then
		if firstSpecies == nil then
			setPortrait( "firstOccupant", world.entityPortrait( firstOccupant, "bust" ) )
		else
			setPortrait( "firstOccupant", {{image="vehicles/spov/"..firstSpecies.."/"..firstSpecies.."icon.png"}})
		end
		widget.setText( "firstOccupant.name", world.entityName( firstOccupant ) )
	else
		widget.setButtonEnabled( "firstOccupant.letOut", false )
	end
	secondOccupant = config.getParameter( "secondOccupant" )
	local secondSpecies = config.getParameter( "secondSpecies" )
	if secondOccupant ~= nil then
		if secondSpecies == nil then
			setPortrait( "secondOccupant", world.entityPortrait( secondOccupant, "bust" ) )
		else
			setPortrait( "secondOccupant", {{image="vehicles/spov/"..secondSpecies.."/"..secondSpecies.."icon.png"}})
		end
		widget.setText( "secondOccupant.name", world.entityName( secondOccupant ) )
	else
		widget.setButtonEnabled( "secondOccupant.letOut", false )
	end
	settings = player.getProperty("vappySettings") or {}
	widget.setChecked( "autoDeploy", settings.autodeploy or false )
	widget.setChecked( "defaultSmall", settings.defaultsmall or false )
	widget.setSelectedOption( "bellyEffect", bellyeffects[settings.bellyeffect or ""] )
	widget.setSelectedOption( "clickMode", clickmodes[settings.clickmode or "attack"] )
end

function update( dt )
	if firstOccupant ~= nil and world.entityExists( firstOccupant ) then
		local firstOccupantHealth = world.entityHealth( firstOccupant )
		widget.setProgress( "firstOccupant.healthbar", firstOccupantHealth[1] / firstOccupantHealth[2] )
	end
	if secondOccupant ~= nil and world.entityExists( secondOccupant ) then
		local secondOccupantHealth = world.entityHealth( secondOccupant )
		widget.setProgress( "secondOccupant.healthbar", secondOccupantHealth[1] / secondOccupantHealth[2] )
	end
end

function setBellyEffect()
	local value = widget.getSelectedOption( "bellyEffect" )
	local bellyeffect = bellyeffects[value]
	world.sendEntityMessage( vappy, "settingsMenuSet", "bellyeffect", bellyeffect )
	settings.bellyeffect = bellyeffect
	saveSettings()
end
function setClickMode()
	local value = widget.getSelectedOption( "clickMode" )
	local clickmode = clickmodes[value]
	world.sendEntityMessage( vappy, "settingsMenuSet", "clickmode", clickmode )
	settings.clickmode = clickmode
	saveSettings()
end
function autoDeploy()
	local value = widget.getChecked( "autoDeploy" )
	settings.autodeploy = value
	saveSettings()
end
function defaultSmall()
	local value = widget.getChecked( "defaultSmall" )
	settings.defaultsmall = value
	saveSettings()
end

function despawn()
	world.sendEntityMessage( vappy, "despawn" )
end

function setPortrait( canvasName, data )
	local canvas = widget.bindCanvas( canvasName..".portrait" )
	canvas:clear()
	for k,v in ipairs(data) do
		canvas:drawImage(v.image, { -7, -19 } )
	end
end
function letOut(_, which )
	world.sendEntityMessage( vappy, "settingsMenuSet", "letout", which )
end

function saveSettings()
	player.setProperty( "vappySettings", settings )
end