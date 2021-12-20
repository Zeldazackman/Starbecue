message.setHandler( "settingsMenuSet", function(_,_, val )
	p.settings = sb.jsonMerge(p.settings, val)
	p.setColorReplaceDirectives()
	p.setSkinPartTags()
	p.settingsMenuUpdated()
end )

message.setHandler( "letout", function(_,_, id )
	p.letout(id)
end )

message.setHandler( "transform", function(_,_, eid, multiplier, data )
	if p.lounging[eid] == nil or p.lounging[eid].progressBarActive  then return end

	if data then
		if data.species ~= p.lounging[eid].species and data.species ~= nil then
			data = sb.jsonMerge(data, p.getSmolPreyData(data.settings, data.species, data.state))
		else return end
	else
		if p.lounging[eid].species == world.entityName( entity.id() ) then return end
	end

	p.lounging[eid].progressBarActive = true
	p.lounging[eid].progressBar = 0
	p.lounging[eid].progressBarData = data
	if data == nil then
		p.lounging[eid].progressBarColor = (p.settings.replaceColorTable[1] or (p.sbqData.replaceColors[1][(p.settings.replaceColors[1] or p.sbqData.defaultSettings.replaceColors[1] or 1) + 1])) -- pred body color
	elseif data.barColor ~= nil then
		p.lounging[eid].progressBarColor = data.barColor
	else
		-- p.lounging[eid].progressBarColor = root.assetJson("something about data:sbqData.replaceColors.0.1")
		-- or maybe define it some other way, I dunno
	end
	p.lounging[eid].progressBarMultiplier = multiplier or 1
	p.lounging[eid].progressBarFinishFuncName = "transformPrey"
end )

message.setHandler( "settingsMenuRefresh", function(_,_)
	p.predHudOpen = 2
	local refreshList = p.refreshList
	p.refreshList = nil
	return {
		occupants = p.occupants,
		occupant = p.occupant,
		powerMultiplier = p.seats[p.driverSeat].controls.powerMultiplier,
		settings = p.settings,
		refreshList = refreshList,
		locked = p.transitionLock
	}
end)

message.setHandler( "despawn", function(_,_, eaten)
	p.onDeath(eaten)
end )

message.setHandler( "digest", function(_,_, eid)
	if eid ~= nil and p.lounging[eid] ~= nil then
		local location = p.lounging[eid].location
		local success, timing = p.doTransition("digest"..location)
		for i = 0, p.occupantSlots do
			if p.occupant[i].id ~= nil and p.occupant[i].location == "nested" and p.occupant[i].nestedPreyData.owner == eid then
				p.occupant[i].location = location
				p.occupant[i].nestedPreyData = p.occupant[i].nestedPreyData.nestedPreyData
			end
		end
		return {success=success, timing=timing}
	end
end )

message.setHandler( "uneat", function(_,_, eid)
	p.uneat( eid )
end )

message.setHandler( "smolPreyData", function(_,_, seatindex, data, type)
	world.sendEntityMessage( type, "despawn", true ) -- no warpout
	p.occupant[seatindex].smolPreyData = data
end )

message.setHandler( "indicatorClosed", function(_,_, eid)
	if p.lounging[eid] ~= nil then
		p.lounging[eid].indicatorCooldown = 2
	end
end )

message.setHandler( "fixWeirdSeatBehavior", function(_,_, eid)
	if p.lounging[eid] == nil then return end
	for i = 0, p.occupantSlots do
		local seatname = "occupant"..i
		if eid == vehicle.entityLoungingIn("occupant"..i) then
			vehicle.setLoungeEnabled(seatname, false)
		end
	end
	p.weirdFixFrame = true
end )

message.setHandler( "addPrey", function (_,_, seatindex, data)
	p.occupant[seatindex] = data
end)

message.setHandler( "requestEat", function (_,_, prey, voreType, location)
	p.addRPC(world.sendEntityMessage(prey, "sbqIsPreyEnabled", voreType), function(enabled)
		if enabled then
			p.eat(prey, location)
		end
	end)
end)

message.setHandler( "requestUneat", function (_,_, prey, voreType)
	p.addRPC(world.sendEntityMessage(prey, "sbqIsPreyEnabled", voreType), function(enabled)
		if enabled then
			p.uneat(prey)
		end
	end)
end)

message.setHandler( "getOccupancyData", function ()
	return {occupant = p.occupant, occupants = p.occupants}
end)
