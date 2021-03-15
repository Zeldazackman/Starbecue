function init()
	self.tech = config.getParameter("tech")
	self.vehicle = config.getParameter("vehicle")
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
		animator.playSound("activate")

		player.makeTechAvailable(self.tech)
		player.enableTech(self.tech)
		player.equipTech(self.tech)

		local position = mcontroller.position()
		world.spawnVehicle( "spovvaporeon", { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = {} } )

		player.radioMessage({
		messageId = "vappypotion", unique = false,
		text = "It seems that the potion you just drank transformed you into a vaporeon. Scans indicate that the ^green;[F]^reset;, ^green;[G]^reset;, and ^green;[H]^reset; buttons will be helpful in this form. ^#555;(You may have to go into settings and bind the ^#711;Tech Action 2^#555; and ^#711;3^#555; keys first.)^reset; I also am detecting a handy instruction manual for your new form came with that potion you drank."
		}, 1)

		item.consume(1)
	end
	end
end
