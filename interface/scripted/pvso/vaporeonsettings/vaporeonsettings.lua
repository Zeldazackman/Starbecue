p = {}

p.vsoname = "vaporeon"

require("/interface/scripted/pvso/pvsosettings.lua")

p.replaceColorMax = {2,2,1,1,1,1}

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
