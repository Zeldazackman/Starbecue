
function sbq.handleImmunities(type)
	local defaults = root.assetJson("/sbqGeneral.config:defaultPreyEnabled")[type] or {}
	local sbqPreyEnabled = sb.jsonMerge( defaults, status.statusProperty("sbqPreyEnabled") or {})
	if sbqPreyEnabled.digestImmunity then
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	else
		status.clearPersistentEffects("digestImmunity")
	end
	if sbqPreyEnabled.cumDigestImmunity then
		status.setPersistentEffects("cumDigestImmunity", {"sbqCumDigestImmunity"})
	else
		status.clearPersistentEffects("cumDigestImmunity")
	end
end
