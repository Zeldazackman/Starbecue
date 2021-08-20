p = {}

p.vsoname = "vappy"

require("/interface/scripted/pvso/pvsosettings.lua")

function init()
	onInit()
end

function update( dt )
	checkRefresh(dt)
	updateHPbars()
end

function secondaryBar(occupant, listItem)

end

function enableActionButtons(enable)
	widget.setButtonEnabled( "letOut", enable )
	widget.setButtonEnabled( "transform", enable )
end


function transform()
	local which = getWhich()
	enableActionButtons(false)
	world.sendEntityMessage( p.vso, "settingsMenuSet", "letout", which )
end
