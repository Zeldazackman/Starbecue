require("/scripts/pathing.lua")

function p.updatePathfinding(dt)
	local driver = p.driver
	if p.driving and (driver ~= nil) and (world.entityType(driver) == "player") then return end
	--[[
	if a monster or an NPC or whatever ever ends up in a driver seat, possibly from setting them as a smol species,
	then we do want it to use whateve pathfinding it has so it doesn't just sit there doing nothing
	]]
	if p.pathMover == nil then
		p.pathMover = PathMover:new({ ---@diagnostic disable-line: undefined-global
			-- pathOptions = { -- all defaults here will be filled in automatically
			-- 	returnBest = false,
			-- 	mustEndOnGround = mcontroller.baseParameters().gravityEnabled,
			-- 	maxDistance = 200,
			-- 	swimCost = 5,
			-- 	dropCost = 2,
			-- 	boundBox = mcontroller.boundBox(),
			-- 	droppingBoundBox = padBoundBox(0.2, 0), --Wider bound box for dropping
			-- 	standingBoundBox = padBoundBox(-0.7, 0), --Thinner bound box for standing and landing
			-- 	smallJumpMultiplier = 1 / math.sqrt(2), -- 0.5 multiplier to jump height
			-- 	jumpDropXMultiplier = 1,
			-- 	enableWalkSpeedJumps = true,
			-- 	enableVerticalJumpAirControl = false,
			-- 	maxFScore = 400,
			-- 	maxNodesToSearch = 70000,
			-- 	maxLandingVelocity = -10.0,
			-- 	liquidJumpCost = 15
			-- },
			-- run = false,
			movementParameters = p.movementParams
		})
	end
	if state[p.state].pathfinding ~= nil then
		state[p.state].pathfinding(dt)
	else
		p.pathfinding(dt)
	end
	if p.isPathfinding then
		p.pathingState = p.pathMover:move(p.pathingTarget, dt)
		sb.setLogMap("pathingState", tostring(p.pathingState))
		if p.pathingState == "pathfinding" then
			p.activeControls = {} -- don't keep moving while deciding what to do
		end
		if p.pathingState == true then -- arrived at target
			p.stopPathing()
		end
	end
end

p.pathMover = nil
p.pathingTarget = nil

function p.pathTo(target, exact)
	p.isPathfinding = true
	p.pathingTarget = target
	if not exact then
		p.pathingTarget = findGroundPosition(
			p.pathingTarget, -- target
			-10, 10 -- min/max height
		)
	end
end

function p.stopPathing()
	p.isPathfinding = false
	p.activeControls = {}
end

-- extend mcontroller to add actor methods
mcontroller_extensions = {}

p.activeControls = {}
function p.doControls()
	-- moveDirection, run, and down are handled in pvso_driving in relevant locations
	if p.activeControls.fly then
		mcontroller.setVelocty(p.activeControls.fly) -- this might be wrong?? no clue
	end
	if p.activeControls.targetVelocity then
		mcontroller.approachVelocity(p.activeControls.targetVelocity, p.activeControls.maxControlForce)
	end
	if p.activeControls.targetXVelocity then
		mcontroller.approachXVelocity(p.activeControls.targetXVelocity, p.activeControls.maxControlForce)
	end
	if p.activeControls.targetYVelocity then
		mcontroller.approachYVelocity(p.activeControls.targetYVelocity, p.activeControls.maxControlForce)
	end
end

function mcontroller_extensions.clearControls() -- not used by pathing.lua? good to have anyway
	p.activeControls = {}
end

function mcontroller_extensions.controlMove(direction, run)
	-- Controls movement in a direction.
	-- Each control replaces the previous one.
	p.activeControls = {
		moveDirection = direction,
		run = run
	}
end

function mcontroller_extensions.baseParameters()
	-- Returns the base movement parameters.
	return p.movementParams
end

function mcontroller_extensions.boundBox()
	-- Returns a rect containing the entire collision of the movement controller, in local coordinates.
	return mcontroller.localBoundBox()
end

function mcontroller_extensions.facingDirection()
	-- Returns the facing direction. -1 for left, 1 for right.
	return p.direction
end

function mcontroller_extensions.movingDirection()
	-- Returns the direction that the actor movement controller is currently moving in. -1 for left, 1 for right.
	local vel = mcontroller.xVelocity()
	return (vel > 0 and 1) or (vel == 0 and 0) or -1
end

function mcontroller_extensions.controlParameters(parameters)
	-- Changes movement parameters. Parameters are merged into the base parameters.
	-- Each control is merged into the previous one.
	p.movementParamOverrides = sb.jsonMerge(p.movementParamOverrides, parameters)
	p.setMovementParams(p.movementParamsName)
end

function mcontroller_extensions.controlDown()
	-- Controls dropping through platforms.
	p.activeControls.controlDown = true -- no override
end

function mcontroller_extensions.controlApproachVelocity(targetVelocity, maxControlForce)
	-- Approaches the targetVelocity using the force provided.
	-- If the current velocity is higher than the provided targetVelocity,
	-- the targetVelocity will still be approached, effectively slowing down the entity.
	-- Each control overrides the previous one.
	p.activeControls = {
		targetVelocity = targetVelocity,
		maxControlForce = maxControlForce
	}
end

function mcontroller_extensions.controlApproachXVelocity(targetVelocity, maxControlForce)
	-- Approaches an X velocity. Same as using approachVelocityAlongAngle with angle 0.
	-- Each control overrides the previous one.
	p.activeControls = {
		targetXVelocity = targetVelocity,
		maxControlForce = maxControlForce
	}
end

function mcontroller_extensions.controlApproachYVelocity(targetVelocity, maxControlForce)
	-- Approaches a Y velocity. Same as using approachVelocityAlongAngle with angle (Pi / 2).
	-- Each control overrides the previous one.
	p.activeControls = {
		targetYVelocity = targetVelocity,
		maxControlForce = maxControlForce
	}
end

function mcontroller_extensions.liquidMovement()
	-- Returns whether the controller is currently in liquid movement mode.
	return p.underWater()
end

function mcontroller_extensions.controlFly(velocity)
	-- Controls flying in the specified velocity.
	-- Each control overrides the previous one.
	p.activeControls = {
		fly = velocity
	}
end

-- technically not part of mcontroller but it's relevant the same way
status = {}
function status.stat(stat)
	-- Returns the value for the specified stat. Defaults to 0.0 if the stat does not exist.
	-- (we only need this to support "jumpModifier")
	if stat == "jumpModifier" then
		return 0.0 -- this'll probably change later but I don't think anything affects this yet
	else
		return 0.0
	end
end
