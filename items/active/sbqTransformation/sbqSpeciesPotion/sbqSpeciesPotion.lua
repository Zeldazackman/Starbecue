function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
end

function update(dt, fireMode, shiftHeld)
	if fireMode == "primary" then
		self = status.statusProperty("speciesAnimOverrideData")
		self.species = self.species or world.entitySpecies(entity.id())

		player.giveItem({name = "sbqMysteriousPotion", parameters = self})
		item.consume(1)
	end
end
