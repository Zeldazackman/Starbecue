function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
end

function update(dt, fireMode, shiftHeld)
	if fireMode == "primary" and not activeItem.callOtherHandScript("isDartGun") then

		local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData")
		self.species = speciesAnimOverrideData.species or world.entitySpecies(entity.id())

		player.giveItem({name = "sbqMysteriousPotion", parameters = self})
		item.consume(1)
	end
end

function dartGunData()
	local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData")
	self.species = speciesAnimOverrideData.species or world.entitySpecies(entity.id())

	return { funcName = "transform", data = self}
end
