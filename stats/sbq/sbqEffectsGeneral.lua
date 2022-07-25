

function removeOtherBellyEffects()
	local name = config.getParameter("effect")
	local bellyEffectList = root.assetJson("/sbqGeneral.config").bellyStatusEffects
	for _, effect in ipairs(bellyEffectList) do
		if effect ~= name then
			status.removeEphemeralEffect(effect)
		end
	end
end

function doItemDrop()
	if self.dropItem and not self.droppedItem then
		self.droppedItem = true
		local drop = config.getParameter("itemDrop")
		if drop then
			local itemDrop = {
				name = drop,
				count = 1,
				parameters = {

				}
			}
			local predType = world.entityType(effect.sourceEntity())
			local preyType = world.entityType(entity.id())

			if predType == "npc" or predType == "player" then
				itemDrop.parameters.pred = world.entityName(effect.sourceEntity())
				itemDrop.parameters.predUUID = world.entityUniqueId(effect.sourceEntity())
			end
			if preyType == "npc" or preyType == "player" then
				itemDrop.parameters.prey = world.entityName(entity.id())
				itemDrop.parameters.preyUUID = world.entityUniqueId(entity.id())
				local overrideData = status.statusProperty("speciesAnimOverrideData") or {}
				local identity = overrideData.identity or {}
				local species = overrideData.species or world.entitySpecies(entity.id())
				local speciesFile = root.assetJson("/species/"..species..".species")
				itemDrop.parameters.preySpecies = species
				itemDrop.parameters.preyDirectives = (overrideData.directives or "")..(identity.bodyDirectives or "")..(identity.hairDirectives or "")
				itemDrop.parameters.preyColorMap = speciesFile.baseColorMap
				if itemDrop.parameters.preyDirectives == "" then
					local portrait = world.entityPortrait(entity.id(), "full")
					local hairGroup
					local gotBody
					local gotHair
					for i, data in ipairs(speciesFile.genders or {}) do
						if data.name == world.entityGender(entity.id()) then
							hairGroup = data.hairGroup or "hair"
						end
					end
					for _, part in ipairs(portrait) do
						local imageString = part.image
						if not gotBody then
							local found1, found2 = imageString:find("body.png:idle.")
							if found1 ~= nil then
								local found3 = imageString:find("?")
								gotBody = imageString:sub(found3)
							end
						end
						if not gotHair then
							local found1, found2 = imageString:find("/"..(hairGroup or "hair").."/")
							if found1 ~= nil then
								local found3, found4 = imageString:find(".png:normal")

								local found5, found6 = imageString:find("?addmask=")
								gotHair = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha
							end
						end
						if gotHair and gotBody then break end
					end
					itemDrop.parameters.preyDirectives = gotBody..gotHair
				end
			end

			world.sendEntityMessage(effect.sourceEntity(), "sbqDigestDrop", itemDrop)
		end
	end
end
