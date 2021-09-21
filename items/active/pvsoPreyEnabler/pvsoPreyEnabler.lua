function init()
	activeItem.setHoldingItem(false)
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() and fireMode ~= nil and not clicked then
		clicked = true


	elseif fireMode ~= "primary" then
		clicked = false
	end
end
