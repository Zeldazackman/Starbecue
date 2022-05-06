local oldinit = init
sbq = {}
require("/scripts/SBQ_everything_primary.lua")
function init()
	oldinit()
	sbq.everything_primary()

	message.setHandler("sbqGetSeatEquips", function(_,_, current)
		status.setStatusProperty( "sbqCurrentData", current)
		if current.type ~= "driver" then
			status.setStatusProperty("sbqDontTouchDoors", true)
		end
	end)
end
