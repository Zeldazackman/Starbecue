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
