
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

		if health[1] <= 1 then
			self.turboDigest = false
			status.setResource("health", 1)
			return
		end

		if health[1] > ( digestRate * dt * self.powerMultiplier) then
			status.modifyResourcePercentage("health", -digestRate * dt * self.powerMultiplier)
		end
	else
		effect.expire()
	end
end

function uninit()

end
