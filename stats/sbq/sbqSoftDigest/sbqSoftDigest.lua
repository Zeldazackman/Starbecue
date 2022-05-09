
require("/stats/sbq/sbqEffectsGeneral.lua")

function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()

	removeOtherBellyEffects("sbqSoftDigest")

	message.setHandler("sbqTurboDigest", function()
		self.turboDigest = true
	end)

end

function update(dt)
	if world.entityExists(effect.sourceEntity()) and (effect.sourceEntity() ~= entity.id()) then
		local health = world.entityHealth(entity.id())
		local digestRate = 0.01
		if self.turboDigest then
			digestRate = 0.1
		end

		if health[1] <= 1 and not self.digested then
			self.turboDigest = false
			self.digested = true
			world.sendEntityMessage(effect.sourceEntity(), "sbqSoftDigest", entity.id())
			status.setResource("health", 1)
			return
		end

		local digestAmount = ( digestRate * dt * self.powerMultiplier)

		if health[1] > ( digestAmount ) and not self.digested then
			world.sendEntityMessage(effect.sourceEntity(), "sbqAddHungerHealth", digestAmount )
			status.modifyResourcePercentage("health", -digestAmount)
		end
	else
		effect.expire()
	end
end

function uninit()

end
