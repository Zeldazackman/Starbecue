
function sbq.handleImmunities()
	local sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
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
