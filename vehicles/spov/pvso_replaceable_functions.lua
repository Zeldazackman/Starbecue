--[[
	Functions placed here are in key locations in the pvso where I believe people would want to place vso specific actions
	these will typically be empty, but are called at points in the main loop

	they're meant to be replaced in the vso itself to have it have said specific actions happen
]]
---------------------------------------------------------------------------------------------------------------------------------

-- to have something in the main loop rather than a state loop
function p.update(dt)
end

-- the standard state called when a state's script is undefined
function p.standardState()
end

-- the pathfinding function called if a state doesn't have its own pathfinding script
function p.pathfinding(dt)
end

---------------------------------------------------------------------------------------------------------------------------------

-- called when the vso starts falling, for example, you may want to force it to change to the stand state if it has one
function p.whenFalling()
end

---------------------------------------------------------------------------------------------------------------------------------
--[[these are called when handling the effects applied to the occupants, called for each one and give the occupant index,
the entity id, health, and the status checked in the options]]

-- to have any extra effects applied to those in digest locations
function p.extraBellyEffects(i, eid, health, status)
end

-- to have effects applied to other locations, for example, womb if the vso does unbirth
function p.otherLocationEffects(i, eid, health, status)
end

---------------------------------------------------------------------------------------------------------------------------------
