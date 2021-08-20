p = {}

p.vsoname = "xeronious"

require("/interface/scripted/pvso/pvsosettings.lua")

function init()
	onInit()
	widget.setChecked( "autoCrouch", settings.autocrouch or false )
	widget.setChecked( "autoEggLay", settings.autoegglay or false )
end

function update( dt )
	updateHPbars()
	checkRefresh(dt)
end

function autoCrouch()
	changeSetting( "autoCrouch" )
end

function autoEggLay()
	changeSetting( "autoEggLay" )
end
