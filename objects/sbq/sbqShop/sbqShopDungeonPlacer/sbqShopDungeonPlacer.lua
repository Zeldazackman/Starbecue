require("/objects/sbq/sbqShop/sbqShopDungeonPlacer/sbqPleaseDontSegfault.lua")

function doTheThing()

	local position = object.toAbsolutePosition(config.getParameter("placeOffset") or {0,0})
	if world.regionActive({position[1]-1,position[2]-1,position[1]+1,position[2]+1}) then
		world.setTileProtection( config.getParameter("dungeonId") or 0, config.getParameter("protect") or false )
		world.placeDungeon( config.getParameter("dungeon"), position, config.getParameter("dungeonId") or 0 )
		return true
	end
end

function thingDone()
	world.breakObject(entity.id(), true)
end
