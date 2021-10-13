local directives
local objPosition
local promise = "send"
function init()
end

function update(dt)
	if promise == "send" then
		promise = world.sendEntityMessage(effect.sourceEntity(), "sbqLoungingIn")
	end
	if promise and promise:finished() then
		if promise:succeeded() then
			local lounge = promise:result()
			if lounge then
				directives = world.getObjectParameter(lounge, "sitDirectives")

				local sitpos = world.getObjectParameter(lounge, "sitPositions")[1]
				local imagepos = world.getObjectParameter(lounge, "imagePosition")

				local playerimage = world.entityPortrait(effect.sourceEntity(), "full")
				local farthest = {0, 0, 0, 0}
				for _,part in ipairs(playerimage) do
					local size = {-part.transformation[1][3], -part.transformation[2][3]}
					local pos = part.position
					if farthest[1] > pos[1] - size[1] then farthest[1] = pos[1] - size[1] end
					if farthest[2] > pos[2] - size[2] then farthest[2] = pos[2] - size[2] end
					if farthest[3] < pos[1] + size[1] then farthest[3] = pos[1] + size[1] end
					if farthest[4] < pos[2] + size[2] then farthest[4] = pos[2] + size[2] end
				end
				local playersize = {farthest[3] - farthest[1], farthest[4] - farthest[2]}
				local playerpos = {playersize[1]/2, playersize[2]/2}

				objPosition = {
					x = math.floor(-playerpos[1] + sitpos[1] - imagepos[1] + 0.5), -- +0.5 to round instead of floor
					y = math.floor(-playerpos[2] + sitpos[2] - imagepos[2] + 0.5), -- since there's no math.round in lua
				}
			end
		end
		promise = nil
	end
	if not promise then
		if not directives then return end
		effect.setParentDirectives(sb.replaceTags(directives, objPosition))
		return
	end
end

function uninit()
end
