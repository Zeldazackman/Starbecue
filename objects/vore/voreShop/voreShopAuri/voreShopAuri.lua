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
	local X = 0
	local Y = 0

	local headPos = {-0.375, 6.75}
	local worldHeadPos = object.toAbsolutePosition(headPos)
	local target = getVisibleEntity(world.playerQuery(worldHeadPos, 50 ))
	if not target then target = getVisibleEntity(world.npcQuery(worldHeadPos, 50 )) end

	if target ~= nil then
		local targetPos = world.entityPosition(target)
		local targetDist = world.distance(targetPos, worldHeadPos)
		world.debugLine(worldHeadPos, targetPos, {72, 207, 180})

		local angle = math.atan(targetDist[2], targetDist[1]) * 180/math.pi
		local distance = world.magnitude(worldHeadPos, targetPos)
		if distance > 1 then
			if angle <= 15 and angle >= -15 then
				X = 1 * object.direction()
				Y = 0
			elseif angle <= 75 and angle > 15 then
				X = 1 * object.direction()
				Y = 1
			elseif angle <= 105 and angle > 75 then
				X = 0
				Y = 1
			elseif angle <= 165 and angle > 105 then
				X = -1 * object.direction()
				Y = 1
			elseif angle > 165 then
				X = -1 * object.direction()
				Y = 0

			elseif angle >= -75 and angle < -15 then
				X = 1 * object.direction()
				Y = -1
			elseif angle >= -105 and angle < -75 then
				X = 0
				Y = -1
			elseif angle >= -165 and angle < -105 then
				X = -1 * object.direction()
				Y = -1
			elseif angle < -165 then
				X = -1 * object.direction()
				Y = 0
			end

			if distance > 5 then
				X = X * 2
			end
		end
	end
	animator.setGlobalTag("eyesX", X)
	animator.setGlobalTag("eyesY", Y)
end

function getVisibleEntity(entities)
	for _, id in ipairs(entities) do
		if entity.entityInSight(id) then
			return id
		end
	end
end
