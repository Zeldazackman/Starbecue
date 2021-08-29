local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoApplyStatusEffects", function(_,_, effects, source)
		status.addEphemeralEffects(effects, source)
	end)

	message.setHandler("pvsoRemoveStatusEffect", function(_,_, effect)
		status.removeEphemeralEffect(effect)
	end)

	message.setHandler("pvsoRemoveStatusEffects", function(_,_, effects)
		for i = 1, #effects do
			status.removeEphemeralEffect(effect[i])
		end
	end)

	message.setHandler("getVSOseatInformation", function()
		local seatdata = {
			species = npc.species(),
			mass = mcontroller.mass(),
			primaryHandItem = npc.getItemSlot("primary"),
			altHandItem = npc.getItemSlot("alt"),
			head = npc.getItemSlot("head"),
			chest = npc.getItemSlot("chest"),
			legs = npc.getItemSlot("legs"),
			back = npc.getItemSlot("back"),
			headCosmetic = npc.getItemSlot("headCosmetic"),
			chestCosmetic = npc.getItemSlot("chestCosmetic"),
			legsCosmetic = npc.getItemSlot("legsCosmetic"),
			backCosmetic = npc.getItemSlot("backCosmetic"),
			powerMultiplier = status.stat("powerMultiplier")
		}
		return seatdata
	end)


end
