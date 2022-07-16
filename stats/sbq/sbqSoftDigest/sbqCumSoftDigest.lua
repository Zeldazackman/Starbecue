
require("/stats/sbq/sbqEffectsGeneral.lua")

function init()
	script.setUpdateDelta(5)

	removeOtherBellyEffects()
	self.digested = false

	message.setHandler("sbqTurboDigest", function()
		self.turboDigest = true
	end)

	message.setHandler("sbqDigestResponse", function(_,_, time)
		effect.modifyDuration((time or self.targetTime)+1)
		self.targetTime = time or self.targetTime
		self.dropItem = true
	end)

end

function update(dt)
	if world.entityExists(effect.sourceEntity()) and (effect.sourceEntity() ~= entity.id()) then
		if status.statPositive(config.getParameter("blockingStat")) then
			if not status.statusProperty("sbqPreyEnabled")[config.getParameter("allowSetting")] then return end
		end
		self.powerMultiplier = status.statusProperty("sbqDigestPower") or 1
		local health = world.entityHealth(entity.id())
		local digestRate = 0.01
		if self.turboDigest then
			digestRate = 0.1
		end

		if health[1] <= 1 and not self.digested then
			effect.addStatModifierGroup({
				{stat = "protection", amount = 100},
			})
			self.cdt = 0
			self.targetTime = 2
			effect.modifyDuration(2+1)

			self.turboDigest = false
			self.digested = true
			world.sendEntityMessage(effect.sourceEntity(), "sbqSoftDigest", entity.id())
			status.setResource("health", 1)
			return
		elseif self.digested then
			self.turboDigest = false
			self.cdt = self.cdt + dt
			if self.cdt >= self.targetTime then
				doItemDrop()
			end
			status.setResource("health", 1)
		end

		local digestAmount = ( digestRate * dt * self.powerMultiplier)

		if health[1] > ( digestAmount ) and not self.digested then
			status.modifyResourcePercentage("health", -digestAmount)
		end
	else
		effect.expire()
	end
end

function uninit()

end
