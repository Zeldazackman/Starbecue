
require("/stats/sbq/sbqEffectsGeneral.lua")

function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()
	self.cdt = 0

	removeOtherBellyEffects("sbqHealDisplay")

end

function update(dt)
	status.modifyResourcePercentage("health", 0.01 * dt * self.powerMultiplier)
end

function uninit()

end