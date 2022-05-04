function init()
	activeItem.setArmAngle(-math.pi / 4)
	animator.rotateTransformationGroup("potion", math.pi / 4)
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
			activeItem.setArmAngle(self.useTimer / 5)
		elseif self.useTimer < 5.5 then
			activeItem.setArmAngle(math.max(3.1 / 5 - (self.useTimer - 3.1) * 3, -math.pi / 3))
		else
			local table = {
				male = "female",
				female = "male"
			}
			self = status.statusProperty("speciesAnimOverrideData") or {}
			local originalGender = world.entityGender(entity.id())
			self.gender = table[(self.gender or originalGender)]
			local mysteriousPotionData = status.statusProperty("sbqMysteriousPotionTF") or {}
			mysteriousPotionData.gender = self.gender
			status.setStatusProperty("sbqMysteriousPotionTF", mysteriousPotionData)

			status.setStatusProperty("speciesAnimOverrideData", self)

			local category = status.getPersistentEffects("speciesAnimOverride")
			status.clearPersistentEffects("speciesAnimOverride")
			status.setPersistentEffects("speciesAnimOverride", category)

			status.removeEphemeralEffect("speciesAnimOverride")
			status.addEphemeralEffect("speciesAnimOverride", 3600)

			item.consume(1)
		end
	end
end
