function init()
	script.setUpdateDelta(5)

	self.tickTime = 1.0
	self.cdt = 0 -- cumulative dt
	self.cdamage = 0
	self.powerMultiplier = effect.duration()
	self.digested = false

	status.removeEphemeralEffect("pvsovoreheal")
	status.removeEphemeralEffect("damagedigest")
	status.removeEphemeralEffect("damagesoftdigest")
	status.removeEphemeralEffect("displaydamagesoftdigest")

end

function update(dt)
	if world.entityExists(effect.sourceEntity()) then
		local health = world.entityHealth(entity.id())
		local damagecalc = status.resourceMax("health") * 0.01 * self.powerMultiplier * self.cdt + self.cdamage

		if health[1] > damagecalc then

			self.cdt = self.cdt + dt
			--if self.cdt < self.tickTime then return end -- wait until at least 1 second has passed

			if damagecalc < 1 then return end -- wait until at least 1 damage will be dealt

			self.cdt = 0
			self.cdamage = damagecalc % 1
			status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = math.floor(damagecalc),
				damageSourceKind = "poison",
				sourceEntityId = entity.id()
			})
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
