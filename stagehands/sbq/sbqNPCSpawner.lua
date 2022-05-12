
function update()
	local position = stagehand.position()
	if world.regionActive({position[1]-1,position[2]-1,position[1]+1,position[2]+1}) then
		local npc = config.getParameter("npc")
		if type(npc) == "string" then
			local success, data = pcall(root.assetJson, ("/species/" .. npc .. ".species"))
			if success then
				world.spawnNpc(position, npc, config.getParameter("npcTypeName"), config.getParameter("npcLevel") or world.threatLevel(), config.getParameter("npcSeed"), config.getParameter("npcParameters"))
			end
		end
		stagehand.die()
	end
end
