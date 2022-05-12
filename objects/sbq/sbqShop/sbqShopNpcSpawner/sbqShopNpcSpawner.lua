require("/objects/sbq/sbqShop/sbqShopDungeonPlacer/sbqPleaseDontSegfault.lua")

function doTheThing()
	local box = object.boundBox()
	if world.regionActive({box[1]-5,box[2]-5,box[3]+5,box[4]+5}) then
		local npc = config.getParameter("npc")
		if type(npc) == "string" then
			local success, data = pcall(root.assetJson, ("/species/" .. npc .. ".species"))
			if success then
				world.spawnNpc(object.position(), npc, config.getParameter("typeName"), config.getParameter("level"), config.getParameter("seed"), config.getParameter("npcParameters"))
			end
		end
		return true
	end
end

function thingDone()
	world.breakObject(entity.id(), true)
end
