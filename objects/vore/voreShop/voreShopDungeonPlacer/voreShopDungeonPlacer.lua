function init()
	world.placeDungeon( config.getParameter("dungeon"), object.toAbsolutePosition(config.getParameter("placeOffset")) or object.position(), config.getParameter("dungeonId") or 0 )
	world.setTileProtection( config.getParameter("dungeonId") or 0, config.getParameter("protect") or false )
	object.smash(true)
end

function die()
	world.placeDungeon( config.getParameter("dungeon"), object.toAbsolutePosition(config.getParameter("placeOffset")) or object.position(), config.getParameter("dungeonId") or 0 )
end
