
local oldinit = init
function init()
	if oldinit ~= nil then oldinit() end
	storage.seatdata = {}
end

local oldupdate = update
function update(dt, fireMode, shiftHeld, controls)
	if oldupdate ~= nil then oldupdate(dt, fireMode, shiftHeld, controls) end
	storage.seatdata.mass = mcontroller.mass()
	storage.seatdata.powerMultiplier = status.stat("powerMultiplier")
	storage.seatdata.head = player.equippedItem("head")
	storage.seatdata.chest = player.equippedItem("chest")
	storage.seatdata.legs = player.equippedItem("legs")
	storage.seatdata.back = player.equippedItem("back")
	storage.seatdata.headCosmetic = player.equippedItem("headCosmetic")
	storage.seatdata.chestCosmetic = player.equippedItem("chestCosmetic")
	storage.seatdata.legsCosmetic = player.equippedItem("legsCosmetic")
	storage.seatdata.backCosmetic = player.equippedItem("backCosmetic")

	if shiftHeld then
		storage.seatdata.shift = (storage.seatdata.shift or 0) + dt
		storage.seatdata.shiftReleased = 0
	else
		storage.seatdata.shiftReleased = storage.seatdata.shift
		storage.seatdata.shift = 0
	end

end
