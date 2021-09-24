local timeAlive
local data
function init()
	timeAlive = 0
	data = config.getParameter( "data" )
	message.setHandler("pvsoSucc", function(_,_, succData)
		data = succData
	end)
end

function update(dt)
	local distance = world.distance( data.destination, mcontroller.position() )
	timeAlive = timeAlive + dt
	if (projectile.sourceEntity() and not world.entityExists(projectile.sourceEntity()))
	or ((math.abs(distance[1]) < 1 ) and (math.abs(distance[2]) < 1 ))

	or (not ((data.direction < 0 and distance[1] > 0) or (data.direction > 0 and distance[1] < 0)))
	or timeAlive >=1
	then
		projectile.die()
	end

	mcontroller.approachVelocityAlongAngle(math.atan(distance[2], distance[1]), data.speed*2, data.force)
end
