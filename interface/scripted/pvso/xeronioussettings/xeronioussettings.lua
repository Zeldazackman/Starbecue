

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
		state = "smol",
		species = "egg",
		settings = {
			cracks = 0,
			bellyEffect = "pvsoVoreHeal",
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
