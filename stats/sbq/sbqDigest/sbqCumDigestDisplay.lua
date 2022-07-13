
require("/stats/sbq/sbqEffectsGeneral.lua")


function init()
	script.setUpdateDelta(5)

	self.tickTime = 1.0
	self.cdt = 0 -- cumulative dt
	self.cdamage = 0
	self.digested = false
	self.rpcAttempts = 0
	self.targetTime = 0

	removeOtherBellyEffects()

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
		self.powerMultiplier = status.statusProperty("sbqDigestPower") or 1

		local health = world.entityHealth(entity.id())
		local digestRate = 0.01
		if self.turboDigest then
			digestRate = 0.1
		end

		local damagecalc = status.resourceMax("health") * digestRate * self.powerMultiplier * self.cdt + self.cdamage

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
		elseif self.digested then
			self.turboDigest = false
			self.cdt = self.cdt + dt
			if self.cdt >= self.targetTime then
				doItemDrop()
				mcontroller.resetAnchorState()
				status.modifyResourcePercentage("health", -1)
			else
				status.setResource("health", 1)
			end
		elseif not self.digested then
			self.cdt = 0
			self.digested = true
			self.targetTime = 2
			status.setResource("health", 1)
			world.sendEntityMessage(effect.sourceEntity(), "sbqDigest", entity.id())
		end
	else
		effect.expire()
	end
end

function uninit()

end
