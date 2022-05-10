local inited
local updated
function init()
	inited = true
	updated = false
end
function update()
	if inited and updated and (world.regionActive(object.boundBox())) then
		world.setTileProtection( config.getParameter("dungeonId") or 0, config.getParameter("protect") or false )
		world.placeDungeon( config.getParameter("dungeon"), object.toAbsolutePosition(config.getParameter("placeOffset") or {0,0}), config.getParameter("dungeonId") or 0 )
		object.smash(true)
	end
	if inited then
		updated = true
	end
end

function uninit()
	inited = false
	updated = false
end
