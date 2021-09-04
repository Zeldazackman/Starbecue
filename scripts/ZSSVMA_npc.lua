local oldinit = init
function init()
	oldinit()

	message.setHandler("pvsoApplyStatusEffects", function(_,_, statlist)
		for stat, data in pairs(statlist) do
			status.addEphemeralEffect(stat, data.power, data.source)
		end
	end)

	message.setHandler("pvsoForceSit", function(_,_, data)
		status.setStatusProperty("pvsoForceSitData", data)

		status.addEphemeralEffect("pvsoForceSit", 1, data.source)
	end)

	message.setHandler("getVSOseatInformation", function()
		local seatdata = {
			mass = mcontroller.mass(),
			--[[ I don't think we actually need to know what NPCs have equipped tbh
			head = npc.getItemSlot("head"),
			chest = npc.getItemSlot("chest"),
			legs = npc.getItemSlot("legs"),
			back = npc.getItemSlot("back"),
			headCosmetic = npc.getItemSlot("headCosmetic"),
			chestCosmetic = npc.getItemSlot("chestCosmetic"),
			legsCosmetic = npc.getItemSlot("legsCosmetic"),
			backCosmetic = npc.getItemSlot("backCosmetic"),
			]]
			powerMultiplier = status.stat("powerMultiplier")
		}
		return seatdata
	end)


end
