message.setHandler( "settingsMenuSet", function(_,_, val )
	p.settings = val
	p.setColorReplaceDirectives()
	p.setSkinPartTags()
end )

message.setHandler( "letout", function(_,_, id )
	p.letout(id)
end )

message.setHandler( "transform", function(_,_, data, eid, multiplier )
	if p.lounging[eid].progressBarActive then return end

	if data then
		if data.species == p.lounging[eid].species then return end
	else
		if p.lounging[eid].species == world.entityName( entity.id() ):gsub("^spov","") then return end
	end

	p.lounging[eid].progressBarActive = true
	p.lounging[eid].progressBar = 0
	p.lounging[eid].progressBarData = data
	if data == nil then
		p.lounging[eid].progressBarColor = p.vso.replaceColors[1][p.settings.replaceColors[1] + 1] -- pred body color
	elseif data.barColor ~= nil then
		p.lounging[eid].progressBarColor = data.barColor
	else
		-- p.lounging[eid].progressBarColor = root.assetJson("something about data:vso.replaceColors.0.1")
		-- or maybe define it some other way, I dunno
	end
	p.lounging[eid].progressBarMultiplier = multiplier or 1
	p.lounging[eid].progressBarFinishFuncName = "transformPrey"
end )

message.setHandler( "settingsMenuRefresh", function(_,_)
	p.settingsMenuOpen = 0.5
	local refreshList = p.refreshList
	p.refreshList = nil
	return {
		occupants = p.occupant,
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
		p.lounging[eid].location = "digesting"
		return {success=success, timing=timing}
	end
end )

message.setHandler( "uneat", function(_,_, eid)
	p.uneat( eid )
end )

message.setHandler( "smolPreyData", function(_,_, seatindex, data, vso)
	world.sendEntityMessage( vso, "despawn", true ) -- no warpout
	p.occupant[seatindex].smolPreyData = data
end )

message.setHandler( "indicatorClosed", function(_,_, eid)
	if p.lounging[eid] ~= nil then
		p.lounging[eid].indicatorCooldown = 2
	end
end )

message.setHandler( "pvsoFixWeirdSeatBehavior", function(_,_, eid)
	if p.lounging[eid] == nil then return end
	vehicle.setLoungeEnabled(p.lounging[eid].seatname, false)
	p.timer(p.lounging[eid].seatname.."Enable", 0.1, function()
		vehicle.setLoungeEnabled(p.lounging[eid].seatname, true)
	end)
end )
