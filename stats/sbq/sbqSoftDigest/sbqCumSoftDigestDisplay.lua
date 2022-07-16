
require("/stats/sbq/sbqEffectsGeneral.lua")


function init()
	script.setUpdateDelta(5)

	self.tickTime = 1.0
	self.cdt = 0 -- cumulative dt
	self.cdamage = 0
	self.digested = false

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
		if status.statPositive(config.getParameter("blockingStat")) then
			if not status.statusProperty("sbqPreyEnabled")[config.getParameter("allowSetting")] then return end
		end

		self.powerMultiplier = status.statusProperty("sbqDigestPower") or 1

		local health = world.entityHealth(entity.id())
		local digestRate = 0.01
		if self.turboDigest then
			digestRate = 0.1
		end

		local damagecalc = status.resourceMax("health") * digestRate * self.powerMultiplier * self.cdt + self.cdamage

		if self.digested then
			self.turboDigest = false
			self.cdt = self.cdt + dt
			if self.cdt >= self.targetTime then
				doItemDrop()
			end
			status.setResource("health", 1)
		elseif health[1] <= 1 then
			effect.addStatModifierGroup({
				{stat = "protection", amount = 100},
			})
			self.cdt = 0
			self.targetTime = 2
			effect.modifyDuration(2+1)

			self.turboDigest = false
			self.digested = true
			status.setResource("health", 1)
			world.sendEntityMessage(effect.sourceEntity(), "sbqSoftDigest", entity.id())

		elseif health[1] > damagecalc then

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
