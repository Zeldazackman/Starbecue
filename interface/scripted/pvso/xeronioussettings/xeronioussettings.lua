

require("/interface/scripted/pvso/pvsoSettings.lua")

p.vsoname = "xeronious"

function onInit()
	widget.setChecked( "autoEggLay", settings.autoegglay or false )
end

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end

function autoEggLay()
	changeSetting( "autoEggLay" )
end
