function init()
	self.useTimer = nil
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
end

function update(dt, fireMode, shiftHeld)

	if not self.useTimer and fireMode == "primary" and not activeItem.callOtherHandScript("isDartGun") then
	self.useTimer = 0
	activeItem.setArmAngle(0)
	animator.playSound("drink", 4)
	end

	if self.useTimer then
		self.useTimer = self.useTimer + dt

		if self.useTimer < 3.1 then
			activeItem.setArmAngle(self.useTimer/5)
		elseif self.useTimer < 5.5 then
			activeItem.setArmAngle(math.max(3.1/5 - (self.useTimer-3.1)*3, -math.pi/3))
		else
			status.removeEphemeralEffect("sbqMysteriousPotionTF")
			status.setStatusProperty("sbqMysteriousPotionTF", nil)
			status.clearPersistentEffects("speciesAnimOverride")
			local old = status.statusProperty("oldSpeciesAnimOverrideData")
			old.gender = nil
			status.setStatusProperty("speciesAnimOverrideData", old)
			status.setPersistentEffects("speciesAnimOverride", status.statusProperty("oldSpeciesAnimOverrideCategory"))
			status.setStatusProperty("sbqMysteriousPotionTFDuration", 0 )
			item.consume(1)
			world.spawnProjectile("sbqWarpInEffect", mcontroller.position(), entity.id(), { 0, 0 }, true)
			refreshOccupantHolder()
			init()
		end
	end
end

function refreshOccupantHolder()
	local currentData = status.statusProperty("sbqCurrentData") or {}
	if currentData.species == "sbqOccupantHolder" and world.entityExists(currentData.id) then
		world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { driver = entity.id(), settings = currentData.settings, retrievePrey = currentData.id, direction = mcontroller.facingDirection() } )
	end
end

function dartGunData()
	return { funcName = "reversion" }
end
