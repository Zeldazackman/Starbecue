--This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 2.0 Generic License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
--https://creativecommons.org/licenses/by-nc-sa/2.0/  @

require("/vehicles/sbq/sbq_main.lua")

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

-------------------------------------------------------------------------------

function onForcedReset( )	--helper function. If a victim warps, vanishes, dies, force escapes, this is called to reset me. (something went wrong)
end

function onBegin()	--This sets up the VSO ONCE.
end

function onEnd()
end

-------------------------------------------------------------------------------

function p.update(dt)
	p.whenFalling()
	p.changeSize()
end

function p.whenFalling()
	if p.state == "stand" or p.state == "smol" or p.state == "chonk_ball" then return end
	if not mcontroller.onGround() and p.totalTimeAlive > 1 then
		p.setState( "stand" )
		p.doAnims( p.stateconfig[p.state].control.animations.fall )
		p.movement.falling = true
		p.uneat(p.findFirstOccupantIdForLocation("hug"))
	end
end

function p.changeSize()
	if p.tapControl( p.driverSeat, "special1" ) and p.totalTimeAlive > 0.5 and not p.transitionLock then
		p.uneat(p.findFirstOccupantIdForLocation("hug"))

		local changeSize = "smol"
		if p.occupants.belly >= 2 then
			changeSize = "chonk_ball"
		end
		if p.state == changeSize then
			changeSize = "stand"
		end
		p.warpInEffect(); --Play warp in effect
		p.setState( changeSize )
	end
end

function escapeAnal(args)
	return p.doEscape(args, {"vsoindicateout"}, {"droolsoaked", 5} )
end

function eatAnal(args)
	return p.doVore(args, "belly", {"vsoindicateout"}, "swallow")
end

-------------------------------------------------------------------------------

function state.stand.begin()
	p.setMovementParams( "default" )
	p.resolvePosition(5)
end

function state.stand.eat( args )
	if not mcontroller.onGround() or p.movement.falling then return false end
	return p.doVore(args, "belly", {"vsoindicatemaw"}, "swallow")
end

function state.stand.letout( args )
	if not mcontroller.onGround() or p.movement.falling then return false end
	return p.doEscape(args, {"vsoindicatemaw"}, {"droolsoaked", 5} )
end

function state.stand.vore()
	return p.checkEatPosition(p.localToGlobal( p.stateconfig.stand.actions.oralVore.position ), 2, "belly", "eat")
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
	if #pinnable >= 1 then
		p.addRPC(world.sendEntityMessage(pinnable[1], "sbqIsPreyEnabled", "held"), function(enabled)
			if enabled then
				p.eat( pinnable[1], "hug" )
			end
			p.doTransition("lay")
		end)
	else
		p.doTransition("lay")
	end
	return true
end

-------------------------------------------------------------------------------

function absorb(args)
	args.id = p.findFirstOccupantIdForLocation("hug")
	if not args.id then return false end

	animator.playSound( "slurp" )
	return p.moveOccupantLocation(args, "belly")
end

function state.lay.update()
	if p.driving then
		if p.pressControl( p.driverSeat, "jump" ) then
			p.doTransition( "absorb" )
		end
		if p.pressControl( p.driverSeat, "primaryFire" ) or p.pressControl( p.driverSeat, "altFire" )then
			p.doTransition( "lick" )
		end
	end
end

state.lay.absorb = absorb

function state.lay.unpin(args)
	args.id = p.findFirstOccupantIdForLocation("hug")
	local returnval = {}
	returnval[1], returnval[2], returnval[3] = p.doEscape(args, {}, {})
	return true, returnval[2], returnval[3]
end

-------------------------------------------------------------------------------

function state.sleep.update()
	if p.driving and p.pressControl( p.driverSeat, "jump" ) then
		p.doTransition( "absorb" )
	end
end

state.sleep.absorb = absorb

-------------------------------------------------------------------------------

function state.back.update()
	-- simulate npc interaction when nearby
	if p.occupants.total == 0 and not p.isObject then
		if p.randomChance(1) then -- every frame, we don't want it too often
			local npcs = world.npcQuery(mcontroller.position(), 4)
			if npcs[1] ~= nil then
				p.doTransition( "bed", {id=npcs[1]} )
			end
		end
	end
end

function state.back.bed( args )
	return p.eat( args.id, "hug" )
end

function state.back.unbed(args)
	return p.uneat(p.findFirstOccupantIdForLocation("hug"))
end

state.back.escapeAnal = escapeAnal
state.back.eatAnal = eatAnal

-------------------------------------------------------------------------------

function state.hug.update()
	if p.pressControl( p.driverSeat, "jump" ) then
		p.doTransition( "absorb" )
	end
end

state.hug.absorb = absorb
state.hug.escapeAnal = escapeAnal
state.hug.eatAnal = eatAnal

-------------------------------------------------------------------------------

function state.smol.begin()
	p.setMovementParams( "smol" )
	p.resolvePosition(3)
end

-------------------------------------------------------------------------------

function state.chonk_ball.update(dt)
	roll_chonk_ball(dt)
	p.movement.aimingLock = 0.1
	if p.occupants.belly < 2 and not p.transitionLock then
		p.warpInEffect();

		p.setState( "smol" )
	end
end

function state.chonk_ball.begin()
	p.setPartTag( "global","rotationFlip", p.direction * -1)
	p.setMovementParams( "chonk_ball" )
	p.resolvePosition(3)
	self.ballFrames = p.stateconfig.chonk_ball.control.ballFrames
	self.ballRadius = p.stateconfig.chonk_ball.control.ballRadius
	self.angularVelocity = 0
	self.angle = 0
end

function state.chonk_ball.nudge(args)
	if args.direction ~= nil then
		local dx = 0
		if args.direction == "front" then
			dx = 1
		elseif args.direction == "back" then
			dx = -1
		end
		dx = dx * p.direction
		if math.abs(mcontroller.xVelocity()) <= p.movementParams.walkSpeed * 1.5 then
			mcontroller.force({p.movementParams.groundForce * 1.5 * dx, 0})
		end
	end
end

function roll_chonk_ball(dt)
	updateAngularVelocity(dt)
	updateRotationFrame(dt)
	self.lastPosition = mcontroller.position()
end

--these are taken from /tech/distortionsphere/distortionsphere.lua
require "/scripts/vec2.lua"

function updateRotationFrame(dt)
	self.angle = math.fmod(math.pi * 2 + self.angle + self.angularVelocity * dt, math.pi * 2)

	-- Rotation frames for the ball are given as one *half* rotation so two
	-- full cycles of each of the ball frames completes a total rotation.
	local rotationFrame = math.floor(self.angle / math.pi * self.ballFrames) % self.ballFrames
	p.setPartTag( "global","rotationFrame", rotationFrame)
end

function updateAngularVelocity(dt)
	if mcontroller.onGround() then
		-- If we are on the ground, assume we are rolling without slipping to
		-- determine the angular velocity
		local positionDiff = world.distance(self.lastPosition or mcontroller.position(), mcontroller.position())
		self.angularVelocity = -vec2.mag(positionDiff) / dt / self.ballRadius

		if positionDiff[1] > 0 then
			self.angularVelocity = -self.angularVelocity
		end
	end
end