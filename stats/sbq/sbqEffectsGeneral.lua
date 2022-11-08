

function removeOtherBellyEffects()
	local name = config.getParameter("effect")
	local bellyEffectList = root.assetJson("/sbqGeneral.config").bellyStatusEffects
	for _, effect in ipairs(bellyEffectList) do
		if effect ~= name then
			status.removeEphemeralEffect(effect)
		end
	end
end

require("/items/active/sbqTransformation/sbqDuplicatePotion/sbqGetIdentity.lua")

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
				local overrideData = getIdentity(entity.id())
				local identity = overrideData.identity or {}
				local species = overrideData.species or world.entitySpecies(entity.id())
				local speciesFile = root.assetJson("/species/" .. species .. ".species")
				itemDrop.parameters.fullPortrait = world.entityPortrait(entity.id(), "full")
				itemDrop.parameters.preySpecies = species
				itemDrop.parameters.preyDirectives = (overrideData.directives or "")..(identity.bodyDirectives or "")..(identity.hairDirectives or "")
				itemDrop.parameters.preyColorMap = speciesFile.baseColorMap
				identity.name = itemDrop.parameters.prey or ""
				itemDrop.parameters.npcArgs = {
					npcSpecies = overrideData.species,
					npcType = "generictenant",
					npcLevel = 1,
					npcParam = {
						identity = identity,
						scriptConfig = {
							uniqueId = itemDrop.parameters.preyUUID
						},
						statusControllerSettings = {
							statusProperties = {
								sbqPreyEnabled = status.statusProperty("sbqPreyEnabled")
							}
						}
					}
				}
				sb.logInfo(sb.printJson(itemDrop,1))
				if preyType == "npc" then
					itemDrop.parameters.npcArgs.npcType = world.callScriptedEntity(entity.id(), "npc.npcType")
					itemDrop.parameters.npcArgs.npcLevel = world.callScriptedEntity(entity.id(), "npc.level")
					itemDrop.parameters.npcArgs.npcSeed = world.callScriptedEntity(entity.id(), "npc.seed")
				end
			end

			world.sendEntityMessage(effect.sourceEntity(), "sbqDigestDrop", itemDrop)
		end
	end
end
