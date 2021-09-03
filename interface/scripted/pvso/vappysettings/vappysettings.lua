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

function transform()
	local selected = getSelectedId()
	if selected ~= nil then
		return sendTransformMessage(eid)
	else
		for i = 1, #p.occupant do
			sendTransformMessage(p.occupant[i].id)
		end
	end
end

function sendTransformMessage(eid)
	if eid ~= nil and world.entityExists(eid) then
		world.sendEntityMessage( p.vso, "transform", "spovvaporeon", eid )
	end
end
