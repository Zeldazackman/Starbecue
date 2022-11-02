---@diagnostic disable: undefined-global

local followers = world.sendEntityMessage(player.id(), "sbqPlayerCompanions", "getCompanions", "followers"):result()

sbq.storage.occupier = { tenants = {}}

for i, follower in ipairs(followers) do
	if (follower.config.parameters.scriptConfig or {}).ownerUuid == player.uniqueId() then
		local tenant = {
			overrides = follower.config.parameters,
			species = follower.config.species,
			uniqueId = follower.uniqueId,
			type = follower.config.type,
			followerTable = follower
		}
		table.insert(sbq.storage.occupier.tenants, tenant)
	end
end

function sbq.savePredSettings()
	sbq.tenant.overrides.scriptConfig.sbqSettings = sbq.predatorSettings
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[indexes.tenantIndex].uniqueId, "sbqSaveSettings",
			sbq.predatorSettings)

		world.sendEntityMessage(player.id(), "sbqSetRecruits", "followers", followers)
	end
end
sbq.saveSettings = sbq.savePredSettings

function sbq.savePreySettings()
	sbq.tenant.overrides.statusControllerSettings.statusProperties.sbqPreyEnabled = sbq.preySettings
	if sbq.storage.occupier then
		world.sendEntityMessage(sbq.storage.occupier.tenants[indexes.tenantIndex].uniqueId, "sbqSavePreySettings",
			sbq.preySettings)

		world.sendEntityMessage(player.id(), "sbqSetRecruits", "followers", followers)
	end
end
