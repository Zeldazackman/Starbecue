--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/scripts/vore/vsosimple.lua")
require("/vehicles/spov/playable_vso.lua")

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

p.vsoMenuName = "egg"

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)

	p.onForcedReset()

end

function onBegin()	--This sets up the VSO ONCE.
	p.control.standalone = false
	p.control.driver = "occupant1"
	p.control.driving = false
	p.driver = config.getParameter( "driver" )
	storage._vsoSpawnOwner = p.driver
	storage._vsoSpawnOwnerName = world.entityName( p.driver )
	p.occupantLocation[1] = "other"
	p.occupants.total = 1
	p.occupants.other = 1
	p.nowarpout = nowarpout
	message.setHandler( "forcedsit", p.control.pressE )
	message.setHandler( "despawn", function(_,_, nowarpout)
		local driver = vehicle.entityLoungingIn(p.control.driver)
		world.sendEntityMessage(driver, "PVSOClear")
		p.nowarpout = nowarpout
		_vsoOnDeath()
	end )

	p.stateconfig = config.getParameter("states")
	p.animStateData = root.assetJson( self.directoryPath .. self.cfgAnimationFile ).animatedParts.stateTypes

	vsoOnBegin( "state_stand", begin_state_stand)

	p.setState( "stand" )
end

function onEnd()

	p.onEnd()

end

-------------------------------------------------------------------------------
function p.edible( targetid )
	if vehicle.entityLoungingIn( "occupant1" ) ~= targetid then return false end
	return p.stateconfig[p.state].edible
end


function p.handleStruggles()
	local movetype, movedir

	movetype, movedir = vso4DirectionInput( "occupant1" )

	if movetype == nil or movetype == 0 then return end

	local struggledata = p.stateconfig[p.state].struggle[p.occupantLocation[1]]
	if struggledata == nil then return end

	if not vsoAnimEnded( struggledata.part.."State" ) and (
		vsoAnimIs( struggledata.part.."State", "s_up" ) or
		vsoAnimIs( struggledata.part.."State", "s_front" ) or
		vsoAnimIs( struggledata.part.."State", "s_back" ) or
		vsoAnimIs( struggledata.part.."State", "s_down" )
	) then return end

	local dir = nil
	if movedir == "B" then dir = "back" end
	if movedir == "F" then dir = "front" end
	if movedir == "U" then dir = "up" end
	if movedir == "D" then dir = "down" end

	if dir == nil then return end -- invalid struggle
	if struggledata[dir] == nil then return end

	if struggledata.script ~= nil then
		local statescript = p.statestripts[p.state][struggledata.script]
		statescript( 1, dir )
	end

	local chance = struggledata.chances
	if struggledata[dir].chances ~= nil then
		chance = struggledata[dir].chances
	end
	if vsoPill( "easyescape" ) then
		chance = chance.easyescape
	elseif vsoPill( "antiescape" ) then
		chance = chance.antiescape
	else
		chance = chance.normal
	end

	if chance ~= nil and ( chance.max == 0 or (
		(not p.control.driving or struggledata[dir].controlled)
		and vsoCounterValue( "struggleCount" ) >= chance.min
		and vsoCounterChance( "struggleCount", chance.min, chance.max )
	) ) then
		p.doTransition( struggledata[dir].transition, {index=1, direction=dir} )
	else
		sb.setLogMap("b", "struggle")
		local animation = {offset = struggledata[dir].offset}
		animation[struggledata.part] = "s_"..dir

		p.doAnims(animation)

		p.doAnims( struggledata[dir].animation or struggledata.animation, true )
		if struggledata[dir].victimAnimation then
			vsoVictimAnimReplay( "occupant1", struggledata[dir].victimAnimation, struggledata.part.."State" )
		end
		vsoCounterAdd( "struggleCount", 1 )
	end
end

function begin_state_stand()
	vsoSetTarget( "occupant1", p.driver )
	vsoEat( p.driver, "occupant1" )
	vsoVictimAnimVisible( "occupant1", false )
	vsoVictimAnimReplay( "occupant1", "othercenter", "bodyState" )
end


function state_stand()
	p.control.doPhysics()
	p.handleStruggles()
end


p.cracks = 0

p.registerStateScript( "stand", "crack", function( args )
	p.cracks = p.cracks + 1

	if p.cracks > 3 then _vsoOnDeath()
	else animator.setGlobalTag( "cracks", tostring(p.cracks) )
	end
end)


-------------------------------------------------------------------------------
