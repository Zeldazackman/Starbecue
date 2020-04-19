local vappy
local firstOccupant
local secondOccupant
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
	if firstOccupant ~= nil then
		setPortrait( "firstOccupant", world.entityPortrait( firstOccupant, "bust" ) )
		widget.setText( "firstOccupant.name", world.entityName( firstOccupant ) )
	else
		widget.setButtonEnabled( "firstOccupant.letOut", false )
	end
	secondOccupant = config.getParameter( "secondOccupant" )
	if secondOccupant ~= nil then
		setPortrait( "secondOccupant", world.entityPortrait( secondOccupant, "bust" ) )
		widget.setText( "secondOccupant.name", world.entityName( secondOccupant ) )
	else
		widget.setButtonEnabled( "secondOccupant.letOut", false )
	end
	widget.setChecked( "autoDeploy", player.getProperty( "vappyAutoDeploy" ) or false )
	widget.setChecked( "defaultSmall", player.getProperty( "vappyDefaultSmall" ) or false )
	widget.setSelectedOption( "bellyEffect", bellyeffects[player.getProperty("vappyBellyEffect") or ""] )
	widget.setSelectedOption( "clickMode", clickmodes[player.getProperty("vappyClickMode") or "attack"] )
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
	player.setProperty( "vappyBellyEffect", bellyeffect )
end
function setClickMode()
	local value = widget.getSelectedOption( "clickMode" )
	local clickmode = clickmodes[value]
	world.sendEntityMessage( vappy, "settingsMenuSet", "clickmode", clickmode )
	player.setProperty( "vappyClickMode", clickmode )
end
function autoDeploy()
	local value = widget.getChecked( "autoDeploy" )
	player.setProperty( "vappyAutoDeploy", value )
end
function defaultSmall()
	local value = widget.getChecked( "defaultSmall" )
	player.setProperty( "vappyDefaultSmall", value )
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