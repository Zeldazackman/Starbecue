p = {}

p.vsoname = "vappy"

require("/interface/scripted/pvso/pvsosettings.lua")

function init()
	onInit()
end

function update( dt )
	checkRefresh(dt)
	updateHPbars(dt)
end

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end
