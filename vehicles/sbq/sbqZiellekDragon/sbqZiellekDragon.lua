--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
}

function sbq.init()
	getColors()
	checkPartsEnabled()
end

function sbq.settingsMenuUpdated()
	checkPartsEnabled()
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
		--	return p.doTransition("analEscape", {id = id})
		--else
			return sbq.doTransition("oralEscape", {id = id})
		--end
	elseif location == "shaft" then
		return sbq.doTransition("cockEscape", {id = id})

	elseif location == "ballsL" or location == "ballsR" then
		return ballsToShaft({id = id})
	end
end

-------------------------------------------------------------------------------

function getColors()
	if not sbq.settings.firstLoadDone then
		-- get random directives for anyone thats not an avian
		for i = 1, #sbq.sbqData.replaceColors do
			sbq.settings.replaceColors[i] = math.random( #sbq.sbqData.replaceColors[i] - 1 )
		end
		for skin, data in pairs(sbq.sbqData.replaceSkin) do
			local result = data.skins[math.random(#data.skins)]
			for i, partname in ipairs(data.parts) do
				sbq.settings.skinNames[partname] = result
			end
		end

		sbq.settings.firstLoadDone = true
		sbq.setColorReplaceDirectives()
		sbq.setSkinPartTags()
		world.sendEntityMessage(sbq.spawner, "sbqSaveSettings", sbq.settings, "sbqZiellekDragon")
	end
end

function checkPartsEnabled()
	local defaultSbqData = config.getParameter("sbqData")
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
	sbq.sbqData.locations.balls.symmetrical = sbq.settings.symmetricalBalls
end

function shaftToBalls(args)
	if math.random() > 0.5 then
		if sbq.moveOccupantLocation(args, "ballsL") then return true end
		if sbq.moveOccupantLocation(args, "ballsR") then return true end
	else
		if sbq.moveOccupantLocation(args, "ballsR") then return true end
		if sbq.moveOccupantLocation(args, "ballsL") then return true end
	end
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


function oralVore(args)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "belly", {}, "swallow")
end

function checkOralVore()
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.oralVore.position ), 5, "belly", "oralVore")
end

function cockVore(args)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "shaft", {}, "swallow")
end

function checkCockVore()
	if sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.cockVore.position ), 5, "shaft", "cockVore") then return true
	else
		local shaftOccupant = sbq.findFirstOccupantIdForLocation("shaft")
		if shaftOccupant then
			shaftToBalls({id = shaftOccupant})
		end
	end
end


function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
end

function oralEscape(args)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function cockEscape(args)
	return sbq.doEscape(args, {glueslow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {} )
end

-------------------------------------------------------------------------------

state.stand.oralVore = oralVore
state.stand.cockVore = cockVore

state.stand.checkVore = checkVore
state.stand.checkOralVore = checkOralVore
state.stand.checkCockVore = checkCockVore

state.stand.oralEscape = oralEscape
state.stand.cockEscape = cockEscape

-------------------------------------------------------------------------------
