
require("/stats/playablevsoeffects/pvsoEffectsGeneral.lua")


function init()
	script.setUpdateDelta(5)

	self.tickTime = 1.0
	self.cdt = 0 -- cumulative dt
	self.cdamage = 0
	self.powerMultiplier = effect.duration()
	self.digested = false
	self.rpcAttempts = 0
	self.targetTime = 0

	removeOtherBellyEffects("pvsoDisplayDigest")

	message.setHandler("pvsoTurboDigest", function()
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
				--world.sendEntityMessage(effect.sourceEntity(), "uneat", entity.id())
				status.modifyResourcePercentage("health", -1)
			end
		elseif self.rpc == nil then
			self.rpc = world.sendEntityMessage(effect.sourceEntity(), "digest", entity.id())
		elseif self.rpc ~= nil and self.rpc:finished() then
			if self.rpc:succeeded() then
				local result = self.rpc:result()
				if result.success == "success" then
					self.digested = true
					self.targetTime = result.timing
				elseif result.success == "doesn't exist" or result.success == "no data" then
					self.digested = true
				end
			end
			if self.rpcAttempts > 5 then
				self.digested = true
			end
			self.rpc = nil
			self.rpcAttempts = self.rpcAttempts + 1
		end
	else
		effect.expire()
	end
end

function uninit()

end