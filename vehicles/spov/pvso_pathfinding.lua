
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
