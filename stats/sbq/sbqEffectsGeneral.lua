

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
		if drop and getPreyEnabled("digestItemDrops") then
			world.sendEntityMessage(effect.sourceEntity(), "sbqDigestDrop", generateItemDrop({
				name = drop,
				count = config.getParameter("itemDropCount") or 1,
				parameters = config.getParameter("itemDropParams") or {}
			}))
		else
			local preyType = world.entityType(entity.id())
			if not preyType == "monster" then
				world.sendEntityMessage(effect.sourceEntity(), "sbqDigestStore", generateItemDrop(root.assetJson("/sbqGeneral.config:npcCardTemplate")))
			end
		end
	end
end

function generateItemDrop(itemDrop)
	local itemDrop = itemDrop

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
				wasPlayer = preyType == "player",
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
		if preyType == "npc" then
			itemDrop.parameters.npcArgs.npcType = world.callScriptedEntity(entity.id(), "npc.npcType")
			itemDrop.parameters.npcArgs.npcLevel = world.callScriptedEntity(entity.id(), "npc.level")
			itemDrop.parameters.npcArgs.npcSeed = world.callScriptedEntity(entity.id(), "npc.seed")
		end
	end

	return itemDrop
end

function getPreyEnabled(setting)
	return sb.jsonMerge(root.assetJson("/sbqGeneral.config:defaultPreyEnabled")[world.entityType(entity.id())], sb.jsonMerge((status.statusProperty("sbqPreyEnabled") or {}), (status.statusProperty("sbqOverridePreyEnabled")or {})))[setting]
end
