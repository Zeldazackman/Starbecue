
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

function init()
	sbq.addRPC( world.sendEntityMessage(  ) )

end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)

end
