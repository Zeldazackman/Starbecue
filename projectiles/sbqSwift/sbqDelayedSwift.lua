require "/scripts/util.lua"

function init()
	self.targetPosition = projectile.getParameter("targetPosition")
	local creatures = world.entityQuery(self.targetPosition, 10, {includedTypes = {"creature"}})
	creatures = util.filter(shuffled(creatures), function(entityId)
			return (not world.lineTileCollision(entity.position(), world.entityPosition(entityId))) and world.entityCanDamage(projectile.sourceEntity(), entityId)
		end)
	self.target = creatures[1]
end

function update()
	if self.target and world.entityExists(self.target) then
		self.targetPosition = world.entityPosition(self.target)
	end
	if self.targetPosition then
		local toTarget = world.distance(self.targetPosition, mcontroller.position())
		local angle = math.atan(toTarget[2], toTarget[1])
		mcontroller.setRotation(angle)
	end

	if projectile.sourceEntity() and not world.entityExists(projectile.sourceEntity()) then
		projectile.die()
	end
end

function destroy()
	if projectile.sourceEntity() and world.entityExists(projectile.sourceEntity()) then
		local rotation = mcontroller.rotation()
		world.spawnProjectile( projectile.getParameter("childProjectile") or "sbqSwift", mcontroller.position(), projectile.sourceEntity(), {math.cos(rotation), math.sin(rotation)}, false, sb.jsonMerge({ speed = 50, power = projectile.getParameter("power"), damageTeam = world.entityDamageTeam(projectile.sourceEntity()) or {type = "indiscriminate"}}, projectile.getParameter("childParams") or {}))
	end
end
