sbq = {}
require("/scripts/SBQ_RPC_handling.lua")
function init()
	local config = root.assetJson("/sbqGeneral.config")
	local immune = (status.statusProperty("sbqPreyEnabled") or {}).transformImmunity or config.defaultPreyEnabled[world.entityType(entity.id())].transformImmunity
	sb.logInfo("Got shot by"..tostring(effect.sourceEntity()))
	sb.logInfo("is Immune? "..tostring(immune))

	if immune then return effect.expire() end


end

function update(dt)
	sbq.checkRPCsFinished(dt)
end

function uninit()
end
