

require("/interface/scripted/sbq/sbqSettings.lua")

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
		state = "smol",
		species = "egg",
		layerLocation = "egg",
		settings = {
			cracks = 0,
			bellyEffect = "sbqHeal",
			escapeModifier = escapeModifier,
			skinNames = {
				head = "xeronious",
				body = "xeronious"
			}
		}
	}
end

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end

function autoEggLay()
	changeSetting( "autoEggLay" )
end
