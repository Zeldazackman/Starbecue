
require("/stats/sbq/sbqEffectsGeneral.lua")


function init()
	script.setUpdateDelta(5)

	self.tickTime = 1.0
	self.cdt = 0 -- cumulative dt
	self.cdamage = 0
	self.powerMultiplier = effect.duration()

	removeOtherBellyEffects("sbqDisplaySoftDigest")

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

		local damagecalc = status.resourceMax("health") * digestRate * self.powerMultiplier * self.cdt + self.cdamage

		if health[1] <= 1 then
			self.turboDigest = false
			status.setResource("health", 1)
			return
		end

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
		end
	else
		effect.expire()
	end
end

function uninit()

end
