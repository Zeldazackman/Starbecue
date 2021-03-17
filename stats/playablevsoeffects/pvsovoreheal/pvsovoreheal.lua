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
	status.giveResource("health", 0.01 * dt * self.powerMultiplier)
end

function uninit()

end
