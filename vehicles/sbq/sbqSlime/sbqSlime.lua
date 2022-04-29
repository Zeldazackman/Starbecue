--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

state = {
	smol = {}
}

function sbq.init()
	getColors()
end

function sbq.update(dt)
	--[[
	if p.movement.airtime > 0.25 then
		local velocity = mcontroller.velocity()
		p.setMovementParams( tostring(p.occupants.body)..".falling" )
		mcontroller.setRotation(math.pi/2 - math.atan(velocity[2], velocity[1]))
		p.movement.touchedGround = false
	elseif not p.movement.touchedGround then
		p.setMovementParams( "default" )
		mcontroller.setRotation(0)
		p.resolvePosition(3)
		p.movement.touchedGround = true
	end
	]]
end

function getColors()
	if not sbq.settings.firstLoadDone then

		sbq.settings.replaceColors[1] = math.random( #sbq.sbqData.replaceColors[1] - 2 )
		sbq.settings.firstLoadDone = true

		sbq.setColorReplaceDirectives()
		world.sendEntityMessage(sbq.spawner, "sbqSaveSettings", sbq.settings, "sbqSlime")
	end
end

-------------------------------------------------------------------------------

function sbq.extraBellyEffects(i, eid, health, bellyEffect)
	if (sbq.occupant[i].progressBar <= 0) and sbq.settings.bellyTF then
		sbq.loopedMessage("TF"..eid, eid, "sbqIsPreyEnabled", {"transformImmunity"}, function (immune)
			if not immune then
				transformMessageHandler( eid , 3 )
			end
		end)
	end
end

function state.smol.absorbVore( args )
	return sbq.doVore(args, "belly", {}, "slurp")
end

function state.smol.absorbEscape( args )
	local replaceColors = sbq.sbqData.replaceColors[1][sbq.settings.replaceColors[1]+1]
	if type(sbq.settings.replaceColorTable[1]) == "table" then
		replaceColors = sbq.settings.replaceColorTable[1]
	end
	local sbqSlimeSlowColor = replaceColors[3]

	return sbq.doEscape(args, { sbqSlimeSlow = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id(), property = sbqSlimeSlowColor }}, {}, "absorbVore")
end

function state.smol.checkAbsorbVore()
	return sbq.checkEatPosition(sbq.localToGlobal({0,0}), 3, "belly", "absorbVore")
end

-------------------------------------------------------------------------------
