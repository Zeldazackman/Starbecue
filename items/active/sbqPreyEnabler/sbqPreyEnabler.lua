function init()
	activeItem.setHoldingItem(false)
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() and fireMode == "primary" and not clicked then
		clicked = true
		world.sendEntityMessage(entity.id(), "sbqOpenInterface", "sbqPreyEnabler")
	elseif not player.isLounging() and fireMode == "alt" and not clicked then
		clicked = true
		world.sendEntityMessage(entity.id(), "sbqOpenInterface", "sbqClose")
	elseif fireMode == "none" then
		clicked = false
	end
end
