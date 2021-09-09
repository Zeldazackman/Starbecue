
require("/interface/scripted/pvso/pvsoSettings.lua")

p.vsoname = "vaporeon"

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end
