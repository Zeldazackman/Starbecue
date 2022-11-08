function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.resetTransformationGroup("potion")
	animator.rotateTransformationGroup("potion", math.pi/4)
end

require("/items/active/sbqTransformation/sbqDuplicatePotion/sbqGetIdentity.lua")

function update(dt, fireMode, shiftHeld)
	if fireMode == "primary" and not activeItem.callOtherHandScript("isDartGun") then
		local parameters = getIdentity(entity.id())
		parameters.potionPath = "/items/active/sbqTransformation/sbqDuplicatePotion/"
		parameters.rarity = "legendary"
		player.giveItem({name = "sbqMysteriousPotion", parameters = parameters})
		item.consume(1)
	end
end

function dartGunData()
	return { funcName = "transform", data = getIdentity(entity.id())}
end
