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
			mass = mcontroller.mass(),
			head = player.equippedItem("head"),
			chest = player.equippedItem("chest"),
			legs = player.equippedItem("legs"),
			back = player.equippedItem("back"),
			headCosmetic = player.equippedItem("headCosmetic"),
			chestCosmetic = player.equippedItem("chestCosmetic"),
			legsCosmetic = player.equippedItem("legsCosmetic"),
			backCosmetic = player.equippedItem("backCosmetic"),
			powerMultiplier = status.stat("powerMultiplier")
		}
		return seatdata
	end)

end
