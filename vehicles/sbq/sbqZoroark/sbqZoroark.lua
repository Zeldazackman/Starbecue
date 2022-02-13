--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
	smol = {}
}
-------------------------------------------------------------------------------

function sbq.init()
	getColors()
	checkPartsEnabled()
end

function sbq.update(dt)
	sbq.changeSize()
	sbq.armRotationUpdate()
	sbq.setGrabTarget()
end

function sbq.otherLocationEffects(i, eid, health, bellyEffect, location )
	if (sbq.settings.penisCumTF and location == "shaft" and (sbq.occupant[i].progressBar <= 0))
	or (sbq.settings.ballsCumTF and ( location == "balls" or location == "ballsR" or location == "ballsL" ) and (sbq.occupant[i].progressBar <= 0))
	then
		sbq.loopedMessage("CumTF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
			if not immune then
				transformMessageHandler( eid , 3, sbq.config.victimTransformPresets.cumBlob )
			end
		end)
	end
end

function sbq.changeSize()
	if sbq.tapControl( sbq.driverSeat, "special1" ) and sbq.totalTimeAlive > 0.5 and not sbq.transitionLock then
		local changeSize = "smol"
		if sbq.state == changeSize then
			changeSize = "stand"
		end
		sbq.warpInEffect() --Play warp in effect
		sbq.setState( changeSize )
	end
end

function sbq.settingsMenuUpdated()
	checkPartsEnabled()
end

function getColors()
	if not sbq.settings.firstLoadDone then
		sb.logInfo("rolling for shiny...")
		sbq.settings.shinyRoll = math.random(1, 4096)
		local presetName = ""

		if math.random() > 0.5 then
			presetName = "unovan"
		else
			presetName = "hisuian"
		end
		if sbq.settings.shinyRoll == 1 then
			sbq.settings.shiny = true
			presetName = presetName.."Shiny"
			sb.logInfo("woah a shiny pokemon!")
		else
			sb.logInfo("meh... not a shiny...")
		end

		sbq.settings = sb.jsonMerge(sbq.settings, sbq.sbqData.customizePresets[presetName])

		local waist = "default"
		local gender = world.entityGender(sbq.spawner)
		if (gender == "female") or ( (gender == nil) and (math.random() > 0.5) ) then
			sbq.settings.breasts = true
			waist = "thin_waist"
		end
		for i, partname in ipairs(sbq.sbqData.replaceSkin.body.parts) do
			sbq.settings.skinNames[partname] = waist
		end

		sbq.settings.firstLoadDone = true
		sbq.setColorReplaceDirectives()
		sbq.setSkinPartTags()
		world.sendEntityMessage(sbq.spawner, "sbqSaveSettings", sbq.settings, "sbqZoroark")
	end
end

function checkPartsEnabled()
	local defaultSbqData = config.getParameter("sbqData")
	if sbq.settings.tail then
		sbq.setPartTag("global", "tailVisible", "")
		if sbq.settings.tailMaw then
			sbq.sbqData.locations.tail.max = defaultSbqData.locations.tail.max
		else
			sbq.sbqData.locations.tail.max = 0
		end
	else
		sbq.setPartTag("global", "tailVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.tail.max = 0
		sbq.removeOccupantsFromLocation("tail")
	end
	if sbq.settings.penis then
		sbq.setPartTag("global", "cockVisible", "")
		sbq.sbqData.locations.shaft.max = defaultSbqData.locations.shaft.max
	else
		sbq.setPartTag("global", "cockVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.shaft.max = 0
		sbq.removeOccupantsFromLocation("shaft")
	end
	if sbq.settings.balls then
		sbq.setPartTag("global", "ballsVisible", "")
		sbq.sbqData.locations.ballsL.max = defaultSbqData.locations.balls.max
		sbq.sbqData.locations.ballsR.max = defaultSbqData.locations.balls.max
	else
		sbq.setPartTag("global", "ballsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.ballsL.max = 0
		sbq.sbqData.locations.ballsR.max = 0
		sbq.removeOccupantsFromLocation("ballsL")
		sbq.removeOccupantsFromLocation("ballsR")
	end
end

function sbq.letout(id)
	local id = id
	if id == nil then
		id = sbq.occupant[sbq.occupants.total].id
	end
	if not id then return end
	local location = sbq.lounging[id].location

	if location == "belly" then
		--if p.heldControl(p.driverSeat, "down") or p.lounging[id].species == "sbqEgg" then
		--	return p.doTransition("analEscale", {id = id})
		--else
			return sbq.doTransition("oralEscape", {id = id})
		--end
	elseif location == "hug" then
		sbq.grabbing = nil
		return sbq.uneat(id)
	elseif location == "shaft" then
		return sbq.doTransition("cockEscape", {id = id})
	end
end

function grab()
	sbq.grab("hug")
end

function cockVore(args)
	return sbq.doVore(args, "shaft", {}, "swallow")
end

function cockEscape(args)
	return sbq.doEscape(args, {glueslow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {} )
end

function oralVore(args)
	sbq.grabbing = args.id
	return sbq.doVore(args, "belly", {}, "swallow")
end

function oralEscape(args)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
end

function checkOralVore()
	return sbq.checkEatPosition(sbq.localToGlobal( {0, 0} ), 5, "belly", "oralVore")
end

function checkCockVore()
	return sbq.checkEatPosition(sbq.localToGlobal( {0, -3} ), 4, "shaft", "cockVore")
end

function shaftToBalls(args)
	local side = "L"
	if math.random() > 0.5 then
		side = "R"
	end
	return sbq.moveOccupantLocation(args, "balls"..side)
end

function ballsToShaft(args)
	sbq.moveOccupantLocation(args, "shaft")
end

function switchBalls(args)
	local dx = sbq.lounging[args.id].controls.dx
	if dx == -1 then
		return sbq.moveOccupantLocation(args, "ballsR")
	elseif dx == 1 then
		return sbq.moveOccupantLocation(args, "ballsL")
	end
end

-------------------------------------------------------------------------------
function state.stand.begin()
	sbq.setMovementParams( "default" )
	sbq.resolvePosition(5)
end

state.stand.oralVore = oralVore
state.stand.cockVore = cockVore
state.stand.oralEscape = oralEscape
state.stand.cockEscape = cockEscape

state.stand.checkCockVore = checkCockVore
state.stand.checkOralVore = checkOralVore

state.stand.shaftToBalls = shaftToBalls
state.stand.ballsToShaft = ballsToShaft
state.stand.switchBalls = switchBalls

state.stand.grab = grab

-------------------------------------------------------------------------------

function state.smol.begin()
	sbq.setMovementParams( "smol" )
	sbq.letGrabGo("hug")
	sbq.resolvePosition(3)
end

-------------------------------------------------------------------------------
