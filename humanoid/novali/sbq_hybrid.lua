

local _sbq_transformPlayer = sbq.transformPlayer
function sbq.transformPlayer(i)
	local data = sbq.occupant[i].progressBarData or {species = sbq.species, gender = sbq.settings.TFTG or "noChange"}
	local id = sbq.occupant[i].id
	sbq.addRPC(world.sendEntityMessage(id,"sbqGetSpeciesOverrideData"), function (overrideData)
		local success, notEmpty = pcall(root.nonEmptyRegion,("/humanoid/novali/malebody.png"))
		if success and notEmpty ~= nil
		and ((((data.species == "avali") or (data.species == "novali")) and ((overrideData.species == "novakid") or (overrideData.species == "novali")))
		or (((overrideData.species == "avali") or (overrideData.species == "novali")) and ((data.species == "novakid") or (data.species == "novali"))))
		then
			local overrideData = overrideData
			overrideData.identity = overrideData.identity or {}
			local success, speciesFile = pcall(root.assetJson, ("/species/"..overrideData.species..".species"))
			if success then -- we need to get any customize data we don't get from the override data
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

				local portrait = world.entityPortrait(sbq.occupant[i].id, "full")
				for _, part in ipairs(portrait) do
					local imageString = part.image
					--get personality values
					if not overrideData.identity.body or not overrideData.identity.bodyDirectives then
						local found1, found2 = imageString:find("body.png:idle.")
						if found1 ~= nil then
							overrideData.identity.body = imageString:sub(found2+1, found2+1)

							local directives = imageString:sub(found2+2)
							overrideData.identity.bodyDirectives = overrideData.identity.bodyDirectives or directives
						end
					end
					if not overrideData.identity.hairType or not overrideData.identity.hairDirectives then
						local found1, found2 = imageString:find("/"..(overrideData.identity.hairGroup or "hair").."/")
						if found1 ~= nil then
							local found3, found4 = imageString:find(".png:normal")
							overrideData.identity.hairType = imageString:sub(found2+1, found3-1)

							local found5, found6 = imageString:find("?addmask=")
							local hairDirectives = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha

							overrideData.identity.hairDirectives = overrideData.identity.hairDirectives or hairDirectives
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

			data.identity = {}
			if overrideData.species == "avali" then
				data.species = "novali"
				data.identity.facialHairType = "20"
				data.identity.hairType = overrideData.identity.hairType
			elseif overrideData.species == "novakid" then
				data.species = "novali"
				data.identity.facialHairType = overrideData.identity.facialHairType
				data.directives = overrideData.directives
				data.hairDirectives = overrideData.hairDirectives
			elseif overrideData.species == "novali" and data.species == "avali" then
				data.species = "avali"
				data.identity.hairType = overrideData.identity.hairType
			elseif overrideData.species == "novali" and data.species == "novakid" then
				data.species = "novakid"
				if overrideData.identity.facialHairType ~= "20" then
					data.identity.facialHairType = overrideData.identity.facialHairType
				end
				data.identity.directives = overrideData.identity.directives
				data.identity.hairDirectives = overrideData.identity.hairDirectives
			end
			if world.entitySpecies(id) == data.species then
				data.identity = nil
			end

			sbq.occupant[i].progressBarData = data
		end
		_sbq_transformPlayer(i)
	end)
end
