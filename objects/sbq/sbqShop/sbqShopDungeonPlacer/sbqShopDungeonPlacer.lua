function init()
	object.smash(true)
end

function die()
	world.setTileProtection( config.getParameter("dungeonId") or 0, config.getParameter("protect") or false )
	world.placeDungeon( config.getParameter("dungeon"), object.toAbsolutePosition(config.getParameter("placeOffset") or {0,0}), config.getParameter("dungeonId") or 0 )
end
