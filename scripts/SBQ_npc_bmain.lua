local oldinit = init
sbq = {}

function init()
	oldinit()

	message.setHandler("sbqGetSeatEquips", function(_,_, type)
		return {
			head = npc.getItemSlot("head"),
			chest = npc.getItemSlot("chest"),
			legs = npc.getItemSlot("legs"),
			back = npc.getItemSlot("back"),
			headCosmetic = npc.getItemSlot("headCosmetic"),
			chestCosmetic = npc.getItemSlot("chestCosmetic"),
			legsCosmetic = npc.getItemSlot("legsCosmetic"),
			backCosmetic = npc.getItemSlot("backCosmetic"),
		}
	end)


	message.setHandler("sbqMakeNonHostile", function(_,_)
		if (status.statusProperty("sbqOriginalDamageTeam") == nil)
		or (entity.damageTeam().type ~= "ghostly")
		then
			status.setStatusProperty("sbqOriginalDamageTeam", entity.damageTeam())
		end
		npc.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("sbqRestoreDamageTeam", function(_,_)
		npc.setDamageTeam(status.statusProperty("sbqOriginalDamageTeam"))
	end)

	if config.getParameter("sbqPreyEnabled") ~= nil then
		status.setStatusProperty("sbqPreyEnabled", config.getParameter("sbqPreyEnabled"))
	end
	local sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	if sbqPreyEnabled.digestImmunity then
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	end
end
