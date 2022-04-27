local oldinit = init
sbq = {}

function init()
	oldinit()

	message.setHandler("sbqGetSeatEquips", function(_,_, current)
		status.setStatusProperty( "sbqCurrentData", current)
		return {
			head = npc.getItemSlot("head") or false,
			chest = npc.getItemSlot("chest") or false,
			legs = npc.getItemSlot("legs") or false,
			back = npc.getItemSlot("back") or false,
			headCosmetic = npc.getItemSlot("headCosmetic") or false,
			chestCosmetic = npc.getItemSlot("chestCosmetic") or false,
			legsCosmetic = npc.getItemSlot("legsCosmetic") or false,
			backCosmetic = npc.getItemSlot("backCosmetic") or false,
			statusDirectives = status.statusProperty("speciesAnimOverrideDirectives"),
			effectDirectives = status.statusProperty("effectDirectives")
		}
	end)

	message.setHandler("sbqInteract", function(_,_, pred, location)
		return interact({sourceId = pred, sourcePosition = world.entityPosition(pred), preyLocation = location})
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

	local sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	if sbqPreyEnabled.digestImmunity then
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	end
end
