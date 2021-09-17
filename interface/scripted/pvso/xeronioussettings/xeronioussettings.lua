

require("/interface/scripted/pvso/pvsoSettings.lua")

p.vsoname = "xeronious"

function onInit()
	widget.setChecked( "autoEggLay", settings.autoegglay or false )
end

function p.getSmolPreyData()
	local escapeModifier = settings.escapeModifier
	if escapeModifier == "noEscape" then
		escapeModifier = "antiEscape"
	end
	return {
		barColor = {"aa720a", "e4a126", "ffb62e", "ffca69"},
		forceSettings = true,
		layer = true,

		species = "egg",
		recieved = true,
		update = true,
		path = "/vehicles/spov/egg/",
		settings = {
			cracks = 0,
			bellyEffect = "pvsoVoreHeal",
			escapeModifier = escapeModifier,
			skinNames = {
				head = "xeronious",
				body = "xeronious"
			}
		},
		state = root.assetJson( "/vehicles/spov/egg/egg.vehicle" ).states.smol,
		animatedParts = root.assetJson( "/vehicles/spov/egg/egg.animation" ).animatedParts
	}
end

p.transformSpeedMultiplier = 10

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end

function autoEggLay()
	changeSetting( "autoEggLay" )
end
