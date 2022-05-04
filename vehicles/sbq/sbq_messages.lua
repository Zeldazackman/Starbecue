message.setHandler( "settingsMenuSet", function(_,_, val )
	sbq.settings = sb.jsonMerge(sbq.settings, val)
	sbq.setColorReplaceDirectives()
	sbq.setSkinPartTags()
	sbq.settingsMenuUpdated()
end )

message.setHandler( "letout", function(_,_, id )
	sbq.letout(id)
end )

message.setHandler( "transform", function(_,_, eid, multiplier, data )
	transformMessageHandler(eid, multiplier, data)
end )

function transformMessageHandler(eid, multiplier, data)
	if sbq.lounging[eid] == nil or sbq.lounging[eid].progressBarActive  then return end

	if data then
		if data.species ~= sbq.lounging[eid].species and data.species ~= nil then
			data = sb.jsonMerge(data, sbq.getSmolPreyData(data.settings, data.species, data.state))
		else return end
	else
		if sbq.lounging[eid].species == world.entityName( entity.id() ) then return end
	end

	sbq.lounging[eid].progressBarActive = true
	sbq.lounging[eid].progressBar = 0
	sbq.lounging[eid].progressBarData = data or {}

	if type(sbq.lounging[eid].progressBarData.barColor) == "table" then
		sbq.lounging[eid].progressBarColor = data.barColor
	else
		sbq.lounging[eid].progressBarColor = (sbq.settings.replaceColorTable[1] or (sbq.sbqData.replaceColors[1][(sbq.settings.replaceColors[1] or sbq.sbqData.defaultSettings.replaceColors[1] or 1) + 1])) -- pred body color
		-- p.lounging[eid].progressBarColor = root.assetJson("something about data:sbqData.replaceColors.0.1")
		-- or maybe define it some other way, I dunno
	end

	if sbq.lounging[eid].species == "sbqOccupantHolder" then
		sbq.lounging[eid].progressBarData.layer = true
	end

	sbq.lounging[eid].progressBarMultiplier = multiplier or 3
	sbq.lounging[eid].progressBarFinishFuncName = "transformPrey"
end

message.setHandler( "playerTransform", function(_,_, eid, multiplier, data )
	playerTransformMessageHandler(eid, multiplier, data)
end )

function playerTransformMessageHandler(eid, multiplier, data)
	if sbq.lounging[eid] == nil or sbq.lounging[eid].progressBarActive  then return end

	sbq.lounging[eid].progressBarActive = true
	sbq.lounging[eid].progressBar = 0
	sbq.lounging[eid].progressBarData = data or {}

	sbq.lounging[eid].progressBarMultiplier = multiplier or 3
	sbq.lounging[eid].progressBarFinishFuncName = "transformPlayer"
end
function sbq.transformPlayer(i)
	local id = sbq.occupant[i].id
	local data = sbq.occupant[i].progressBarData
	if type(id) == "number" and world.entityExists(id) then
		world.sendEntityMessage(id, "sbqRemoveStatusEffect", "sbqMysteriousPotionTF")
		world.sendEntityMessage(id, "sbqApplyStatusEffects", {sbqMysteriousPotionTF = { power = 3600, property = { species = data.species or sbq.species }}})
	end
end


message.setHandler( "settingsMenuRefresh", function(_,_)
	sbq.predHudOpen = 2
	local refreshList = sbq.refreshList
	sbq.refreshList = nil
	return {
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

message.setHandler( "digest", function(_,_, eid)
	if type(eid) == "number" and sbq.lounging[eid] ~= nil then
		local location = sbq.lounging[eid].location
		local success, timing = sbq.doTransition("digest"..location)
		for i = 0, sbq.occupantSlots do
			if type(sbq.occupant[i].id) == "number" and sbq.occupant[i].location == "nested" and sbq.occupant[i].nestedPreyData.owner == eid then
				sbq.occupant[i].location = location
				sbq.occupant[i].nestedPreyData = sbq.occupant[i].nestedPreyData.nestedPreyData
			end
		end
		sbq.lounging[eid].location = "digesting"
		return {success=success, timing=timing}
	end
end )

message.setHandler( "uneat", function(_,_, eid)
	sbq.uneat( eid )
end )

message.setHandler( "sbqSmolPreyData", function(_,_, seatindex, data, type)
	world.sendEntityMessage( type, "despawn", true ) -- no warpout
	sbq.occupant[seatindex].smolPreyData = data
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

message.setHandler( "requestEat", function (_,_, prey, voreType, location)
	sbq.addRPC(world.sendEntityMessage(prey, "sbqIsPreyEnabled", voreType), function(enabled)
		if enabled then
			sbq.eat(prey, location)
		end
	end)
end)

message.setHandler( "requestUneat", function (_,_, prey, voreType)
	sbq.addRPC(world.sendEntityMessage(prey, "sbqIsPreyEnabled", voreType), function(enabled)
		if enabled then
			sbq.uneat(prey)
		end
	end)
end)

message.setHandler( "getOccupancyData", function ()
	return {occupant = sbq.occupant, occupants = sbq.occupants}
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
