local data = {}
function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
	data.species = config.getParameter("species")
	data.identity = config.getParameter("identity")
	data.directives = config.getParameter("directives")
	data.hairDirectives = config.getParameter("hairDirectives")
	data.gender = config.getParameter("gender") or "noChange"
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
			local duration = 3600
			if config.getParameter("unlockSpecies") then
				data.unlockSpecies = true
				---@diagnostic disable-next-line: cast-local-type
				duration = nil
				local customizedSpecies = status.statusProperty("sbqCustomizedSpecies") or {}
				if not customizedSpecies[data.species] then
					player.radioMessage({
						messageId = "transformPotionUnlock", unique = false,
						text = "It seems that the potion you just drank may have caused some lasting alterations to your DNA, future transformations into this species should be more stable. ^#555;(Head to the ^#711;Starbecue Settings^#555; menu from the ^#711;Quickbar^#555; to customize your appearance.)"
					}, 1)
				end
			end
			world.sendEntityMessage(entity.id(), "sbqMysteriousPotionTF", data, duration )
			item.consume(1)
			world.spawnProjectile("sbqWarpInEffect", mcontroller.position(), entity.id(), { 0, 0 }, true)
			animator.playSound("activate")
		end
	end
end

function dartGunData()
	return { funcName = "transform", data = data }
end
