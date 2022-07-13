

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
			local pred
			local prey
			local predUUID
			local preyUUID
			local predType = world.entityType(effect.sourceEntity())
			local preyType = world.entityType(entity.id())

			if predType == "npc" or predType == "player" then
				pred = world.entityName(effect.sourceEntity())
				predUUID = world.entityUniqueId(effect.sourceEntity())
			end
			if preyType == "npc" or preyType == "player" then
				prey = world.entityName(entity.id())
				preyUUID = world.entityUniqueId(entity.id())
			end

			world.spawnItem(drop, mcontroller.position(), 1, { pred = pred, predUUID = predUUID, prey = prey, preyUUID = preyUUID })
		end
	end
end
