function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()

	status.removeEphemeralEffect("pvsovoreheal")
	status.removeEphemeralEffect("damagedigest")
	status.removeEphemeralEffect("displaydamagesoftdigest")
	status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)
	if world.entityExists(effect.sourceEntity()) and (effect.sourceEntity() ~= -65536) then
		local health = world.entityHealth(entity.id())

		if health[1] <= 1 then
			status.setResource("health", 1)
			return
		end

		if health[1] > ( 0.01 * dt * self.powerMultiplier) then
			status.modifyResourcePercentage("health", -0.01 * dt * self.powerMultiplier)
		end
	else
		effect.expire()
	end
end

function uninit()

end
