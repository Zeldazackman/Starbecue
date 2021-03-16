function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()
	self.digested = false
	self.cdt = 0
	status.removeEphemeralEffect("damagedigest")
	status.removeEphemeralEffect("damagesoftdigest")
	status.removeEphemeralEffect("displaydamagesoftdigest")
	status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)
	local health = world.entityHealth(entity.id())
	if health[1] > ( 0.01 * dt * self.powerMultiplier) then
		status.giveResource("health", 0.01 * dt * self.powerMultiplier)
	end
end

function uninit()

end
