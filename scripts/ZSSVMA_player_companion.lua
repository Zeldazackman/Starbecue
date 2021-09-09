local oldinit = init
function init()
	oldinit()
	message.setHandler( "loadVSOsettings", function(_,_, vsoMenuName )
		local settings = player.getProperty( "vsoSettings" ) or {}
		if vsoMenuName then return settings[vsoMenuName] or {} end
		return settings.global or {}
	end)
	message.setHandler( "openPVSOInterface", function(_,_, name, args, appendSettings, sourceEntity)
		local pane = root.assetJson("/interface/scripted/pvso/"..name.."/"..name..".config")
		if args then
			pane = sb.jsonMerge(pane, args)
		end
		if appendSettings and appendSettings ~= "" then
			pane.settings = player.getProperty( "vsoSettings", {} )
			if type(appendSettings) == "string" then
				pane.settings = pane.settings[appendSettings] or {}
			end
		end
		player.interact("ScriptPane", pane, sourceEntity or entity.id())
	end)
	message.setHandler( "isLounging", function()
		return player.isLounging(), player.loungingIn()
	end)

	message.setHandler("spawnSmolPrey", function(_,_, species )
		local position = world.entityPosition( entity.id() )
		local settings = player.getProperty( "vsoSettings", {} )[species] or {}
		world.spawnVehicle( "spov"..species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true, data = species } )
	end )

	message.setHandler("useEnergy", function( _, _, energyUsed)
		return status.overConsumeResource("energy", energyUsed)
	end )

	message.setHandler("getDriverStat", function( _, _, stat)
		return status.stat(stat)
	end )

	message.setHandler("addHungerHealth", function( _, _, amount)
		if status.resourcePercentage("food") < 1 then
			status.modifyResourcePercentage( "food", amount)
			return 1
		elseif status.resourcePercentage("health") < 1 then
			status.modifyResourcePercentage( "health", amount)
			return 2
		else
			return 3
		end
	end )

	message.setHandler("unlockVSO", function(_,_, name )
		local settings = player.getProperty( "vsoSettings" ) or {}
		if settings.vsos == nil then settings.vsos = {} end
		if not settings.vsos[name] then
			settings.vsos[name] = {}
		end
		player.setProperty( "vsoSettings", settings )
	end)

	message.setHandler("getRadialSelection", function(_,_, stat)
		return player.getProperty("radialSelection")
	end)

	message.setHandler("getVSOseatEquips", function(_,_, type)
		player.setProperty( "vsoSeatType", type)
		checkLockItem(world.entityHandItemDescriptor( entity.id(), "primary" ), type)
		checkLockItem(world.entityHandItemDescriptor( entity.id(), "alt" ), type)

		return {
			head = player.equippedItem("head"),
			chest = player.equippedItem("chest"),
			legs = player.equippedItem("legs"),
			back = player.equippedItem("back"),
			headCosmetic = player.equippedItem("headCosmetic"),
			chestCosmetic = player.equippedItem("chestCosmetic"),
			legsCosmetic = player.equippedItem("legsCosmetic"),
			backCosmetic = player.equippedItem("backCosmetic"),
		}
	end)

	message.setHandler("giveVoreController", function(_,_)
		if (not player.hasItem("pvsoController")) then
			player.giveItem("pvsoController")
		end
	end)
end

local essentialItems = {"beamaxe", "wiretool", "painttool", "inspectiontool"}

function checkLockItem(itemDescriptor, type)
	if not itemDescriptor then return end
	allowedItems = root.assetJson("/vehicles/spov/pvso_general.config:pvsoAllowedItems")
	bannedTags = root.assetJson("/vehicles/spov/pvso_general.config:pvsoBannedTags")
	bannedCategories = root.assetJson("/vehicles/spov/pvso_general.config:pvsoBannedCategories")

	for i, item in ipairs(allowedItems[type]) do
		if itemDescriptor.name == item then return end
	end

	for i, item in ipairs(essentialItems) do
		local essentialItem = player.essentialItem(item)
		if essentialItem then
			if (essentialItem.name == itemDescriptor.name) then
				return lockEssentialItem(itemDescriptor, item, type)
			end
		end
	end

	for i, tag in ipairs(bannedTags[type]) do
		if root.itemHasTag(itemDescriptor.name, tag) then
			return lockItem(itemDescriptor, type)
		end
	end

	local data = root.itemConfig(itemDescriptor) or root.materialConfig(itemDescriptor.name) or root.liquidConfig(itemDescriptor.name)
	if data == nil then
		return lockItem(itemDescriptor)
	end
	for i, category in ipairs(bannedCategories[type]) do
		if category == data.config.category then
			return lockItem(itemDescriptor, type)
		end
	end
end

function lockItem(itemDescriptor, type)
	local lockItemDescriptor = player.essentialItem("inspectiontool")
	if lockItemDescriptor.name ~= "pvsoSecretTrick" then
		lockEssentialItem(lockItemDescriptor, "inspectiontool", type)
		lockItemDescriptor = player.essentialItem("inspectiontool")
	end

	local consumed = player.consumeItem(itemDescriptor, false, true)
	if consumed then
		table.insert(lockItemDescriptor.parameters.scriptStorage.itemDescriptors, consumed)
		player.giveEssentialItem("inspectiontool", lockItemDescriptor)
	end
end

function lockEssentialItem(itemDescriptor, slot, type)
	local lockItemDescriptor = root.assetJson("/vehicles/spov/pvso_general.config:lockItemDescriptor")
	lockItemDescriptor.parameters.scriptStorage.lockedEssentialItems[slot] = itemDescriptor
	lockItemDescriptor.parameters.scriptStorage.lockType = type
	player.giveEssentialItem(slot, lockItemDescriptor)
end
