--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

state = {
	smol = {}
}

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

end

function onBegin()
	p.occupant[0].location = "egg"
	p.occupants.total = 1
	p.occupants.egg = 1
	p.includeDriver = true
	p.driving = false

	if not p.settings.cracks then
		p.settings.cracks = 0
	end

	if p.settings.escapeModifier == "noEscape" then
		p.settings.escapeModifier = "antiEscape"
	end

	animator.setGlobalTag( "cracks", p.settings.cracks )
end

function onEnd()

end

-------------------------------------------------------------------------------

function p.edible( occupantId, seatindex, source )
	if p.occupant[0].id ~= occupantId then return false end
	if p.stateconfig[p.state].edible then
		world.sendEntityMessage( source, "smolPreyData", seatindex, p.getSmolPreyData(), entity.id())
		return true
	end
end

function state.smol.crack( args )
	p.settings.cracks = p.settings.cracks + 1

	if p.settings.cracks > 3 then p.onDeath()
	else animator.setGlobalTag( "cracks", p.settings.cracks )
	end
end


-------------------------------------------------------------------------------
