
require("/stats/sbq/sbqEffectsGeneral.lua")


function init()
	self.powerMultiplier = effect.duration()
	self.digested = false
	self.cdt = 0
	self.turboDigest = false
	self.targetTime = 0
	self.rpcAttempts = 0

	removeOtherBellyEffects("sbqDigest")

	message.setHandler("sbqTurboDigest", function()
		self.turboDigest = true
	end)

	message.setHandler("sbqDigestResponse", function(time)
		effect.modifyDuration((time or self.targetTime)+1)
		self.targetTime = time or self.targetTime
	end)

end

function update(dt)
	if world.entityExists(effect.sourceEntity()) and (effect.sourceEntity() ~= entity.id()) then
		local health = world.entityHealth(entity.id())
		local digestRate = 0.01
		if self.turboDigest then
			digestRate = 0.1
		end
		local digestAmount = ( digestRate * dt * self.powerMultiplier)
		if health[1] > digestAmount and not self.digested then
			world.sendEntityMessage(effect.sourceEntity(), "sbqAddHungerHealth", digestAmount )
			status.modifyResourcePercentage("health", -digestAmount)
		elseif self.digested then
			self.turboDigest = false
			self.cdt = self.cdt + dt
			if self.cdt >= self.targetTime then
				mcontroller.resetAnchorState()
				status.modifyResourcePercentage("health", -1)
			else
				status.setResource("health", 1)
			end
		elseif not self.digested then
			self.cdt = 0
			self.digested = true
			self.targetTime = 2
			effect.modifyDuration(2+1)
			status.setResource("health", 1)
			world.sendEntityMessage(effect.sourceEntity(), "sbqDigest", entity.id())
		end
	else
		effect.expire()
	end
end

function uninit()

end
