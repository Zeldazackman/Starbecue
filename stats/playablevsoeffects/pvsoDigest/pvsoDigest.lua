
require("/stats/playablevsoeffects/pvsoEffectsGeneral.lua")


function init()
	self.powerMultiplier = effect.duration()
	self.digested = false
	self.cdt = 0
	self.turboDigest = false
	self.targetTime = 0
	self.rpcAttempts = 0

	removeOtherBellyEffects("pvsoDigest")

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
		if health[1] > ( digestRate * dt * self.powerMultiplier) and not self.digested then
			status.modifyResourcePercentage("health", -digestRate * dt * self.powerMultiplier)
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
