
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

function sbq.setItemActionColorReplaceDirectives()
	local colorReplaceString = sbq.sbqData.itemActionDirectives or ""

	if sbq.sbqData.replaceColors ~= nil then
		local i = 1
		local basePalette = { "154247", "23646a", "39979e", "4cc1c9" }
		local replacePalette = sbq.sbqData.replaceColors[i][((sbq.settings.replaceColors or {})[i] or (sbq.sbqData.defaultSettings.replaceColors or {})[i] or 1) + 1]
		local fullbright = (sbq.settings.fullbright or {})[i]

		if sbq.settings.replaceColorTable and sbq.settings.replaceColorTable[i] then
			replacePalette = sbq.settings.replaceColorTable[i]
		end

		for j, color in ipairs(basePalette) do
			color = replacePalette[j]
			if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
				color = color.."fe"
			end
			colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")
		end

		i = 7
		basePalette = { "63263d", "7a334d", "9d4165" }
		replacePalette = sbq.sbqData.replaceColors[i][((sbq.settings.replaceColors or {})[i] or (sbq.sbqData.defaultSettings.replaceColors or {})[i] or 1) + 1]
		fullbright = (sbq.settings.fullbright or {})[i]

		if sbq.settings.replaceColorTable and sbq.settings.replaceColorTable[i] then
			replacePalette = sbq.settings.replaceColorTable[i]
		end

		for j, color in ipairs(basePalette) do
			color = replacePalette[j]
			if fullbright and #color <= #"ffffff" then -- don't tack it on it if it already has a defined opacity or fullbright
				color = color.."fe"
			end
			colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")

		end
	end

	sbq.itemActionDirectives = colorReplaceString
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
	elseif location == "womb" then
		return sbq.doTransition("unbirthEscape", {id = id})
	end
end

-------------------------------------------------------------------------------

function getColors()
	if not sbq.settings.firstLoadDone then
		for i, colors in ipairs(sbq.sbqData.replaceColors or {}) do
			sbq.settings.replaceColors[i] = math.random( #colors - 1 )
		end
		for skin, data in pairs(sbq.sbqData.replaceSkin or {}) do
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

function unbirth(args, tconfig)
	if not sbq.settings.pussy or not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "womb", {}, "swallow", tconfig.voreType)
end

function checkUnbirth()
	if not sbq.settings.pussy then return false end
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.unbirth.position ), 4, "womb", "unbirth")
end

function unbirthEscape(args, tconfig)
	if not sbq.settings.pussy then return false end
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {}, tconfig.voreType )
end

-------------------------------------------------------------------------------

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
	if checkUnbirth() then return true end
	if checkAnalVore() then return true end
end

-------------------------------------------------------------------------------

state.stand.oralVore = oralVore
state.stand.cockVore = cockVore
state.stand.analVore = analVore
state.stand.unbirth = unbirth

state.stand.checkVore = checkVore
state.stand.checkOralVore = checkOralVore
state.stand.checkCockVore = checkCockVore
state.stand.checkAnalVore = checkAnalVore
state.stand.checkUnbirth = checkUnbirth

state.stand.oralEscape = oralEscape
state.stand.cockEscape = cockEscape
state.stand.analEscape = analEscape
state.stand.unbirthEscape = unbirthEscape

state.stand.shaftToBalls = sbq.shaftToBalls
state.stand.ballsToShaft = sbq.ballsToShaft
state.stand.switchBalls = sbq.switchBalls

-------------------------------------------------------------------------------
