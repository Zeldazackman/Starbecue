---@diagnostic disable: undefined-global
local initStage = 0
local oldinit = init
sbq = {}
require("/scripts/SBQ_RPC_handling.lua")
require("/scripts/SBQ_species_config.lua")

local prey = {}

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
			message = "Monster Core Loader missing.\n \nThis is not required, but without it you may find some mod incompatibilities, especially with FU.\n \nMake sure to read install information."
		})
	end
	if (not pcall(root.assetJson,("/stats/speciesAnimOverride/speciesAnimOverride.animation"))) then
		player.confirm({
			paneLayout = "/interface/windowconfig/popup.config:paneLayout",
			icon = "/interface/errorpopup/erroricon.png",
			title = "Starbecue Mod Requirement Warning",
			message = "If you had read the install directions, you would have installed the required starboundSpeciesAnimOverrides.pak file on the releases page."
		})
	end
	if root.itemConfig("spovpilldonut") ~= nil then
		player.confirm({
			paneLayout = "/interface/windowconfig/popup.config:paneLayout",
			icon = "/interface/errorpopup/erroricon.png",
			title = "Starbecue Mod Conflict Warning",
			message = "Zygan SSVM Addons detected.\n \nThat mod is an older version of Starbecue before it was renamed, please remove it."
		})
	end

	message.setHandler( "sbqPlayerCompanions", function (_,_, func, ...)
		return playerCompanions[func](...)
	end)
	message.setHandler( "sbqSetRecruits", function (_,_, name, data)
		recruitSpawner[name] = recruitSpawner:_loadRecruits(data or {})
		recruitSpawner:markDirty()
	end)

	message.setHandler( "sbqRequestFollow", function (_,_, uniqueId, recruitUuid, recruitInfo)
		if not checkCrewLimits(recruitUuid) then
			return false
		end
		promises:add(world.sendEntityMessage(uniqueId, "recruit.confirmFollow"), function(success)
			recruitSpawner:recruitFollowing(onOwnShip(), recruitUuid, recruitInfo)
		end)
	end)

	message.setHandler( "sbqPreyWarp", function(_,_, uuid, prey)
		player.setProperty("sbqPreyWarpData", {uuid = uuid, prey = prey})
	end)

	message.setHandler("addPrey", function( _, _, data)
		table.insert(prey, data)
		return true
	end )

	message.setHandler( "sbqLoadSettings", function(_,_, menuName )
		local settings = player.getProperty( "sbqSettings" ) or {}
		if menuName then return sb.jsonMerge(settings[menuName] or {}, settings.global or {}) end
		return settings
	end)

	message.setHandler( "sbqSaveSettings", function(_,_, settings, menuName )
		local sbqSettings = player.getProperty( "sbqSettings" ) or {}
		sbqSettings[menuName] = settings
		player.setProperty( "sbqSettings", sbqSettings )
		world.sendEntityMessage(player.id(), "sbqRefreshSettings", sbqSettings )
	end)

	message.setHandler( "sbqOpenMetagui", function(_,_, name, sourceEntity, data)
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
	message.setHandler( "sbqPlayerInteract", function(_,_, data, id)
		if not data then return end
		player.interact(data[1], data[2], id)
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
		status.setStatusProperty( "sbqCurrentData", current)
		if not (current.type == "driver" and current.species == "sbqOccupantHolder") then
			sbq.checkLockItem(world.entityHandItemDescriptor( entity.id(), "primary" ), type)
			sbq.checkLockItem(world.entityHandItemDescriptor( entity.id(), "alt" ), type)
		end

		return {
			head = player.equippedItem("head") or false,
			chest = player.equippedItem("chest") or false,
			legs = player.equippedItem("legs") or false,
			back = player.equippedItem("back") or false,
			headCosmetic = player.equippedItem("headCosmetic") or false,
			chestCosmetic = player.equippedItem("chestCosmetic") or false,
			legsCosmetic = player.equippedItem("legsCosmetic") or false,
			backCosmetic = player.equippedItem("backCosmetic") or false,
			statusDirectives = status.statusProperty("speciesAnimOverrideDirectives"),
			effectDirectives = status.statusProperty("effectDirectives")
		}
	end)

	message.setHandler("sbqGiveController", function(_,_)
		if (not player.hasItem("sbqController")) then
			player.giveItem("sbqController")
		end
	end)

	message.setHandler("sbqDigestDrop", function(_,_, itemDrop)
		local itemDrop = itemDrop
		local overrideData = status.statusProperty("speciesAnimOverrideData") or {}
		local identity = overrideData.identity or {}
		local species = player.species()
		local speciesFile = root.assetJson("/species/"..species..".species")
		itemDrop.parameters.predSpecies = species
		itemDrop.parameters.predDirectives = (overrideData.directives or "")..(identity.bodyDirectives or "")..(identity.hairDirectives or "")
		itemDrop.parameters.predColorMap = speciesFile.baseColorMap
		if itemDrop.parameters.predDirectives == "" then
			local portrait = world.entityPortrait(entity.id(), "full")
			local hairGroup
			local gotBody
			local gotHair
			for i, data in ipairs(speciesFile.genders or {}) do
				if data.name == world.entityGender(entity.id()) then
					hairGroup = data.hairGroup or "hair"
				end
			end
			for _, part in ipairs(portrait) do
				local imageString = part.image
				if not gotBody then
					local found1, found2 = imageString:find("body.png:idle.")
					if found1 ~= nil then
						local found3 = imageString:find("?")
						gotBody = imageString:sub(found3)
					end
				end
				if not gotHair then
					local found1, found2 = imageString:find("/"..(hairGroup or "hair").."/")
					if found1 ~= nil then
						local found3, found4 = imageString:find(".png:normal")

						local found5, found6 = imageString:find("?addmask=")
						gotHair = imageString:sub(found4+1, (found5 or 0)-1) -- this is really elegant haha
					end
				end
				if gotHair and gotBody then break end
			end
			itemDrop.parameters.predDirectives = gotBody..gotHair
		end

		player.giveItem(itemDrop)
	end)

	message.setHandler("sbqGiveItem", function(_,_, item)
		player.giveItem(item)
	end)


	message.setHandler("sbqEatItem", function(_,_, item, partial, match)
		player.consumeItem(item, partial, match )
	end)

	message.setHandler("sbqPredatorDespawned", function (_,_, eaten, species, occupants)
		status.setStatusProperty("sbqPreyList", nil)
		world.sendEntityMessage(player.id(), "sbqRefreshSettings", player.getProperty( "sbqSettings") or {} )
		world.sendEntityMessage(player.id(), "sbqLight")

		if not eaten then
			for i, effect in ipairs(root.assetJson("/sbqGeneral.config").predStatusEffects) do
				status.removeEphemeralEffect(effect)
			end
			if species == "sbqOccupantHolder" and occupants == 0 and not (status.statusProperty("speciesAnimOverrideData") or {}).permanent then
				status.clearPersistentEffects("speciesAnimOverride")
			end
		end

		player.setProperty( "sbqCurrentData", nil)
		status.setStatusProperty( "sbqCurrentData", nil)
	end)

	message.setHandler("sbqEscape", function ()
		if player.loungingIn() ~= nil then
			world.sendEntityMessage( player.loungingIn(), "uneat", player.id() )
		end
	end)

	message.setHandler("sbqGetSpeciesVoreConfig", function (_,_)
		sbq.getSpeciesConfig(player.species())

		local speciesAnimOverrideData = status.statusProperty("speciesAnimOverrideData") or {}
		status.setStatusProperty("sbqOverridePreyEnabled", sbq.speciesConfig.sbqData.overridePreyEnabled)

		local effects = status.getPersistentEffects("speciesAnimOverride")
		if not effects[1] then
			status.setPersistentEffects("speciesAnimOverride", {  speciesAnimOverrideData.customAnimStatus or "speciesAnimOverride" })
		end
		status.clearPersistentEffects("digestImmunity")
		status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
		return {sbq.speciesConfig, status.statusProperty("animOverrideScale") or 1, status.statusProperty("animOverridesGlobalScaleYOffset") or 0}
	end)

	message.setHandler("sbqUnlockedSpecies", function ()
		player.radioMessage({
			messageId = "transformPotionUnlock", unique = false,
			text = "Scans indicate that may have caused some lasting alterations to your DNA, future transformations into this species should be more stable. ^#555;(Head to the ^#711;Starbecue Settings^#555; menu from the ^#711;Quickbar^#555; to customize your appearance.)"
		}, 1)
	end)

	if initStage < 1 then
		function Recruit:_spawn(position, parameters)

			self.uniform = nil
			if parameters.scriptConfig.preservedUuid then
				parameters.scriptConfig.uniqueId = parameters.scriptConfig.preservedUuid
				self.uniqueId = parameters.scriptConfig.preservedUuid

				sbq.addRPC(world.findUniqueEntity(parameters.scriptConfig.preservedUuid), function(result)
					if not result then
						world.spawnNpc(position, self.spawnConfig.species, self.spawnConfig.type, parameters.level, self.spawnConfig.seed, parameters)
					end
				end, function()
					world.spawnNpc(position, self.spawnConfig.species, self.spawnConfig.type, parameters.level, self.spawnConfig.seed, parameters)
				end)
			else
				world.spawnNpc(position, self.spawnConfig.species, self.spawnConfig.type, parameters.level, self.spawnConfig.seed, parameters)
			end
		end
	end

	status.clearPersistentEffects("digestImmunity")
	status.setPersistentEffects("digestImmunity", {"sbqDigestImmunity"})
	initStage = 1 -- init has run
end

local predNotFound
local warpAttempts = 0
local oldupdate = update
function update(dt)
	oldupdate(dt)
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)

	local current = player.getProperty("sbqCurrentData") or {}
	if current.id and initStage >= 2 then
		for i, preyData in ipairs(prey) do
			status.removeEphemeralEffect("sbqInvisible")
			status.addEphemeralEffect("sbqInvisible")
			world.sendEntityMessage(current.id, "addPrey", preyData)
		end
		prey = {}
	end

	local preyWarpData = player.getProperty("sbqPreyWarpData")
	if preyWarpData and (not preyWarpData.uuid or #preyWarpData.uuid ~= 32) then
		preyWarpData = nil
		player.setProperty("sbqPreyWarpData", nil)
	end
	if preyWarpData then
		status.removeEphemeralEffect("sbqInvisible")
		status.addEphemeralEffect("sbqInvisible")
		if not predNotFound then
			preyWarpData.prey.id = player.id()
			local players = world.playerQuery(world.entityPosition(player.id()), 1000)
			local gotPlayer
			for i, eid in ipairs(players or {}) do
				if world.entityUniqueId(eid) == preyWarpData.uuid then
					gotPlayer = eid
					break
				end
			end
			if gotPlayer then
				sbq.loopedMessage("sendPrey", gotPlayer, "addPrey", {preyWarpData.prey}, function (got)
					if got then
						player.setProperty("sbqPreyWarpData", nil)
						predNotFound = nil
					end
				end)
			else
				local cooldown = preyWarpData.cooldown or 0
				local loopedMessages = 0
				for _, _ in pairs(sbq.loopedMessages or {}) do
					loopedMessages = loopedMessages + 1
				end
				if warpAttempts >= 2 then
					predNotFound = true
					sbq.addRPC(player.confirm({
						paneLayout = "/interface/windowconfig/waitForPred.config:paneLayout",
						message = "Your Pred seems to have left, do you want to wait for them to come back?",
						icon = "/interface/scripted/sbq/sbqSettings/preySettings.png",
						title = "Predator Has Left",
					}), function (choice)
						if choice then
							predNotFound = nil
							warpAttempts = 0
						else
							player.setProperty("sbqPreyWarpData", nil)
							predNotFound = nil
						end
					end, function ()
						player.setProperty("sbqPreyWarpData", nil)
						predNotFound = nil
					end)
				elseif cooldown <= 0 and #sbq.rpcList == 0 and loopedMessages == 0 then
					player.warp("Player:" .. preyWarpData.uuid)
					warpAttempts = warpAttempts + 1
					preyWarpData.cooldown = 5
				else
					preyWarpData.cooldown = math.max( 0, cooldown - dt )
				end
				player.setProperty("sbqPreyWarpData", preyWarpData)
			end
		end
	end


	-- make sure init has happened
	if initStage ~= 1 then return end
	-- make sure the world is loaded
	if world.pointTileCollision(entity.position(), {"Null"}) then return end
	-- now we can actually do things
	if not preyWarpData then
		if current.species then
			world.spawnVehicle(current.species, entity.position(), {
				driver = player.id(), layer = current.layer, startState = current.state,
				settings = current.settings,
			})
		elseif current.type == "prey" then
			for i, effect in ipairs(root.assetJson("/sbqGeneral.config").predStatusEffects) do
				status.removeEphemeralEffect(effect)
			end
		end
		player.setProperty("sbqCurrentData", nil) -- after spawning the vehicle, clear it so it can set its own current data
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

	local lockItemDescriptor = player.essentialItem("painttool") or {}
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
