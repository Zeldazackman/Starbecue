local oldinit = init
function init()
	oldinit()

	message.setHandler("getVSOseatEquips", function(_,_, type)
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


	message.setHandler("pvsoMakeNonHostile", function(_,_)
		if (status.statusProperty("pvsoOriginalDamageTeam") == nil)
		or (entity.damageTeam().type ~= "ghostly")
		then
			status.setStatusProperty("pvsoOriginalDamageTeam", entity.damageTeam())
		end
		npc.setDamageTeam({ type = "ghostly", team = 1 })
	end)

	message.setHandler("pvsoRestoreDamageTeam", function(_,_)
		npc.setDamageTeam(status.statusProperty("pvsoOriginalDamageTeam"))
	end)

end
