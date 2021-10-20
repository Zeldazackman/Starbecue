local oldinit = init
sbq = {}
require("/scripts/SBQ_everything_primary.lua")
function init()
	oldinit()
	sbq.everything_primary()
end
