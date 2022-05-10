local inited
local updated
function init()
	inited = true
	updated = false
end
function update()
	if inited and updated and (world.regionActive(object.boundBox())) then
		local npc = config.getParameter("npc")
		if type(npc) == "string" then
			local success, data = pcall(root.assetJson, ("/species/" .. npc .. ".species"))
			if success then
				world.spawnNpc(object.position(), npc, config.getParameter("typeName"), config.getParameter("level"), config.getParameter("seed"), config.getParameter("npcParameters"))
			end
		end
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
