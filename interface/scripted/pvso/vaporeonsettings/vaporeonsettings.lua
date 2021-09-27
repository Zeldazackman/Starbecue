
require("/interface/scripted/pvso/pvsoSettings.lua")

p.vsoname = "vaporeon"

function onInit()
	widget.setChecked( "defaultSmall", settings.defaultSmall or false )
	setStartState()
end

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end

function defaultSmall()
	setStartState()
	changeSetting( "defaultSmall" )
end

function setStartState()
	if widget.getChecked("defaultSmall") then
		settings.startState = "smol"
	else
		settings.startState = "stand"
	end
end
