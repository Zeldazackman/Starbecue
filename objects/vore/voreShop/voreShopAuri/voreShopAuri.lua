function init()
end

function update(dt)
	eyeTracking()

end

function die()
end

--function onInteraction()
--end

function eyeTracking()
	local headPos = {-0.375, 6.75}
	local worldHeadPos = object.toAbsolutePosition(headPos)
	local target = getVisibleEntity(world.playerQuery(worldHeadPos, 20 ))
	if not target then target = getVisibleEntity(world.npcQuery(worldHeadPos, 20 )) end

	if target ~= nil then
		local targetDist = entity.distanceToEntity(target)
		world.debugLine(worldHeadPos, world.entityPosition(target), {72, 207, 180})

		local angle = math.atan(targetDist[2] - headPos[2], targetDist[1] - headPos[1])


	else
		animator.setGlobalTag("eyesX", "0")
		animator.setGlobalTag("eyesY", "0")
	end
end

function getVisibleEntity(entities)
	for _, id in ipairs(entities) do
		if entity.entityInSight(id) then
			return id
		end
	end
end
