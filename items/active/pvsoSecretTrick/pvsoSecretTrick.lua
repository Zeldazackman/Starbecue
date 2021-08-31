function init()
end

function update(dt)
	if player.isLounging() then
		storage.timeUntilUnlock = 0.5
	elseif storage.timeUntilUnlock <= 0 then
		for i, itemDescriptor in pairs(storage.itemDescriptors) do
			player.giveItem(itemDescriptor)
		end
		for slotname, itemDescriptor in pairs(storage.lockedEssentialItems) do
			player.giveEssentialItem(slotname, itemDescriptor)
		end
		item.setCount(0)
		player.cleanupItems()
	else
		storage.timeUntilUnlock = storage.timeUntilUnlock - dt
	end
end
