

function update(dt, fireMode, shiftHeld, controls)
	if fireMode == "primary" and not clicked then
		clicked = true
		if item.consume(1) then
			world.spawnVehicle( "sbqEgg", mcontroller.position(), { driver = player.id(), direction = mcontroller.facingDirection(), settings = storage.settings or { skinNames = { head = "plastic" } } } )
		end
	elseif fireMode == "none" then
		clicked = false
	end
end
