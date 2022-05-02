function init()
	local playerimage = world.entityPortrait(entity.id(), "full")
	local farthest = { 0, 0, 0, 0 }
	for _, part in ipairs(playerimage or {}) do
		local size = { -part.transformation[1][3], -part.transformation[2][3] }
		local pos = part.position
		if farthest[1] > pos[1] - size[1] then farthest[1] = pos[1] - size[1] end
		if farthest[2] > pos[2] - size[2] then farthest[2] = pos[2] - size[2] end
		if farthest[3] < pos[1] + size[1] then farthest[3] = pos[1] + size[1] end
		if farthest[4] < pos[2] + size[2] then farthest[4] = pos[2] + size[2] end
	end
	local playersize = { farthest[3] - farthest[1], farthest[4] - farthest[2] }
	local playerpos = { playersize[1] / 2, playersize[2] / 2 }

	local path = status.statusProperty( "sbqEggMask" )
	local imageSize = root.imageSize(path)

	objPosition = {
		x = math.floor(-playerpos[1] + imageSize[1]/2 + 0.5), -- +0.5 to round instead of floor
		y = math.floor(-playerpos[2] + imageSize[2]/2 + 0.5), -- since there's no math.round in lua
		path = path
	}
	effect.setParentDirectives(sb.replaceTags("?addmask=<path>;<x>;<y>", objPosition))
	script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end
