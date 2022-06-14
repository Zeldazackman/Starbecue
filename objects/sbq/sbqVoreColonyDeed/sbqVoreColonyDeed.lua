---@diagnostic disable: undefined-global

local _init = init
local _onInteraction = onInteraction
local _countTags = countTags


function init()
	if not storage.settings then
		storage = config.getParameter("saveTenants") or {}
	end

	_init()

	message.setHandler("sbqSaveSettings", function (_,_, settings)
		storage.settings = settings
	end)

	message.setHandler("sbqSavePreySettings", function (_,_, settings)
		storage.preySettings = settings
	end)

	message.setHandler("sbqDeedInteract", function (_,_, args)
		_onInteraction(args)
	end)

	message.setHandler("sbqSummonNewTenant", function (_,_, newTenant)
		storage.settings = nil
		storage.preySettings = nil
		if not storage.house then return end

		evictTenants()
		if not newTenant then return end
		local success, occupier = pcall(root.tenantConfig,(newTenant))
		if not success then return end

		local data = occupier.checkRequirements or {}
		if data.checkItems then
			for i, item in ipairs(data.checkItems) do
				if not root.itemConfig(item) then return end
			end
		end
		if data.checkJson then
			if not pcall(root.assetJson, data.checkJson) then return end
		end
		if data.checkImage then
			success, notEmpty = pcall(root.nonEmptyRegion, data.checkImage)
			if not (success and notEmpty ~= nil) then return end
		end

		for _, tenant in ipairs(occupier.tenants) do
			if type(tenant.species) == "table" then
				tenant.species = tenant.species[math.random(#tenant.species)]
			end
			tenant.seed = sb.makeRandomSource():randu64()
		end
		storage.occupier = occupier
		if isOccupied() then
			respawnTenants()
			animator.setAnimationState("particles", "newArrival")
			sendNewTenantNotification()
			return
		end
	end)
end

function countTags(...)
	local tags = _countTags(...)
	tags["sbqVore"] = 1
	return tags
end

function chooseTenants(seed, tags)
	if seed then
		math.randomseed(seed)
	end

	local matches = root.getMatchingTenants(tags)
	local highestPriority = 0
	for _, tenant in ipairs(matches) do
		if tenant.priority > highestPriority then
			highestPriority = tenant.priority
		end
	end

	matches = util.filter(matches, function(match)

		local data = match.checkRequirements or {}
		if data.checkItems then
			for i, item in ipairs(data.checkItems) do
				if not root.itemConfig(item) then return end
			end
		end
		if data.checkJson then
			if not pcall(root.assetJson, data.checkJson) then return end
		end
		if data.checkImage then
			success, notEmpty = pcall(root.nonEmptyRegion, data.checkImage)
			if not (success and notEmpty ~= nil) then return end
		end

		return (match.priority >= highestPriority)
	end)
	util.debugLog("Applicable tenants:")
	for _, tenant in ipairs(matches) do
		util.debugLog("  " .. tenant.name .. " (priority " .. tenant.priority .. ")")
	end

	if #matches == 0 then
		util.debugLog("Failed to find a suitable tenant")
		return
	end

	local occupier = matches[math.random(#matches)]
	for _, tenant in ipairs(occupier.tenants) do
		if type(tenant.species) == "table" then
			tenant.species = tenant.species[math.random(#tenant.species)]
		end
		tenant.seed = sb.makeRandomSource():randu64()
	end
	storage.occupier = occupier

	if seed then
		math.randomseed(util.seedTime())
	end
end
function onInteraction(args)
	return {"ScriptPane", { data = storage, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:voreColonyDeed" }}
end

function die() -- replace the old function so the tenant isn't evicted upon breaking it
	object.setConfigParameter("saveTenants", storage)
	self.questParticipant:die()
	evictTenants()
end

function checkHouseIntegrity()
	storage.grumbles = scanHouseIntegrity()

	for _, tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() and storage.grumbles ~= nil then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.setGrumbles", storage.grumbles)
		end
	end
end

function spawn(tenant)
	local level = tenant.level or getRentLevel()
	tenant.overrides = tenant.overrides or {}
	local overrides = tenant.overrides

	overrides.scriptConfig = overrides.scriptConfig or {}
	overrides.scriptConfig.sbqSettings = tenant.settings or storage.settings

	if not overrides.damageTeamType then
		overrides.damageTeamType = "friendly"
	end
	if not overrides.damageTeam then
		overrides.damageTeam = 0
	end
	overrides.persistent = true

	local position = { self.position[1], self.position[2] }
	for i, val in ipairs(self.positionVariance) do
		if val ~= 0 then
			position[i] = position[i] + math.random(val) - (val / 2)
		end
	end

	local entityId = nil
	if tenant.spawn == "npc" then
		entityId = world.spawnNpc(position, tenant.species, tenant.type, level, tenant.seed, overrides)
		if tenant.personality then
			world.callScriptedEntity(entityId, "setPersonality", tenant.personality)
		else
			tenant.personality = world.callScriptedEntity(entityId, "personality")
		end
		if not tenant.overrides.identity then
			tenant.overrides.identity = world.callScriptedEntity(entityId, "npc.humanoidIdentity")
		end

	elseif tenant.spawn == "monster" then
		if not overrides.seed and tenant.seed then
			overrides.seed = tenant.seed
		end
		if not overrides.level then
			overrides.level = level
		end
		entityId = world.spawnMonster(tenant.type, position, overrides)

	else
		sb.logInfo("colonydeed can't be used to spawn entity type '" .. tenant.spawn .. "'")
		return nil
	end

	if tenant.seed == nil then
		tenant.seed = world.callScriptedEntity(entityId, "object.seed")
	end
	return entityId
end
