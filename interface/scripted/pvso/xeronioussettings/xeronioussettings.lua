

require("/interface/scripted/pvso/pvsoSettings.lua")

p.vsoname = "xeronious"

function onInit()
	--widget.setChecked( "autoCrouch", settings.autocrouch or false )
	--widget.setChecked( "autoEggLay", settings.autoegglay or false )
end

function autoCrouch()
	changeSetting( "autoCrouch" )
end

function autoEggLay()
	changeSetting( "autoEggLay" )
end
