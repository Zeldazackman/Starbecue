--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------
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
	if vehicle.entityLoungingIn( "occupant1" ) ~= occupantId then return false end
	if p.stateconfig[p.state].edible then
		if p.stateconfig[p.state].ediblePath then
			world.sendEntityMessage( source, "smolPreyPath", seatindex, p.stateconfig[p.state].ediblePath[p.cracks] )
		end
		return true
	end
end


function p.handleStruggles()
	local movedir = p.getSeatDirections( "occupant1" )

	if movedir == nil then return end -- invalid struggle

	local struggledata = p.stateconfig[p.state].struggle[p.occupant[1].location]
	if struggledata == nil then return end

	if not p.hasAnimEnded( struggledata.part.."State" ) and (
		p.animationIs( struggledata.part.."State", "s_up" ) or
		p.animationIs( struggledata.part.."State", "s_front" ) or
		p.animationIs( struggledata.part.."State", "s_back" ) or
		p.animationIs( struggledata.part.."State", "s_down" )
	) then return end

	if struggledata.script ~= nil then
		local statescript = p.statestripts[p.state][struggledata.script]
		statescript( struggler, movedir )
	end

	local chance = struggledata.chances
	if struggledata[movedir].chances ~= nil then
		chance = struggledata[movedir].chances
	end
	if chance[p.settings.escapeModifier] ~= nil then
		chance = chance[p.settings.escapeModifier]
	end

	if chance ~= nil and ( chance.max == 0 or (
		(not p.driving or struggledata[movedir].controlled)
		and (math.random(chance.min, chance.max) <= p.struggleCount))
	) ) then
		p.struggleCount = 0
		p.doTransition( struggledata[movedir].transition, {index=struggler, direction=movedir} )
	else
		p.struggleCount = p.struggleCount + 1
		p.bellySettleDownTimer = 5

		sb.setLogMap("b", "struggle")
		local animation = {offset = struggledata[movedir].offset}
		animation[struggledata.part] = "s_"..movedir

		p.doAnims(animation)

		if struggledata[movedir].victimAnimation then
			p.doVictimAnim( "occupant"..struggler, struggledata[movedir].victimAnimation, struggledata.part.."State" )
		end
		--animator.playSound( "struggle" )
	end
end

function state.begin.stand()
	p.occupant[1].id = p.driverSeat
	p.forceSeat( p.driverSeat, "occupant1" )
end


function state.stand()
	p.doPhysics()
	p.handleStruggles()
end


p.cracks = 0

p.registerStateScript( "stand", "crack", function( args )
	p.cracks = p.cracks + 1

	if p.cracks > 3 then p.onDeath()
	else animator.setGlobalTag( "cracks", tostring(p.cracks) )
	end
end)


-------------------------------------------------------------------------------
