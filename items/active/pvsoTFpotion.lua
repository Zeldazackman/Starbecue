function init()
	self.vehicle = "spov"..config.getParameter("spov")
	self.vso = config.getParameter("spov")
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
			local position = mcontroller.position()
			local settings = player.getProperty("vsoSettings") or {}
			local vsoSettings = sb.jsonMerge(sb.jsonMerge(root.assetJson( "/pvso_general.config"), root.assetJson( "/vehicles/spov/"..self.vso.."/"..self.vso..".vehicle" ).vso.defaultSettings or {}), settings[self.vso] or {})
			settings[self.vso] = vsoSettings

			animator.playSound("activate")

			settings.selected = self.vso
			if settings.vsos == nil then settings.vsos = {} end
			if not settings.vsos[self.vso] then
				settings.vsos[self.vso] = { enable = true }
			end

			player.setProperty("vsoSettings", settings)

			player.makeTechAvailable("vsospawner")
			player.enableTech("vsospawner")
			player.equipTech("vsospawner")

			if config.getParameter("codex") then
				world.spawnItem(config.getParameter("codex").."-codex", position, 1)
			end

			world.spawnVehicle( self.vehicle, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = vsoSettings } )

			player.radioMessage({
				messageId = self.vehicle.."1", unique = false,
				text = "It seems that the potion you just drank transformed you into "..config.getParameter("transformationDescription")..".\nScans indicate that the ^green;[E]^reset;, ^green;[F]^reset;, ^green;[G]^reset;, and ^green;[H]^reset; buttons may be helpful in this form."
			}, 1)
			player.radioMessage({
				messageId = self.vehicle.."2", unique = false,
				text = "I suggest reading the included guide for more information about how to control your new form.\n^#555;(You may have to go into settings and bind the ^#711;Tech Action 2^#555; and ^#711;3^#555; keys first.)^reset;"
			}, 5)

			item.consume(1)
		end
	end
end
