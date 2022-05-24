function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
end

function getIdentity()
	self = status.statusProperty("speciesAnimOverrideData")
	self.gender = self.gender or world.entityGender(entity.id())
	self.species = self.species or world.entitySpecies(entity.id())
	self.identity = self.identity or {}
	self.name = world.entityName(player.id())

	local success, speciesFile = pcall(root.assetJson, ("/species/"..self.species..".species"))
	if success then
		if not self.identity.hairGroup and type(speciesFile) == "table" then
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == self.gender then
					self.identity.hairGroup = data.hairGroup or "hair"
				end
			end
		end
		if not self.identity.facialHairGroup and type(speciesFile) == "table" then
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == self.gender then
					self.identity.facialHairGroup = data.facialHairGroup or "facialHair"
				end
			end
		end
		if not self.identity.facialMaskGroup and type(speciesFile) == "table" then
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == self.gender then
					self.identity.facialMaskGroup = data.facialMaskGroup or "facialMask"
				end
			end
		end

		local portrait = world.entityPortrait(entity.id(), "full")
		for _, part in ipairs(portrait) do
			local imageString = part.image
			--get personality values
			if not self.identity.body then
				local found1, found2 = imageString:find("body.png:idle.")
				if found1 ~= nil then
					self.identity.body = imageString:sub(found2+1, found2+1)

					local directives = imageString:sub(found2+2)
					self.directives = self.directives or directives
				end
			end
			if not self.identity.arm then
				local found1, found2 = imageString:find("backarm.png:idle.")
				if found1 ~= nil then
					self.identity.arm = imageString:sub(found2+1, found2+1)
				end
			end

			if not self.identity.hairType then
				local found1, found2 = imageString:find("/"..(self.identity.hairGroup or "hair").."/")
				if found1 ~= nil then
					local found3, found4 = imageString:find(".png:normal")
					self.identity.hairType = imageString:sub(found2+1, found3-1)

					local found5, found6 = imageString:find("?addmask=")
					local hairDirectives = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha

					self.hairDirectives = self.hairDirectives or hairDirectives
				end
			end

			if not self.identity.facialHairType then
				local found1, found2 = imageString:find("/"..(self.identity.facialHairGroup or "facialHair").."/")
				if found1 ~= nil then
					found3, found4 = imageString:find(".png")
					self.identity.facialHairType = imageString:sub(found2+1, found3-1)
				end
			end

			if not self.identity.facialMaskType then
				local found1, found2 = imageString:find("/"..(self.identity.facialMaskGroup or "facialMask").."/")
				if found1 ~= nil then
					found3, found4 = imageString:find(".png")
					self.identity.facialMaskType = imageString:sub(found2+1, found3-1)
				end
			end
		end
	end
	return self
end

function update(dt, fireMode, shiftHeld)
	if fireMode == "primary" and not activeItem.callOtherHandScript("isDartGun") then
		player.giveItem({name = "sbqMysteriousPotion", parameters = getIdentity()})
		item.consume(1)
	end
end

function dartGunData()
	return { funcName = "transform", data = getIdentity()}
end
