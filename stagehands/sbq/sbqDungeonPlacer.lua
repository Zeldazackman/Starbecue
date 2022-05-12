
function update()
	local position = stagehand.position()
	if world.regionActive({position[1]-1,position[2]-1,position[1]+1,position[2]+1}) then
		local offset = config.getParameter("placeOffset") or {0,0}
		world.setTileProtection( config.getParameter("dungeonId") or 0, config.getParameter("protect") or false )
		world.placeDungeon( config.getParameter("dungeon"), {position[1]+offset[1],position[2]+offset[2]}, config.getParameter("dungeonId") or 0 )
		stagehand.die()
	end
end
