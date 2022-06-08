function init()
	activeItem.setArmAngle(-math.pi/4)
	animator.rotateTransformationGroup("potion", math.pi/4)
end

function getIdentity()
	local overrideData = status.statusProperty("speciesAnimOverrideData") or {}
	overrideData.gender = overrideData.gender or world.entityGender(entity.id())
	overrideData.species = overrideData.species or world.entitySpecies(entity.id())
	overrideData.identity = overrideData.identity or {}
	overrideData.name = world.entityName(player.id())

	local success, speciesFile = pcall(root.assetJson, ("/species/"..overrideData.species..".species"))
	if success then
		if not overrideData.identity.hairGroup and type(speciesFile) == "table" then
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == overrideData.gender then
					overrideData.identity.hairGroup = data.hairGroup or "hair"
				end
			end
		end
		if not overrideData.identity.facialHairGroup and type(speciesFile) == "table" then
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == overrideData.gender then
					overrideData.identity.facialHairGroup = data.facialHairGroup or "facialHair"
				end
			end
		end
		if not overrideData.identity.facialMaskGroup and type(speciesFile) == "table" then
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == overrideData.gender then
					overrideData.identity.facialMaskGroup = data.facialMaskGroup or "facialMask"
				end
			end
		end

		local portrait = world.entityPortrait(entity.id(), "full")
		for _, part in ipairs(portrait) do
			local imageString = part.image
			--get personality values
			if not overrideData.identity.body then
				local found1, found2 = imageString:find("body.png:idle.")
				if found1 ~= nil then
					overrideData.identity.body = imageString:sub(found2+1, found2+1)

					local directives = imageString:sub(found2+2)
					overrideData.directives = overrideData.directives or directives
				end
			end
			if not overrideData.identity.arm then
				local found1, found2 = imageString:find("backarm.png:idle.")
				if found1 ~= nil then
					overrideData.identity.arm = imageString:sub(found2+1, found2+1)
				end
			end

			if not overrideData.identity.hairType then
				local found1, found2 = imageString:find("/"..(overrideData.identity.hairGroup or "hair").."/")
				if found1 ~= nil then
					local found3, found4 = imageString:find(".png:normal")
					overrideData.identity.hairType = imageString:sub(found2+1, found3-1)

					local found5, found6 = imageString:find("?addmask=")
					local hairDirectives = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha

					overrideData.hairDirectives = overrideData.hairDirectives or hairDirectives
				end
			end

			if not overrideData.identity.facialHairType then
				local found1, found2 = imageString:find("/"..(overrideData.identity.facialHairGroup or "facialHair").."/")
				if found1 ~= nil then
					found3, found4 = imageString:find(".png")
					overrideData.identity.facialHairType = imageString:sub(found2+1, found3-1)
				end
			end

			if not overrideData.identity.facialMaskType then
				local found1, found2 = imageString:find("/"..(overrideData.identity.facialMaskGroup or "facialMask").."/")
				if found1 ~= nil then
					found3, found4 = imageString:find(".png")
					overrideData.identity.facialMaskType = imageString:sub(found2+1, found3-1)
				end
			end
		end
	end
	return overrideData
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
