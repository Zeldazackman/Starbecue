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
end

function p.update(dt)
	p.changeSize()
	p.armRotationUpdate()
	p.setGrabTarget()
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

function getColors()
	if p.settings.firstLoadDone == nil then
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
			end
		else
			-- get random directives for anyone thats not an avian
			for i = 1, #p.sbqData.replaceColors do
				p.settings.replaceColors[i] = math.random( #p.sbqData.replaceColors[i] - 1 )
			end
		end
		p.settings.firstLoadDone = true
		p.setColorReplaceDirectives()
		world.sendEntityMessage(p.spawner, "sbqSaveSettings", p.settings, "sbqAvian")
	end
end

function grab()
	p.grab("hug")
end

function cockVore(args)
	return p.doVore(args, "shaft", {}, "swallow")
end

function cockEscape(args)
	return p.doEscape(args, {wet = { power = 5, source = entity.id()}}, {} )
end

function oralVore(args)
	return p.doVore(args, "belly", {}, "swallow")
end

function checkVore()
	if checkOralVore() then return true end
	if checkCockVore() then return true end
end

function checkOralVore()
	return p.checkEatPosition(p.localToGlobal( {0, 0} ), 5, "belly", "eat")
end

function checkCockVore()
	return p.checkEatPosition(p.localToGlobal( {0, -3} ), 4, "shaft", "cockVore")
end


-------------------------------------------------------------------------------
function state.stand.begin()
	p.setMovementParams( "default" )
	p.resolvePosition(5)
end

state.stand.eat = oralVore
state.stand.cockVore = cockVore
state.stand.cockEscape = cockEscape

state.stand.checkCockVore = checkCockVore
state.stand.checkOralVore = checkOralVore

-------------------------------------------------------------------------------

function state.smol.begin()
	p.setMovementParams( "smol" )
	p.resolvePosition(3)
end

-------------------------------------------------------------------------------
