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
				color = color.."fb"
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
				color = color.."fb"
			end
			colorReplaceString = colorReplaceString.."?replace;"..(basePalette[j] or "").."="..(color or "")

		end
	end

	sbq.itemActionDirectives = colorReplaceString
end

function sbq.letout(id)
	local id = id
	if id == nil then
		id = sbq.occupant[sbq.occupants.total].id
	end
	if not id then return end
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
		return ballsToShaft({id = id})
	elseif location == "womb" then
		return sbq.doTransition("unbirthEscape", {id = id})
	end
end

function sbq.otherLocationEffects(i, eid, health, bellyEffect, location, powerMultiplier )
	if location == "womb" then
		local bellyEffect = "sbqHeal"
		if sbq.settings.displayDigest then
			if sbq.config.bellyDisplayStatusEffects[bellyEffect] ~= nil then
				bellyEffect = sbq.config.bellyDisplayStatusEffects[bellyEffect]
			end
		end
		world.sendEntityMessage( eid, "applyStatusEffect", bellyEffect, powerMultiplier, entity.id())
	end

	if (sbq.occupant[i].progressBar <= 0) then
		if (sbq.settings.penisCumTF and location == "shaft") or (sbq.settings.ballsCumTF and ( location == "balls" or location == "ballsR" or location == "ballsL" )) then
			sbq.loopedMessage("CumTF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
				if not immune then
					transformMessageHandler( eid , 3, sbq.config.victimTransformPresets.cumBlob )
				end
			end)
		elseif sbq.settings.wombEggify and location == "womb" then
			sbq.loopedMessage("Eggify"..eid, eid, "sbqIsPreyEnabled", {"eggImmunity"}, function (immune)
				if not immune then
					local eggData = root.assetJson("/vehicles/sbq/sbqEgg/sbqEgg.vehicle")
					local replaceColors = {
					math.random(1, #eggData.sbqData.replaceColors[1] - 1),
					math.random(1, #eggData.sbqData.replaceColors[2] - 1)
					}
					transformMessageHandler( eid, 3, {
						barColor = eggData.sbqData.replaceColors[2][replaceColors[2]+1],
						forceSettings = true,
						layer = true,
						state = "smol",
						species = "sbqEgg",
						layerLocation = "egg",
						settings = {
							cracks = 0,
							bellyEffect = "sbqHeal",
							escapeDifficulty = sbq.settings.escapeDifficulty,
							replaceColors = replaceColors
						}
					})
				end
			end)
		end
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

-------------------------------------------------------------------------------

function oralVore(args)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "belly", {}, "swallow")
end

function checkOralVore()
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.oralVore.position ), 5, "belly", "oralVore")
end

function oralEscape(args)
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

-------------------------------------------------------------------------------

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

function cockEscape(args)
	return sbq.doEscape(args, {glueslow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {} )
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

-------------------------------------------------------------------------------

function analVore(args)
	if not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "belly", {}, "swallow")
end

function checkAnalVore()
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.analVore.position ), 4, "belly", "analVore")
end

function analEscape(args)
	return sbq.doEscape(args, {}, {} )
end

-------------------------------------------------------------------------------

function unbirth(args)
	if not sbq.settings.pussy or not mcontroller.onGround() or sbq.movement.falling then return false end
	return sbq.doVore(args, "womb", {}, "swallow")
end

function checkUnbirth()
	if not sbq.settings.pussy then return false end
	return sbq.checkEatPosition(sbq.localToGlobal( sbq.stateconfig[sbq.state].actions.unbirth.position ), 4, "womb", "unbirth")
end

function unbirthEscape(args)
	if not sbq.settings.pussy then return false end
	return sbq.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
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

state.stand.shaftToBalls = shaftToBalls
state.stand.ballsToShaft = ballsToShaft
state.stand.switchBalls = switchBalls

-------------------------------------------------------------------------------
