function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
end

function update(dt, fireMode, shiftHeld)

	if not self.useTimer and fireMode == "primary" and player then
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
			status.setStatusProperty("sbqMysteriousPotionData", nil)
			status.clearPersistentEffects("speciesAnimOverride")
			status.setStatusProperty("speciesAnimOverrideData", status.statusProperty("oldSpeciesAnimOverrideData"))
			status.setPersistentEffects("speciesAnimOverride", status.statusProperty("oldSpeciesAnimOverrideCategory"))
			item.consume(1)
		end
	end
end
