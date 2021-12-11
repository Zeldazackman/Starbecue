s = {}

function init()
	if not storage.vehicle then
		storage = config.getParameter("scriptStorage")
	end

	reload()

	message.setHandler( "sbqSaveSettings", function(_,_, settings )
		storage.settings = settings
	end)
end

function reload()
	if storage.vehicle ~= nil then
		s.vehicle = storage.vehicle.type
		local offset = config.getParameter("spawnOffset") or {0,0}
		local position = {offset[1]+storage.vehicle.position[1], offset[2]+storage.vehicle.position[2]}
		s.spawnPosition = localToGlobal(position)

		if storage.settings == nil and storage.vehicle.settings ~= nil then
			storage.settings = sb.jsonMerge(root.assetJson("/sbqGeneral.config").defaultSettings, storage.vehicle.settings)
		end
		object.setInteractive(false)
	end
end

function localToGlobal(position)
	local lpos = { position[1], position[2] }
	if object.direction() == -1 then lpos[1] = -lpos[1] end
	local mpos = object.position()
	local gpos = { mpos[1] + lpos[1], mpos[2] + lpos[2] }
	return world.xwrap( gpos )
end

s.vehicleId = nil

function update(dt)
	if object.uniqueId() == nil then
		object.setUniqueId(sb.makeUuid())
	end
	if storage.vehicle ~= nil then
		if (s.vehicleId == nil) or (not world.entityExists(s.vehicleId)) then
			s.vehicleId = world.spawnVehicle( s.vehicle, s.spawnPosition, { spawner = entity.id(), settings = storage.settings, direction = object.direction() } )
		end
	else
		object.setInteractive(false)
		local players = world.playerQuery(object.position(), 10)
		for _, player in ipairs(players) do
			local primary = world.entityHandItem(player, "primary")
			local alt = world.entityHandItem(player, "alt")
			if (primary ~= nil and (root.itemType(primary) == "augmentitem")) or (alt ~= nil and (root.itemType(alt) == "augmentitem")) then
				object.setInteractive(true)
			end
		end
	end
end

function checkAugmentInHand(eid, hand)
end

function die()
	if s.vehicleId ~= nil and world.entityExists(s.vehicleId) then
		world.sendEntityMessage(s.vehicleId, "despawn")
	end
end

function onInteraction(args)
	if eatHandItem(args.sourceId, "primary") then return end
	if eatHandItem(args.sourceId, "alt") then return end
end

function eatHandItem(entity, hand)
	local item = world.entityHandItemDescriptor(entity, hand)
	local data = root.itemConfig(item)
	if item ~= nil and root.itemType(item.name) == "augmentitem" and data.config.vehicle ~= nil then
		if data.config.scriptStorage ~= nil then
			storage.settings = data.config.scriptStorage.settings
		end
		storage.vehicle = data.config.vehicle
		world.sendEntityMessage(entity, "sbqEatItem", item, false, true)
		reload()
	end
end
