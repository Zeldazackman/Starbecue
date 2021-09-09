function init()
end

function update(dt)
	if player.isLounging() then
		storage.timeUntilUnlock = 0.5
	end
	if player.getProperty( "vsoSeatType") ~= storage.lockType then
		if storage.lockType == "driver" then
			storage.lockType = player.getProperty( "vsoSeatType")
		else
			storage.timeUntilUnlock = 0
		end
	end
	if storage.timeUntilUnlock <= 0 then
		for i, itemDescriptor in pairs(storage.itemDescriptors) do
			player.giveItem(itemDescriptor)
		end
		for slotname, itemDescriptor in pairs(storage.lockedEssentialItems) do
			player.giveEssentialItem(slotname, itemDescriptor)
		end
	else
		storage.timeUntilUnlock = storage.timeUntilUnlock - dt
	end
end
