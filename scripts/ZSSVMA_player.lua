local oldinit = init
function init()
	oldinit()

	message.setHandler("getVSOseatInformation", function()
		local seatdata = {
			species = player.species(),
			mass = mcontroller.mass(),
			primaryHandItem = player.primaryHandItem(),
			altHandItem = player.altHandItem(),
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
