function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()
	self.digested = false
	self.cdt = 0
	status.removeEphemeralEffect("pvsovoreheal")
	status.removeEphemeralEffect("damagesoftdigest")
	status.removeEphemeralEffect("displaydamagesoftdigest")
	status.removeEphemeralEffect("displaydamagedigest")

end

function update(dt)
	if world.entityExists(effect.sourceEntity()) and (effect.sourceEntity() ~= -65536) then
		local health = world.entityHealth(entity.id())
		if health[1] > ( 0.01 * dt * self.powerMultiplier) then
			status.modifyResourcePercentage("health", -0.01 * dt * self.powerMultiplier)
		elseif not self.digested then
			self.digested = true
			world.sendEntityMessage(effect.sourceEntity(), "digest", entity.id())
		else
			effect.modifyDuration(1)
			if self.cdt > 1.5 then
				status.modifyResourcePercentage("health", -1 * dt * self.powerMultiplier)
				world.sendEntityMessage(effect.sourceEntity(), "uneat", entity.id())
			else
				self.cdt = self.cdt + dt
			end
		end
	else
		effect.expire()
	end
end

function uninit()

end
