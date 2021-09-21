function init()
	activeItem.setHoldingItem(false)
end

function update(dt, fireMode, shiftHeld, controls)
	if not player.isLounging() and fireMode ~= nil and not clicked then
		clicked = true
		status.setStatusProperty("pvsoPreyEnabled",{
			held = true,
			oralVore = true,
			analVore = true,
			tailVore = true,
			cockVore = true,
			breastVore = true,
			absorbVore = true
		})

	elseif fireMode ~= "primary" then
		clicked = false
	end
end
