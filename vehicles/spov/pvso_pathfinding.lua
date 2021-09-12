
function p.updatePathfinding(dt)
	local driver = p.driver
	if p.driving and (driver ~= nil) and (world.entityType(driver) == "player") then return end
	--[[
	if a monster or an NPC or whatever ever ends up in a driver seat, possibly from setting them as a smol species,
	then we do want it to use whateve pathfinding it has so it doesn't just sit there doing nothing
	]]
	if state[p.state].pathfinding ~= nil then
		state[p.state].pathfinding(dt)
	else
		p.pathfinding(dt)
	end
end

-- extend mcontroller to add actor methods
local mcontroller_extensions = {}
-- [[ this all seems to cause it to crash, seems like you can't do that
function mcontroller_extensions.controlMove(direction, run)
	-- Controls movement in a direction.
	-- Each control replaces the previous one.
end

function mcontroller_extensions.baseParameters()
	-- Returns the base movement parameters.
end

function mcontroller_extensions.facingDirection()
	-- Returns the facing direction. -1 for left, 1 for right.
end

function mcontroller_extensions.movingDirection()
	-- Returns the direction that the actor movement controller is currently moving in. -1 for left, 1 for right.
end

function mcontroller_extensions.controlParameters(parameters)
	-- Changes movement parameters. Parameters are merged into the base parameters.
	-- Each control is merged into the previous one.
end

function mcontroller_extensions.controlDown()
	-- Controls dropping through platforms.
end

function mcontroller_extensions.controlApproachVelocity(targetVelocity, maxControlForce)
	-- Approaches the targetVelocity using the force provided.
	-- If the current velocity is higher than the provided targetVelocity,
	-- the targetVelocity will still be approached, effectively slowing down the entity.
	-- Each control overrides the previous one.
end

function mcontroller_extensions.controlApproachXVelocity(targetVelocity, maxControlForce)
	-- Approaches an X velocity. Same as using approachVelocityAlongAngle with angle 0.
	-- Each control overrides the previous one.
end

function mcontroller_extensions.controlApproachYVelocity(targetVelocity, maxControlForce)
	-- Approaches a Y velocity. Same as using approachVelocityAlongAngle with angle (Pi / 2).
	-- Each control overrides the previous one.
end

function mcontroller_extensions.liquidMovement()
	-- Returns whether the controller is currently in liquid movement mode.
end

function mcontroller_extensions.controlFly(velocity)
	-- Controls flying in the specified velocity.
	-- Each control overrides the previous one.
end

-- technically not part of mcontroller but it's relevant the same way
status = {}
function status.stat(stat)
	-- Returns the value for the specified stat. Defaults to 0.0 if the stat does not exist.
	-- (we only need this to support "jumpModifier")
end
--]]
