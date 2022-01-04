local initStage = 0
local oldinit = init
sbq = {}
function init()
	oldinit()

	player.setUniverseFlag("foodhall_auriShop")

	if not pcall(root.assetJson,("/metagui/registry.json")) then
		player.confirm({
			paneLayout = "/interface/windowconfig/popup.config:paneLayout",
			icon = "/interface/errorpopup/erroricon.png",
			title = "Starbecue Mod Requirement Warning",
			message = "Stardust Core or Stardust Lite missing.\n \nMake sure to read install information."
		})
	end
	if (not pcall(root.assetJson,("/stats/monster_compat_list.config"))) and not player.getProperty("sbqMonsterCoreLoaderWarned") then
		player.setProperty("sbqMonsterCoreLoaderWarned", true)
		player.confirm({
			paneLayout = "/interface/windowconfig/popup.config:paneLayout",
			icon = "/interface/errorpopup/erroricon.png",
			title = "Starbecue Mod Requirement Warning",
			message = "Monster Core Loader missing.\n \nThis is not required, but without it you may find some mod incompatibilities.\n \nMake sure to read install information."
		})
	end
	sb.logInfo("The following error from lack of '/vehicles/spov/vaporeon/vaporeon.vehicle' is not truly an error, merely the result of checking if an older version of the mod is still installed. Even under a pcall, root.assetJson still logs the error")
	if pcall(root.assetJson,("/vehicles/spov/vaporeon/vaporeon.vehicle")) then
		player.confirm({
			paneLayout = "/interface/windowconfig/popup.config:paneLayout",
			icon = "/interface/errorpopup/erroricon.png",
			title = "Starbecue Mod Conflict Warning",
			message = "Zygan SSVM Addons detected.\n \nThat mod is an older version of Starbecue before it was renamed, please remove it."
		})
	end


	message.setHandler( "sbqLoadSettings", function(_,_, menuName )
		local settings = player.getProperty( "sbqSettings" ) or {}
		if menuName then return sb.jsonMerge(settings[menuName] or {}, settings.global or {}) end
		return settings
	end)
	message.setHandler( "sbqPlayerSaveSettings", function(_,_, settings )
		player.setProperty( "sbqSettings", settings )
	end)
	message.setHandler( "sbqSaveSettings", function(_,_, settings, menuName )
		local sbqSettings = player.getProperty( "sbqSettings" ) or {}
		sbqSettings[menuName] = settings
		player.setProperty( "sbqSettings", sbqSettings )
		world.sendEntityMessage(player.id(), "sbqRefreshSettings", sbqSettings )
	end)

	message.setHandler( "sbqOpenMetagui", function(_,_, name, sourceEntity)
		player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = name }, sourceEntity )
	end)

	message.setHandler( "sbqOpenInterface", function(_,_, name, args, appendSettings, sourceEntity)
		local pane = root.assetJson("/interface/scripted/sbq/"..name.."/"..name..".config")
		if args then
			pane = sb.jsonMerge(pane, args)
		end
		if appendSettings and appendSettings ~= "" then
			pane.settings = player.getProperty( "sbqSettings", {} )
			if type(appendSettings) == "string" then
				pane.settings = pane.settings[appendSettings] or {}
			end
		end
		player.interact("ScriptPane", pane, sourceEntity or entity.id())
	end)

	message.setHandler( "sbqLoungingIn", function()
		return player.loungingIn()
	end)

	message.setHandler("sbqSpawnSmolPrey", function(_,_, species )
		local position = world.entityPosition( entity.id() )
		local settings = player.getProperty( "sbqSettings", {} )[species] or {}
		world.spawnVehicle( species, { position[1], position[2] + 1.5 }, { driver = entity.id(), settings = settings, uneaten = true, data = species } )
	end )

	message.setHandler("sbqUseEnergy", function( _, _, energyUsed)
		return status.overConsumeResource("energy", energyUsed)
	end )

	message.setHandler("sbqAddHungerHealth", function( _, _, amount)
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

	message.setHandler("sbqGetDriverStat", function( _, _, stat)
		return status.stat(stat)
	end )

	message.setHandler("sbqUnlockType", function(_,_, name )
		local settings = player.getProperty( "sbqSettings" ) or {}
		if settings.types == nil then settings.types = {} end
		if not settings.types[name] then
			settings.types[name] = { enable = true }
		end
		player.setProperty( "sbqSettings", settings )
	end)

	message.setHandler("sbqGetRadialSelection", function(_,_, stat)
		return player.getProperty("sbqRadialSelection") or {}
	end)

	message.setHandler("sbqGetSeatEquips", function(_,_, current)
		local type = current.type or "prey"
		player.setProperty( "sbqCurrentData", current)
		sbq.checkLockItem(world.entityHandItemDescriptor( entity.id(), "primary" ), type)
		sbq.checkLockItem(world.entityHandItemDescriptor( entity.id(), "alt" ), type)

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

	message.setHandler("sbqGiveController", function(_,_)
		if (not player.hasItem("sbqController")) then
			player.giveItem("sbqController")
		end
	end)

	message.setHandler("sbqGiveItem", function(_,_, item)
		player.giveItem(item)
	end)


	message.setHandler("sbqEatItem", function(_,_, item, partial, match)
		player.consumeItem(item, partial, match )
	end)

	message.setHandler("sbqPredatorDespawned", function ()
		world.sendEntityMessage(player.id(), "sbqRefreshSettings", player.getProperty( "sbqSettings") or {} )
		player.setProperty( "sbqCurrentData", nil)
	end)

	local sbqPreyEnabled = status.statusProperty("sbqPreyEnabled") or {}
	if sbqPreyEnabled.digestImmunity then
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	end

	initStage = 1 -- init has run
end

local oldupdate = update
function update(dt)
	oldupdate(dt)
	-- make sure init has happened
	if initStage ~= 1 then return end
	-- make sure the world is loaded
	if world.pointTileCollision(entity.position(), {"Null"}) then return end
	-- now we can actually do things
	local current = player.getProperty("sbqCurrentData") or {}
	if current.species then
		world.spawnVehicle(current.species, entity.position(), {
			driver = player.id(), layer = current.layer, startState = current.state,
			settings = player.getProperty( "sbqSettings", {} )[current.species] or {},
		})
	elseif current.type == "prey" then
		player.setProperty("sbqCurrentData", {})
		status.removeEphemeralEffect("sbqInvisible")
		status.removeEphemeralEffect("sbqScaling")
	end
	initStage = 2 -- post-init finished
end

local essentialItems = {"beamaxe", "wiretool", "painttool", "inspectiontool"}

function sbq.checkLockItem(itemDescriptor, type)
	if not itemDescriptor then return end
	allowedItems = root.assetJson("/sbqGeneral.config:sbqAllowedItems")
	bannedTags = root.assetJson("/sbqGeneral.config:sbqBannedTags")
	bannedTypes = root.assetJson("/sbqGeneral.config:sbqBannedItemTypes")

	if allowedItems[type][itemDescriptor.name] then return end

	for i, item in ipairs(essentialItems) do
		local essentialItem = player.essentialItem(item)
		if essentialItem then
			if (essentialItem.name == itemDescriptor.name) then
				return sbq.lockEssentialItem(itemDescriptor, item, type)
			end
		end
	end

	for i, tag in ipairs(bannedTags[type]) do
		if root.itemHasTag(itemDescriptor.name, tag) then
			return sbq.lockItem(itemDescriptor, type)
		end
	end

	if bannedTypes[type][root.itemType(itemDescriptor.name)] then return sbq.lockItem(itemDescriptor, type) end
end

function sbq.lockItem(itemDescriptor, type)
	if itemDescriptor.parameters ~= nil and itemDescriptor.parameters.itemHasOverrideLockScript then
		return world.sendEntityMessage(entity.id(), itemDescriptor.name.."Lock", true)
	end
	if root.itemType(itemDescriptor.name) == "activeitem" and (not itemDescriptor.parameters or not itemDescriptor.parameters.itemHasOverrideLockScript) then
		return giveHeldItemOverrideLockScript(itemDescriptor) ---@diagnostic disable-line:undefined-global
	end

	local lockItemDescriptor = player.essentialItem("painttool")
	if lockItemDescriptor.name ~= "sbqLockedItem" then
		sbq.lockEssentialItem(lockItemDescriptor, "painttool", type)
		lockItemDescriptor = player.essentialItem("painttool")
	end

	local consumed = player.consumeItem(itemDescriptor, false, true)
	if consumed then
		local lockedItemList = player.getProperty( "sbqLockedItems" ) or {}
		table.insert(lockedItemList, consumed)
		player.setProperty( "sbqLockedItems", lockedItemList )
	end
end

function sbq.lockEssentialItem(itemDescriptor, slot, type)
	local lockItemDescriptor = root.assetJson("/sbqGeneral.config:lockItemDescriptor")
	lockItemDescriptor.parameters.scriptStorage.lockedEssentialItems[slot] = itemDescriptor
	lockItemDescriptor.parameters.scriptStorage.lockType = type
	player.giveEssentialItem(slot, lockItemDescriptor)
end
