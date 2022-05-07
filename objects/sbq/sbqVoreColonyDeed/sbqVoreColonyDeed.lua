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
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.setGrumbles", storage.grumbles)
		end
	end
end
