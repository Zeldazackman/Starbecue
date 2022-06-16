---@diagnostic disable: undefined-global

local _init = init
local _onInteraction = onInteraction
local _countTags = countTags


function init()
	if not storage.settings then
		storage = config.getParameter("saveTenants") or {}
	end

	_init()

	message.setHandler("sbqSaveSettings", function (_,_, settings, index)
		local scriptConfig = storage.occupier.tenants[index or 1].overrides.scriptConfig or {}
		scriptConfig.sbqSettings = settings
		storage.occupier.tenants[index or 1].overrides.scriptConfig = scriptConfig
	end)

	message.setHandler("sbqSavePreySettings", function (_,_, settings, index)

		storage.occupier.tenants[index or 1].overrides.statusControllerSettings = sb.jsonMerge(
			storage.occupier.tenants[index or 1].overrides.statusControllerSettings or {},
			{statusProperties = { sbqPreyEnabled = settings}}
		)
	end)

	message.setHandler("sbqDeedInteract", function (_,_, args)
		_onInteraction(args)
	end)

	message.setHandler("sbqSummonNewTenant", function (_,_, newTenant, seed)
		if not storage.house then return animator.playSound("error") end

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

		if not seed then
			for _, tenant in ipairs(occupier.tenants) do
				if type(tenant.species) == "table" then
					tenant.species = tenant.species[math.random(#tenant.species)]
				end
				tenant.seed = sb.makeRandomSource():randu64()
			end
		else
			tenant.seed = seed
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
	if not storage.house then return animator.playSound("error") end

	return {"ScriptPane", { data = storage, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:voreColonyDeed" }}
end

function die() -- replace the old function so the tenant isn't evicted upon breaking it
	object.setConfigParameter("saveTenants", storage)
	self.questParticipant:die()
	evictTenants()
end

function checkHouseIntegrity()
	storage.grumbles, storage.possibleTortureRoom = scanHouseIntegrity()

	for _, tenant in ipairs(storage.occupier.tenants) do
		if tenant.uniqueId and world.findUniqueEntity(tenant.uniqueId):result() then
			local entityId = world.loadUniqueEntity(tenant.uniqueId)

			world.callScriptedEntity(entityId, "tenant.setGrumbles", storage.grumbles)
		end
	end

	if  #storage.grumbles > 0 and isGrumbling() and self.grumbleTimer:complete() and storage.possibleTortureRoom then
		evictTenants()
	end
end

function scanHouseIntegrity()
	if not world.regionActive(polyBoundBox(storage.house.boundary)) then
		util.debugLog("Parts of the house are unloaded - skipping integrity check")
		return storage.grumbles or {}, storage.possibleTortureRoom
	end

	local possibleTortureRoom

	local grumbles = {}
	local house = findHouseBoundary(self.position, self.maxPerimeter)

	if not house.poly then
		grumbles[#grumbles + 1] = { "enclosedArea" }
		possibleTortureRoom = true
	else
		storage.house.floorPosition = house.floor
		storage.house.boundary = house.poly

		local liquid = world.liquidAt(util.boundBox(house.poly))
		if liquid then
			grumbles[#grumbles + 1] = { "enclosedArea" }
			possibleTortureRoom = true
		end
	end

	local scanResults = scanHouseContents(storage.house.boundary)
	if scanResults.otherDeed then
		grumbles[#grumbles + 1] = { "otherDeed" }
	end
	if scanResults.bannedObject then
		grumbles[#grumbles + 1] = { "tagCriteria" }
		possibleTortureRoom = true
	end

	local objects = countObjects(scanResults.objects, house.doors or {})
	storage.house.objects = storage.house.objects or {}
	for objectName, count in pairs(objects) do
		local oldCount = storage.house.objects[objectName] or 0
		if count > oldCount then
			self.questParticipant:fireEvent("objectAdded", objectName, count - oldCount)
		end
	end
	for objectName, count in pairs(storage.house.objects) do
		local newCount = objects[objectName] or 0
		if newCount < count then
			self.questParticipant:fireEvent("objectRemoved", objectName, count - newCount)
		end
	end
	storage.house.objects = objects

	local tags = countTags(scanResults.objects, house.doors or {})
	for tag, requiredAmount in pairs(getTagCriteria()) do
		local currentAmount = tags[tag] or 0
		if currentAmount < requiredAmount then
			grumbles[#grumbles + 1] = { "tagCriteria", tag, requiredAmount - currentAmount }
		end
	end

	return grumbles, possibleTortureRoom
end

function scanVacantArea()
	local house = findHouseBoundary(self.position, self.maxPerimeter)

	local housePolyActive = house.poly and world.regionActive(polyBoundBox(house.poly))

	if housePolyActive and world.liquidAt(util.boundBox(house.poly)) ~= nil then
		util.debugLog("Liquid is within house bound box")
		animator.setAnimationState("deedState", "error")
	elseif housePolyActive then
		local scanResults = scanHouseContents(house.poly)
		if scanResults.otherDeed then
			util.debugLog("Colony deed is already present")
		elseif scanResults.objects then
			if scanResults.bannedObject then
				util.debugLog("House contains dangerous objects")
				animator.setAnimationState("deedState", "error")
				return
			end

			local tags = countTags(scanResults.objects, house.doors)
			storage.house = {
				boundary = house.poly,
				contents = tags,
				seed = scanResults.hash,
				floorPosition = house.floor,
				objects = countObjects(scanResults.objects, house.doors)
			}
			local seed = nil
			if self.hashHouseAsSeed then
				seed = scanResults.hash
			end
			chooseTenants(seed, tags)

			if isOccupied() then
				respawnTenants()
				animator.setAnimationState("particles", "newArrival")
				sendNewTenantNotification()
				return
			end
		end
	elseif not house.poly then
		util.debugLog("Scan failed")
		animator.setAnimationState("deedState", "error")
	else
		util.debugLog("Parts of the house are unloaded - skipping scan")
	end
end
