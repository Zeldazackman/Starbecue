--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

state = {
	stand = {}
}

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

end

function onBegin()	--This sets up the VSO ONCE.
	p.standalone = false
	p.driverSeat = "occupant1"
	p.driving = false
	p.occupant[1].location = "other"
	p.occupants.total = 1
	p.occupants.other = 1

	vsoOnBegin( "state_stand", begin_state_stand)
end

function onEnd()

end

-------------------------------------------------------------------------------
function p.edible( occupantId )
	if p.getEidFromSeatname( "occupant1" ) ~= occupantId then return false end
	if p.stateconfig[p.state].edible then
		if p.stateconfig[p.state].ediblePath then
			world.sendEntityMessage( source, "smolPreyPath", seatindex, p.stateconfig[p.state].ediblePath[p.cracks] )
		end
		return true
	end
end

function state.stand.begin()
	p.occupant[1].id = p.driverSeat
	p.forceSeat( p.driverSeat, "occupant1" )
end

p.cracks = 0

function state.stand.crack( args )
	p.cracks = p.cracks + 1

	if p.cracks > 3 then p.onDeath()
	else animator.setGlobalTag( "cracks", tostring(p.cracks) )
	end
end


-------------------------------------------------------------------------------
