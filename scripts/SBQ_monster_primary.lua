local oldinit = init
sbq = {}
require("/scripts/SBQ_everything_primary.lua")
function init()
	oldinit()
	sbq.everything_primary()

	message.setHandler("sbqGetSeatEquips", function(_,_, current)
		status.setStatusProperty( "sbqCurrentData", current)
	end)
end
