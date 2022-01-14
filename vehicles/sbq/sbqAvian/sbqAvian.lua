--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	stand = {},
	smol = {}
}
-------------------------------------------------------------------------------

function p.init()
	getColors()
	checkPartsEnabled()
end

function p.update(dt)
	p.changeSize()
	p.armRotationUpdate()
	p.setGrabTarget()
end
local cumBlob = {
	barColor = {"A1A1A1", "DCDCDC", "EFEFEF", "FFFFFF"},
	forceSettings = true,
	state = "smol",
	species = "sbqSlime",
	settings = {
		firstLoadDone = true,
		bellyEffect = "sbqRemoveBellyEffects",
		replaceColors = {8},
		skinNames = {},
		directives = "?replace;A1A1A1=A1A1A1Bc;DCDCDC=DCDCDCBc;EFEFEF=EFEFEFBc;FFFFFF=FFFFFFBc"
	}
}

function p.otherLocationEffects(i, eid, health, bellyEffect, location )
	if (p.settings.penisCumTF and location == "shaft" and (p.occupant[i].progressBar <= 0))
	or (p.settings.ballsCumTF and ( location == "balls" or location == "ballsR" or location == "ballsL" ) and (p.occupant[i].progressBar <= 0))
	then
		transformMessageHandler( eid , 3, cumBlob )
	end
end

function p.changeSize()
	if p.tapControl( p.driverSeat, "special1" ) and p.totalTimeAlive > 0.5 and not p.transitionLock then
		local changeSize = "smol"
		if p.state == changeSize then
			changeSize = "stand"
		end
		p.warpInEffect() --Play warp in effect
		p.setState( changeSize )
	end
end

function p.settingsMenuUpdated()
	checkPartsEnabled()
end

function getColors()
	if not p.settings.firstLoadDone then
		if world.entitySpecies(p.spawner) == "avian" then
			-- get the directives for color here if you are an avian
			local portrait = world.entityPortrait(p.spawner, "full")
			for _, part in ipairs(portrait) do
				local imageString = part.image
				-- check for doing an emote animation
				local found1, found2 = imageString:find("/emote.png:")
				if found1 ~= nil then
					local found3, found4 = imageString:find(".1", found2, found2+10 )
					if found3 ~= nil then
						local directives = imageString:sub(found4+1)
						p.settings.directives = directives
						p.settings.replaceColorTable[1] = directives
					end
				end
				--get personality values
				found1, found2 = imageString:find("body.png:idle.")
				if found1 ~= nil then
					p.setPartTag( "global", "bodyPersonality", imageString:sub(found2+1, found2+1) )
				end
				found1, found2 = imageString:find("backarm.png:idle.")
				if found1 ~= nil then
					p.setPartTag( "global", "backarmPersonality", imageString:sub(found2+1, found2+1) )
				end
				found1, found2 = imageString:find("frontarm.png:idle.")
				if found1 ~= nil then
					p.setPartTag( "global", "frontarmPersonality", imageString:sub(found2+1, found2+1) )
				end

				getPlayerInitialCustomize( imageString, "fluff/", "fluff" )
				getPlayerInitialCustomize( imageString, "beaks/", "beak" )
				getPlayerInitialCustomize( imageString, "hair/", "hair" )
			end
		else
			-- get random directives for anyone thats not an avian
			for i = 1, #p.sbqData.replaceColors do
				p.settings.replaceColors[i] = math.random( #p.sbqData.replaceColors[i] - 1 )
			end
			for skin, data in pairs(p.sbqData.replaceSkin) do
				local result = data.skins[math.random(#data.skins)]
				for i, partname in ipairs(data.parts) do
					p.settings.skinNames[partname] = result
				end
			end
		end

		local waist = "default"
		local gender = world.entityGender(p.spawner)
		if (gender == "female") or ( (gender == nil) and (math.random() > 0.5) ) then
			p.settings.breasts = true
			waist = "thin_waist"
		end

		for i, partname in ipairs(p.sbqData.replaceSkin.body.parts) do
			p.settings.skinNames[partname] = waist
		end

		p.settings.firstLoadDone = true
		p.setColorReplaceDirectives()
		p.setSkinPartTags()
		world.sendEntityMessage(p.spawner, "sbqSaveSettings", p.settings, "sbqAvian")
	end
end

function getPlayerInitialCustomize( imageString, name, skin )
	found1, found2 = imageString:find(name)
	if found1 ~= nil then
		local result = imageString:sub(found2+1, found2+2)

		if result:sub(-1) == "." then
			result = result:sub(1,1)
		end

		if result == "1" then
			result = "default"
		end

		for i, partname in ipairs(p.sbqData.replaceSkin[skin].parts) do
			p.settings.skinNames[partname] = result
		end
	end
end

function checkPartsEnabled()
	local defaultSbqData = config.getParameter("sbqData")
	if p.settings.penis then
		p.setPartTag("global", "cockVisible", "")
		p.sbqData.locations.shaft.max = defaultSbqData.locations.shaft.max
	else
		p.setPartTag("global", "cockVisible", "?crop;0;0;0;0")
		p.sbqData.locations.shaft.max = 0
		p.removeOccupantsFromLocation("shaft")
	end
	if p.settings.balls then
		p.setPartTag("global", "ballsVisible", "")
		p.sbqData.locations.ballsL.max = defaultSbqData.locations.balls.max
		p.sbqData.locations.ballsR.max = defaultSbqData.locations.balls.max
	else
		p.setPartTag("global", "ballsVisible", "?crop;0;0;0;0")
		p.sbqData.locations.ballsL.max = 0
		p.sbqData.locations.ballsR.max = 0
		p.removeOccupantsFromLocation("ballsL")
		p.removeOccupantsFromLocation("ballsR")
	end
	if p.settings.breasts then
		p.setPartTag("global", "breastsVisible", "")
		p.sbqData.locations.breastsL.max = defaultSbqData.locations.breasts.max
		p.sbqData.locations.breastsR.max = defaultSbqData.locations.breasts.max
	else
		p.setPartTag("global", "breastsVisible", "?crop;0;0;0;0")
		p.sbqData.locations.breastsL.max = 0
		p.sbqData.locations.breastsR.max = 0
		p.removeOccupantsFromLocation("breastsL")
		p.removeOccupantsFromLocation("breastsR")
	end
end

function p.letout(id)
	local id = id
	if id == nil then
		id = p.occupant[p.occupants.total].id
	end
	if not id then return end
	local location = p.lounging[id].location

	if location == "belly" then
		--if p.heldControl(p.driverSeat, "down") or p.lounging[id].species == "sbqEgg" then
		--	return p.doTransition("analEscale", {id = id})
		--else
			return p.doTransition("oralEscape", {id = id})
		--end
	elseif location == "hug" then
		p.grabbing = nil
		return p.uneat(id)
	elseif location == "shaft" then
		return p.doTransition("cockEscape", {id = id})
	end
end

function grab()
	p.grab("hug")
end

function cockVore(args)
	return p.doVore(args, "shaft", {}, "swallow")
end

function cockEscape(args)
	return p.doEscape(args, {glueslow = { power = 5 + (p.lounging[args.id].progressBar), source = entity.id()}}, {} )
end

function oralVore(args)
	p.grabbing = args.id
	return p.doVore(args, "belly", {}, "swallow")
end

function oralEscape(args)
	return p.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
end

function checkOralVore()
	return p.checkEatPosition(p.localToGlobal( {0, 0} ), 5, "belly", "oralVore")
end

function checkCockVore()
	return p.checkEatPosition(p.localToGlobal( {0, -3} ), 4, "shaft", "cockVore")
end

function shaftToBalls(args)
	local side = "L"
	if math.random() > 0.5 then
		side = "R"
	end
	return p.moveOccupantLocation(args, "balls"..side)
end

function ballsToShaft(args)
	p.moveOccupantLocation(args, "shaft")
end

function switchBalls(args)
	local dx = p.lounging[args.id].controls.dx
	if dx == -1 then
		return p.moveOccupantLocation(args, "ballsR")
	elseif dx == 1 then
		return p.moveOccupantLocation(args, "ballsL")
	end
end

-------------------------------------------------------------------------------
function state.stand.begin()
	p.setMovementParams( "default" )
	p.resolvePosition(5)
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
	p.setMovementParams( "smol" )
	p.letGrabGo("hug")
	p.resolvePosition(3)
end

-------------------------------------------------------------------------------
