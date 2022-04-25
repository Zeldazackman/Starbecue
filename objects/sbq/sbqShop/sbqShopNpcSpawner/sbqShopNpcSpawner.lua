function init()
	object.smash(true)
end

function die()
	local npc = config.getParameter("npc")
	sb.logInfo(npc)
	local success, data = pcall(root.assetJson, ("/species/"..npc..".species"))
	if success then
		world.spawnNpc(object.position(), npc, config.getParameter("typeName"), config.getParameter("level"), config.getParameter("seed"), config.getParameter("npcParameters") )
	end
end
