function init()
	activeItem.setArmAngle(-math.pi / 4)
	animator.rotateTransformationGroup("potion", math.pi / 4)
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
			activeItem.setArmAngle(self.useTimer / 5)
		elseif self.useTimer < 5.5 then
			activeItem.setArmAngle(math.max(3.1 / 5 - (self.useTimer - 3.1) * 3, -math.pi / 3))
		else
			local table = {
				male = "female",
				female = "male"
			}
			data = status.statusProperty("speciesAnimOverrideData") or {}
			local originalGender = world.entityGender(entity.id())
			data.gender = table[(data.gender or originalGender)]
			local mysteriousPotionData = status.statusProperty("sbqMysteriousPotionTF") or {}
			mysteriousPotionData.gender = data.gender
			status.setStatusProperty("sbqMysteriousPotionTF", mysteriousPotionData)
			if data.gender == originalGender then
				data.gender = nil
			end
			status.setStatusProperty("speciesAnimOverrideData", data)

			local category = status.getPersistentEffects("speciesAnimOverride")
			status.clearPersistentEffects("speciesAnimOverride")
			if category[1] == nil then
				category = {"speciesAnimOverride"}
			end
			status.setPersistentEffects("speciesAnimOverride", category )

			item.consume(1)
			world.spawnProjectile("sbqWarpInEffect", mcontroller.position(), entity.id(), { 0, 0 }, true)
			animator.playSound("activate")
		end
	end
end

function dartGunData()
	return { funcName = "genderSwap" }
end
