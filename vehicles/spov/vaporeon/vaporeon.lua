--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/spov/playable_vso.lua")

state = {
	stand = {},
	sit = {},
	lay = {},
	sleep = {},
	back = {},
	hug = {},
	smol = {},
	chonk_ball = {}
}

--[[

vaporeon plan:

	state chart:
		0	 *			sleep
		|	 V			|
		0	idle - sit - lay - back
		|	 :		 \		:
		0	 :	 sleep - pin - bed - hug
		·	 :			V		 L
		1	idle - sit - lay - back
		|	 :			|
		1	 :			sleep
		·	 :
		2	idle - sit - lay - sleep

	(struggling not included in chart, everything in full has it)

	todo:
	- pills to control the chance of entering/leaving a desired state (and states leading toward it)


	eventually if I can figure out how:
	- walk around
	- follow nearby player
	- eat automatically if low health, to protect (and heal w/ pill)
	- attack enemies
	- ride on back to control
		- shlorp in from back -> control from inside?

]]--

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)
end

function onBegin()	--This sets up the VSO ONCE.
end

function onEnd()
end

-------------------------------------------------------------------------------

function p.whenFalling()
	if p.state ~= ("stand" or "smol" or "chonk_ball") and mcontroller.yVelocity() < -5 then
		p.setState( "stand" )
		p.doAnims( p.stateconfig[p.state].control.animations.fall )
		p.movement.falling = true
		for i = 1, p.occupants.total do
			if p.occupant[i].location == "hug" then
				p.uneat(p.occupant[i].id)
			end
		end
	end
end

-------------------------------------------------------------------------------

function state.stand.update()
	if p.driving then
		if p.tapControl( p.driverSeat, "special1" ) then
			world.spawnProjectile( "spovwarpouteffectprojectile", mcontroller.position(), entity.id(), {0,0}, true)
			if p.occupants.belly < 2 then
				p.setState( "smol" )
				p.doAnims( p.stateconfig.smol.idle, true )
			else
				p.setState( "chonk_ball" )
				p.doAnims( p.stateconfig.chonk_ball.idle, true )
			end
			return
		end
		if p.tapControl( p.driverSeat, "special2" ) then
			if p.occupants.belly > 0 then
				p.doTransition( "escape", {index=p.occupants.belly} ) -- last eaten
			end
		end
	end
end

function state.stand.interact( occupantId )
	if mcontroller.yVelocity() > -5 then
		p.onInteraction( occupantId )
	end
end

function state.stand.eat( args )
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function state.stand.letout( args )
	return p.doEscape(args, "belly", {3.5, -1.875}, {"vsoindicatemaw"}, {"droolsoaked", 5} )
end

function state.stand.bapeat()
	if p.checkEatPosition(p.localToGlobal( p.stateconfig.stand.control.oralVore.position ), "belly", "eat") then return end
end

-------------------------------------------------------------------------------

function state.sit.pin( args )
	local pinnable = { args.id }
	-- if not interact target or target isn't in front
	if args.id == nil or p.globalToLocal( world.entityPosition( args.id ) )[1] < 3 then
		local pinbounds = {
			p.localToGlobal({2.75, -4}),
			p.localToGlobal({3.5, -3.5})
		}
		pinnable = world.playerQuery( pinbounds[1], pinbounds[2] )
		if #pinnable == 0 and p.driving then
			pinnable = world.npcQuery( pinbounds[1], pinbounds[2] )
		end
	end
	local index = p.occupants.total + 1
	if #pinnable >= 1 and p.eat( pinnable[1], "hug" ) then
		--vsoVictimAnimSetStatus( "occupant"..index , {} )
	end
	return true
end

-------------------------------------------------------------------------------

function LayAbsorb()
	local index = p.findFirstIndexForLocation("hug")
	if not index then return false end

	animator.playSound( "slurp" )
	return true, function()
		p.occupant[index].location = "belly"
	end
end

function state.lay.update()
	if p.driving then
		p.primaryAction() -- lick
	end

	if p.driving and vehicle.controlHeld( p.driverSeat, "jump" ) then
		p.doTransition( "absorb" )
	end
end

state.lay.absorb = LayAbsorb

function state.lay.unpin(args)
	local returnval = {}
	returnval[1], returnval[2], returnval[3] = p.doEscape({index = p.findFirstIndexForLocation("hug")}, "hug", {1.3125, -2.0}, {}, {})
	return true, returnval[2], returnval[3]
end

-------------------------------------------------------------------------------

function state.sleep.update()
	if p.driving and vehicle.controlHeld( p.driverSeat, "jump" ) then
		p.doTransition( "absorb" )
	end
end

state.sleep.absorb = LayAbsorb

-------------------------------------------------------------------------------

function state.back.update()
	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and p.standalone then
		if p.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

function state.back.bed( args )
	local index = p.occupants.total + 1

	if p.eat( args.id, "hug" ) then
		--vsoVictimAnimSetStatus( "occupant"..index, {} );
		return true
	else
		return false
	end
end

function state.back.unbed(args)
	return p.doEscapeNoDelay({index = p.findFirstIndexForLocation("hug")}, "hug", {1.3125, -2.0}, {})
end

-------------------------------------------------------------------------------

function state.hug.update()
	if p.driving and vehicle.controlHeld( p.driverSeat, "jump" ) then
		p.doTransition( "absorb" )
	end
end

function state.hug.absorb(args)
	local index = p.findFirstIndexForLocation("hug")
	if not index then return false end

	animator.playSound( "slurp" )
	return true, function()
		p.occupant[index].location = "belly"
	end
end

-------------------------------------------------------------------------------

function state.smol.update()
	if p.driving and p.tapControl( p.driverSeat, "special1" ) then
		world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect
		p.setState( "stand" )
		p.doAnims( p.stateconfig.stand.idle, true )
	end
end

function state.smol.begin()
	p.setMovementParams( "smol" )
end

function state.smol.ending()
	p.setMovementParams( "default" )
end

-------------------------------------------------------------------------------

local CurBallFrame = 0
function roll_chonk_ball(dx, control)
	mcontroller.setXVelocity( dx * control.walkSpeed)
	if dx ~= 0 and vsoAnimEnd( "bodyState" ) then
		CurBallFrame = CurBallFrame + dx
		if CurBallFrame > 11 then
			CurBallFrame = 0
		elseif CurBallFrame < 0 then
			CurBallFrame = 11
		end
		animator.setGlobalTag("rotationFrame", CurBallFrame)
		p.doAnim( "bodyState", "chonk_ball" )
	end
end

function state.chonk_ball.update()
	if p.occupants.belly < 2 then
		world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect

		p.setState( "smol" )
		p.doAnims( p.stateconfig.smol.idle, true )
	end

	local control = p.stateconfig[p.state].control

	local dx = 0
	local dy = 0

	if p.driving then
		if p.tapControl( p.driverSeat, "special1" ) then
			world.spawnProjectile( "spovwarpineffectprojectile", mcontroller.position(), entity.id(), {0,0}, true) --Play warp in effect

			p.setState( "stand" )
			p.doAnims( p.stateconfig.stand.idle, true )
			return
		end
		if vehicle.controlHeld( p.driverSeat, "left" ) then
			dx = dx - 1
		end
		if vehicle.controlHeld( p.driverSeat, "right" ) then
			dx = dx + 1
		end
		if vehicle.controlHeld( p.driverSeat, "up" ) then
			dy = dy + 1
		end
		if vehicle.controlHeld( p.driverSeat, "down" ) then
			dy = dy - 1
		end
		if vehicle.controlHeld( p.driverSeat, "jump" ) then
			p.movement.jumped = true
		end
	end

	if dy == -1 and p.movement.jumped then
		mcontroller.applyParameters{ ignorePlatformCollision = true }
	else
		mcontroller.applyParameters{ ignorePlatformCollision = false }
	end

	if p.underWater() then
		mcontroller.approachYVelocity( 11, 50 ) --this should make ball vappy float on the surface of water haha
	end

	roll_chonk_ball(dx, control)
end

function state.chonk_ball.begin()
	animator.setGlobalTag("rotationFlip", p.direction)
	p.setMovementParams( "chonk_ball" )
	CurBallFrame = 0
	BallLastPosition = mcontroller.position()
end


function state.chonk_ball.ending()
	p.setMovementParams( "default" )
end
