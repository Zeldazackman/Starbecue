function init()
	world.placeDungeon( config.getParameter("dungeon"), object.position(), config.getParameter("dungeonId") )
	world.setTileProtection( config.getParameter("dungeonId"), config.getParameter("protect") )
	object.smash(true)
end
