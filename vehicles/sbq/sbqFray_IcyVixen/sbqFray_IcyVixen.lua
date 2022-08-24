
require("/vehicles/sbq/sbq_main.lua")
require("/scripts/vec2.lua")

state = {
	stand = {},
}

function sbq.init()
	checkPartsEnabled()
end

function sbq.settingsMenuUpdated()
	checkPartsEnabled()
end

function sbq.update(dt)
	eyeTracking()
end

function sbq.letout(id)
	local id = id or sbq.getRecentPrey()
	if not id then return false end

	local location = sbq.lounging[id].location

	if location == "belly" then
		if sbq.heldControl(sbq.driverSeat, "down") then
			return sbq.doTransition("analEscape", {id = id})
		else
			return sbq.doTransition("oralEscape", {id = id})
		end
	elseif location == "shaft" then
		return sbq.doTransition("cockEscape", {id = id})

	elseif location == "ballsL" or location == "ballsR" then
		return sbq.ballsToShaft({id = id})
	end
end

-------------------------------------------------------------------------------

function getVisibleEntity(entities)
	for _, id in ipairs(entities) do
		if entity.entityInSight(id) then
			return id
		end
	end
end

function eyeTracking()
	local X = 0
	local Y = 0
	local target
	local center = { 2.5, 0.5 }
	if sbq.driving then
		target = sbq.globalToLocal(sbq.seats[sbq.driverSeat].controls.aim)
	else
		local entity = getVisibleEntity(world.playerQuery(center, 50))
		if not entity then
			entity = getVisibleEntity(world.npcQuery(center, 50 ))
		end
		if entity then
			target = sbq.globalToLocal(world.entityPosition(entity))
		end
	end

	if target ~= nil then
		local angle = math.atan((target[2] - center[2]), (target[1] - center[1])) * 180/math.pi

		if angle <= 15 and angle >= -15 then
			X = 1
			Y = 0
		elseif angle <= 75 and angle > 15 then
			X = 1
			Y = 1
		elseif angle <= 105 and angle > 75 then
			X = 0
			Y = 1
		elseif angle <= 165 and angle > 105 then
			X = -1
			Y = 1
		elseif angle > 165 then
			X = -1
			Y = 0

		elseif angle >= -75 and angle < -15 then
			X = 1
			Y = -1
		elseif angle >= -105 and angle < -75 then
			X = 0
			Y = -1
		elseif angle >= -165 and angle < -105 then
			X = -1
			Y = -1
		elseif angle < -165 then
			X = -1
			Y = 0
		end

		if math.abs(target[1]-center[1]) > 10 then
			X = X * 2
		end
	end
	animator.setGlobalTag("eyesX", X)
	animator.setGlobalTag("eyesY", Y)
end

function checkPartsEnabled()
	local defaultSbqData = config.getParameter("sbqData")
	if sbq.settings.penis then
		sbq.setPartTag("global", "cockVisible", "")
		sbq.sbqData.locations.shaft.max = defaultSbqData.locations.shaft.max
	else
		sbq.setPartTag("global", "cockVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.shaft.max = 0
	end
	if sbq.settings.balls then
		sbq.setPartTag("global", "ballsVisible", "")
		sbq.sbqData.locations.ballsL.max = defaultSbqData.locations.balls.max
		sbq.sbqData.locations.ballsR.max = defaultSbqData.locations.balls.max
	else
		sbq.setPartTag("global", "ballsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.ballsL.max = 0
		sbq.sbqData.locations.ballsR.max = 0
	end
	sbq.sbqData.locations.balls.symmetrical = sbq.settings.symmetricalBalls
end

-------------------------------------------------------------------------------

function oralVore(args, tconfig)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function checkOralVore()
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.oralVore.position ), 5, "belly", "oralVore")
end

function oralEscape(args, tconfig)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end

-------------------------------------------------------------------------------

function cockVore(args, tconfig)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "shaft", {}, "swallow", tconfig.voreType)
end

function checkCockVore()
	if sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.cockVore.position ), 5, "shaft", "cockVore") then return true
	else
		sbq.shaftToBalls({id = sbq.findFirstOccupantIdForLocation("shaft")})
	end
end

function cockEscape(args, tconfig)
	return sbq.doEscape(args, {glueslow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {}, tconfig.voreType )
end

-------------------------------------------------------------------------------

function analVore(args, tconfig)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "belly", {}, "swallow", tconfig.voreType)
end

function checkAnalVore()
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.analVore.position ), 4, "belly", "analVore")
end

function analEscape(args, tconfig)
	return sbq.doEscape(args, {}, {}, tconfig.voreType )
end

-------------------------------------------------------------------------------


-------------------------------------------------------------------------------

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
	if checkAnalVore() then return true end
end

-------------------------------------------------------------------------------

state.stand.oralVore = oralVore
state.stand.cockVore = cockVore
state.stand.analVore = analVore

state.stand.checkVore = checkVore
state.stand.checkOralVore = checkOralVore
state.stand.checkCockVore = checkCockVore
state.stand.checkAnalVore = checkAnalVore

state.stand.oralEscape = oralEscape
state.stand.cockEscape = cockEscape
state.stand.analEscape = analEscape

state.stand.shaftToBalls = sbq.shaftToBalls
state.stand.ballsToShaft = sbq.ballsToShaft
state.stand.switchBalls = sbq.switchBalls

-------------------------------------------------------------------------------
