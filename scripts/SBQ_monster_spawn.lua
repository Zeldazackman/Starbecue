local oldinit = init
sbq = {}

function init()
	oldinit()

	message.setHandler("sbqMakeNonHostile", function(_,_)
		local damageTeam = entity.damageTeam()
		if (status.statusProperty("sbqOriginalDamageTeam") == nil)
		or (damageTeam.type ~= "ghostly")
		then
			status.setStatusProperty("sbqOriginalDamageTeam", damageTeam)
		end
		monster.setDamageTeam({ type = "ghostly", team = damageTeam.team })
	end)

	message.setHandler("sbqRestoreDamageTeam", function(_,_)
		local sbqOriginalDamageTeam = status.statusProperty("sbqOriginalDamageTeam")
		if sbqOriginalDamageTeam then
			monster.setDamageTeam(sbqOriginalDamageTeam)
		end
	end)

	local sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	if sbqPreyEnabled.digestImmunity then
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	end
end
