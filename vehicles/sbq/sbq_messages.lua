message.setHandler( "settingsMenuSet", function(_,_, val )
	sbq.settings = sb.jsonMerge(sbq.settings, sb.jsonMerge(val, sbq.sbqData.overrideSettings or {}))
	sbq.setColorReplaceDirectives()
	sbq.setSkinPartTags()
	sbq.settingsMenuUpdated()
end )

message.setHandler( "letout", function(_,_, id )
	sbq.letout(id)
end )

message.setHandler( "eggify", function(_,_, eid, data)
	if not eid or not sbq.lounging[eid] then return end
	local location = sbq.lounging[eid].location
	sbq.addRPC( world.sendEntityMessage(eid, "sbqIsPreyEnabled", (data or sbq.sbqData.locations[location].eggify or {}).immunity or "eggImmunity"), function (enabled)
		if enabled and not enabled.enabled then
			sbq.transformMessageHandler(eid, data or sbq.sbqData.locations[location].eggify, "eggify")
		end
	end)
end)
message.setHandler( "transform", function(_,_, eid, data)
	local location = sbq.lounging[eid].location
	sbq.addRPC( world.sendEntityMessage(eid, "sbqIsPreyEnabled", (data or sbq.sbqData.locations[location].TF or {}).immunity or "transformImmunity"), function (enabled)
		if enabled and not enabled.enabled then
			sbq.transformMessageHandler(eid, data or sbq.sbqData.locations[location].TF)
		end
	end)
end)

function sbq.transformMessageHandler(eid, TF, TFType)
	if sbq.lounging[eid] == nil or sbq.lounging[eid].progressBarActive then return end
	local location = sbq.lounging[eid].location
	local TF = sb.jsonMerge(TF or sbq.sbqData.locations[location][TFType or "TF"] or {}, {})
	if TF.preset then
		TF.data =  sb.jsonMerge(sbq.config.victimTransformPresets[TF.preset] or {}, {})
	end
	local isOccupantHolderDefault = (world.entityName(entity.id()) == "sbqOccupantHolder" and type((TF.data or {}).species) == "nil")
	TF.data = TF.data or { species = sbq.species, gender = sbq.settings.TFTG or "noChange" }

	if TF.data.randomSpecies then
		TF.data.species = TF.data.randomSpecies[math.random(#TF.data.randomSpecies)]
	end
	for setting, values in pairs(TF.data.randomSettings or {}) do
		TF.data.settings[setting] = values[math.random(#values)]
	end
	for i, setting in ipairs(TF.data.inheritSettings or {}) do
		TF.data.settings[setting] = sbq.settings[setting]
	end
	if not TF.data.gender then
		TF.data.gender = sbq.settings.TFTG or "noChange"
	end
	if TF.data.randomColors then
		local predatorConfig = root.assetJson("/vehicles/sbq/"..TF.data.species.."/"..TF.data.species..".vehicle").sbqData
		local replaceColors =  TF.data.replaceColors or "replaceColors"
		local offset = type(TF.data.replaceColors) == "nil" and 1 or 0
		local replaceColorTable = {}
		for i, colorTable in ipairs(predatorConfig[replaceColors] or {}) do
			replaceColorTable[i] = colorTable[math.random(#colorTable-offset)+offset]
		end
		TF.data.settings.replaceColorTable = replaceColorTable
	end
	TF.locations = TF.locations or { [location] = true }

	sbq.lounging[eid].progressBarLocations = TF.locations
	sbq.lounging[eid].progressBarActive = true
	sbq.lounging[eid].progressBar = 0
	sbq.lounging[eid].progressBarData = sb.jsonMerge(TF.data or {}, {})
	sbq.lounging[eid].progressBarMultiplier = TF.multiplier or 3

	if type(TF.barColor) == "table" then
		sbq.lounging[eid].progressBarColor = TF.barColor
	else
		sbq.lounging[eid].progressBarColor = (
			(((TF.data.settings or {}).replaceColorTable or {})[1])
			or (sbq.settings.replaceColorTable[TF.data.replaceColorIndex or 1])
			or (((sbq.sbqData.replaceColors or {})[TF.data.replaceColorIndex or 1] or {})[((sbq.settings.replaceColors or {})[TF.data.replaceColorIndex or 1]
			or (sbq.sbqData.defaultSettings.replaceColors or {})[TF.data.replaceColorIndex or 1] or 1) + 1]) -- pred body color
			or sbq.sbqData.defaultProgressBarColor
		)
	end
	if sbq.lounging[eid].species == "sbqOccupantHolder" then
		sbq.lounging[eid].progressBarData.layer = true
	end

	if isOccupantHolderDefault or TF.data.playerSpeciesTF then
		sbq.lounging[eid].progressBarFinishFuncName = "transformPlayer"
	else
		sbq.lounging[eid].progressBarFinishFuncName = "transformPrey"
	end

	sbq.lounging[eid].progressBarType = "transforming"
	if TFType then
		sbq.lounging[eid].progressBarType = TFType.."ing"
	end
end

message.setHandler( "settingsMenuRefresh", function(_,_)
	sbq.predHudOpen = 2
	local refreshList = sbq.refreshList
	sbq.refreshList = nil
	return {
		isNested = sbq.isNested,
		occupants = sbq.occupants,
		occupant = sbq.occupant,
		powerMultiplier = sbq.seats[sbq.driverSeat].controls.powerMultiplier,
		settings = sbq.settings,
		refreshList = refreshList,
		locked = sbq.transitionLock
	}
end)

message.setHandler( "despawn", function(_,_, eaten)
	sbq.onDeath(eaten)
end )

message.setHandler( "reversion", function(_,_)
	sbq.reversion()
end)

function sbq.reversion()
	if sbq.occupants.total > 0 then
		sbq.addRPC(world.sendEntityMessage( sbq.driver, "sbqLoadSettings", "sbqOccupantHolder" ), function (settings)
			world.spawnVehicle( "sbqOccupantHolder", mcontroller.position(), { driver = sbq.driver, settings = settings, retrievePrey = entity.id(), direction = sbq.direction } )
		end)
	else
		sbq.onDeath()
	end
end

sbq.entityDigestedAt = {}
message.setHandler( "sbqDigest", function(_,_, eid)
	if type(eid) == "number" and sbq.lounging[eid] ~= nil and not sbq.lounging[eid].digested then
		local location = sbq.lounging[eid].location
		local success, timing = sbq.doTransition("digest"..location)
		sbq.entityDigestedAt[eid] = location

		sbq.lounging[eid].sizeMultiplier = 0
		sbq.lounging[eid].visible = false
		sbq.lounging[eid].location = "digesting"
		sbq.lounging[eid].digested = true

		if type(sbq.lounging[eid].smolPreyData.id) == "number" and world.entityExists(sbq.lounging[eid].smolPreyData.id) then
			world.sendEntityMessage(sbq.lounging[eid].smolPreyData.id, "giveDigestPrey", eid)
		end

		if success and type(timing) == "number" then
			world.sendEntityMessage(eid, "sbqDigestResponse", timing)
		else
			world.sendEntityMessage(eid, "sbqDigestResponse")
		end
	else
		sbq.lounging[eid].sizeMultiplier = 0
		sbq.lounging[eid].visible = false
		sbq.lounging[eid].location = "digesting"
		sbq.lounging[eid].digested = true
	end
end )

message.setHandler("sbqCumDigest", function(_, _, eid)
	if eid ~= nil and type(sbq.lounging[eid]) == "table" then
		sbq.lounging[eid].cumDigesting = true
	end
end)

message.setHandler( "sbqSoftDigest", function(_,_, eid)
	if type(eid) == "number" and sbq.lounging[eid] ~= nil and not sbq.lounging[eid].digested then
		local location = sbq.lounging[eid].location
		local success, timing = sbq.doTransition("digest"..location)
		sbq.entityDigestedAt[eid] = location

		sbq.lounging[eid].sizeMultiplier = 0
		sbq.lounging[eid].digested = true
		sbq.lounging[eid].visible = false

		if type(sbq.lounging[eid].smolPreyData.id) == "number" and world.entityExists(sbq.lounging[eid].smolPreyData.id) then
			world.sendEntityMessage(sbq.lounging[eid].smolPreyData.id, "giveDigestPrey", entity.id())
		end

		if success and type(timing) == "number" then
			world.sendEntityMessage(eid, "sbqDigestResponse", timing)
		else
			world.sendEntityMessage(eid, "sbqDigestResponse")
		end
	else
		sbq.lounging[eid].sizeMultiplier = 0
		sbq.lounging[eid].digested = true
		sbq.lounging[eid].visible = false
	end
end )

message.setHandler( "uneat", function(_,_, eid)
	sbq.uneat( eid )
end )

message.setHandler( "sbqSmolPreyData", function(_,_, seatindex, data, id)
	sbq.occupant[seatindex].smolPreyData = data
	sbq.occupant[seatindex].smolPreyData.id = id
end )

message.setHandler( "indicatorClosed", function(_,_, eid)
	if sbq.lounging[eid] ~= nil then
		sbq.lounging[eid].indicatorCooldown = 2
	end
end )

message.setHandler( "fixWeirdSeatBehavior", function(_,_, eid)
	if sbq.lounging[eid] == nil then return end
	for i = 0, sbq.occupantSlots do
		local seatname = "occupant"..i
		if eid == vehicle.entityLoungingIn("occupant"..i) then
			vehicle.setLoungeEnabled(seatname, false)
		end
	end
	sbq.weirdFixFrame = true
end )

message.setHandler( "addPrey", function (_,_, data)
	table.insert(sbq.addPreyQueue, data)
end)

message.setHandler( "addDigestPrey", function (_,_, data, owner)
	data.location = sbq.entityDigestedAt[owner] or "belly"
	table.insert(sbq.addPreyQueue, data)
end)

message.setHandler( "requestEat", function (_,_, prey, voreType, location)
	sbq.addRPC(world.sendEntityMessage(prey, "sbqIsPreyEnabled", voreType), function(enabled)
		if enabled and enabled.enabled then
			sbq.eat(prey, location, enabled.size or 1)
		end
	end)
end)

message.setHandler( "requestUneat", function (_,_, prey, voreType)
	sbq.addRPC(world.sendEntityMessage(prey, "sbqIsPreyEnabled", voreType), function(enabled)
		if enabled and enabled.enabled then
			sbq.uneat(prey)
		end
	end)
end)

message.setHandler( "getOccupancyData", function ()
	return {occupant = sbq.occupant, occupants = sbq.occupants, actualOccupants = sbq.actualOccupants}
end)

message.setHandler( "requestTransition", function (_,_, transition, args)
	sbq.doTransition( transition, args )
end)

message.setHandler( "getObjectSettingsMenuData", function (_,_)
	if not sbq.driver then
		return {
			settings = sbq.settings,
			spawner = sbq.spawner
		}
	end
end)

message.setHandler( "sbqSendAllPreyTo", function (_,_, id)
	sbq.sendAllPreyTo = id
end)

message.setHandler( "giveDigestPrey", function (_,_, id)
	sbq.sendAllPreyTo = id
	sbq.digestSendPrey = true
end)


message.setHandler("sbqDigestDrop", function(_,_, itemDrop)
	local itemDrop = itemDrop
	itemDrop.parameters.predSpecies = sbq.species
	itemDrop.parameters.predDirectives = sbq.settings.directives
	itemDrop.parameters.predColorMap = {
		primary = ((sbq.sbqData.replaceColors or {})[1] or {})[1],
		secondary = ((sbq.sbqData.replaceColors or {})[2] or {})[1]
	}

	world.spawnItem(itemDrop, mcontroller.position())
end)

message.setHandler( "uneaten", function ()
	sbq.isNested = false
	sbq.resetTransformationGroup("globalScale")
end)

message.setHandler("animOverridesLoungeAnim", function ()
	return "lay"
end)
