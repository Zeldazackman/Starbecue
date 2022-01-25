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

function state.smol.absorbVore( args )
	return sbq.doVore(args, "belly", {}, "slurp")
end

function state.smol.absorbEscape( args )
	local effect = "slimeslow"
	if sbq.settings.replaceColors[1] == 2 then
		effect = "glueslow"
	end
	return sbq.doEscape(args, {[effect] = { power = 5 + (sbq.lounging[args.id].progressBar), source = entity.id()}}, {})
end

function state.smol.checkAbsorbVore()
	return sbq.checkEatPosition(sbq.localToGlobal({0,0}), 3, "belly", "absorbVore")
end

-------------------------------------------------------------------------------
