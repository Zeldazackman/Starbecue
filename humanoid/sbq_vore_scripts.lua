
function sbq.update(dt)
	sbq.detectShirt()
	sbq.detectPants()
end

function state.stand.oralVore(args, tconfig)
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.stand.oralEscape(args, tconfig)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end

function state.stand.analVore(args, tconfig)
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.stand.analEscape(args, tconfig)
	return sbq.doEscape(args, {}, {}, tconfig.voreType )
end

function state.stand.unbirth(args, tconfig)
	return sbq.doVore(args, "womb", {}, "swallow", tconfig.voreType)
end

function state.stand.unbirthEscape(args, tconfig)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end

function state.stand.cockVore(args, tconfig)
	if not args.id then
		sbq.shaftToBalls({id = sbq.findFirstOccupantIdForLocation("shaft")})
		return false
	end
	return sbq.doVore(args, "shaft", {}, "swallow", tconfig.voreType)
end

state.stand.ballsToShaft = sbq.ballsToShaft
state.stand.shaftToBalls = sbq.shaftToBalls
state.stand.switchBalls = sbq.switchBalls

function state.stand.cockEscape(args, tconfig)
	return sbq.doEscape(args, {glueslow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {}, tconfig.voreType )
end

function state.stand.breastVore(args, tconfig)
	return sbq.doVore(args, "breasts", {}, "swallow", tconfig.voreType)
end

function state.stand.breastEscape(args, tconfig)
	return sbq.doEscape(args, {}, {}, tconfig.voreType )
end

function state.stand.navelVore(args, tconfig)
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function state.stand.navelEscape(args, tconfig)
	return sbq.doEscape(args, {}, {}, tconfig.voreType )
end

function sbq.detectShirt()
	if (sbq.sbqData.overrideSettings or {}).shirt == false then return false end
	if sbq.settings.bra then return true end
	local shirt = sbq.seats[sbq.driverSeat].controls.chestCosmetic or sbq.seats[sbq.driverSeat].controls.chest or {}
	local result = not sbq.config.chestVoreWhitelist[shirt.name or "none"]
	sbq.settings.shirt = result
end

function sbq.detectPants()
	if (sbq.sbqData.overrideSettings or {}).pants == false then return false end
	if sbq.settings.underwear then return true end
	local pants = sbq.seats[sbq.driverSeat].controls.legsCosmetic or sbq.seats[sbq.driverSeat].controls.legs or {}
	local result = not sbq.config.legsVoreWhitelist[pants.name or "none"]
	sbq.settings.pants = result
end

function sbq.letout(id)
	local id = id or sbq.getRecentPrey()
	if not id then return false end

	local location = sbq.lounging[id].location

	if location == "belly" then
		if (sbq.seats[sbq.driverSeat].controls.primaryHandItem == "sbqController") and sbq.seats[sbq.driverSeat].controls.primaryHandItemDescriptor.parameters.scriptStorage.clickAction == "analVore" then
			return sbq.doTransition("analEscape", {id = id})
		elseif (sbq.seats[sbq.driverSeat].controls.primaryHandItem == "sbqController") and sbq.seats[sbq.driverSeat].controls.primaryHandItemDescriptor.parameters.scriptStorage.clickAction == "navelVore" then
			return sbq.doTransition("navelEscape", {id = id})
		else
			return sbq.doTransition("oralEscape", {id = id})
		end
	elseif location == "tail" then
		return sbq.doTransition("tailEscape", {id = id})
	elseif location == "shaft" then
		return sbq.doTransition("cockEscape", {id = id})
	elseif location == "ballsL" or location == "ballsR" then
		return sbq.ballsToShaft({id = id})
	elseif location == "breastsL" or location == "breastsR" then
		return sbq.doTransition("breastEscape", {id = id})
	elseif location == "womb" then
		return sbq.doTransition("unbirthEscape", {id = id})
	end
end

function sbq.settingsMenuUpdated()
	local defaultSbqData = sbq.defaultSbqData
	if sbq.settings.penis then
		if sbq.settings.underwear then
			sbq.setStatusValue( "cockVisible", "?crop;0;0;0;0")
		else
			sbq.setStatusValue( "cockVisible", "")
		end
		sbq.sbqData.locations.shaft.max = defaultSbqData.locations.shaft.max
	else
		sbq.setStatusValue( "cockVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.shaft.max = 0
	end
	if sbq.settings.balls then
		if sbq.settings.underwear then
			sbq.setStatusValue( "ballsVisible", "?crop;0;0;0;0")
		else
			sbq.setStatusValue( "ballsVisible", "")
		end
		sbq.sbqData.locations.ballsL.max = defaultSbqData.locations.balls.max
		sbq.sbqData.locations.ballsR.max = defaultSbqData.locations.balls.max
	else
		sbq.setStatusValue( "ballsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.ballsL.max = 0
		sbq.sbqData.locations.ballsR.max = 0
	end
	sbq.sbqData.locations.balls.symmetrical = sbq.settings.symmetricalBalls
	if sbq.settings.breasts then
		sbq.setStatusValue( "breastsVisible", "")
		sbq.sbqData.locations.breastsL.max = defaultSbqData.locations.balls.max
		sbq.sbqData.locations.breastsR.max = defaultSbqData.locations.balls.max
	else
		sbq.setStatusValue( "breastsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.breastsL.max = 0
		sbq.sbqData.locations.breastsR.max = 0
	end
	world.sendEntityMessage(sbq.driver, "setBoobMask", sbq.settings.breasts)

	sbq.sbqData.locations.breasts.symmetrical = sbq.settings.symmetricalBreasts

	if sbq.settings.pussy then
		sbq.setStatusValue( "pussyVisible", "")
	else
		sbq.setStatusValue( "pussyVisible", "?crop;0;0;0;0")
	end
	sbq.handleUnderwear()
end

function sbq.handleUnderwear()
	world.sendEntityMessage(sbq.driver, "sbqEnableUnderwear", sbq.settings.underwear)
	world.sendEntityMessage(sbq.driver, "sbqEnableBra", sbq.settings.bra)
end
