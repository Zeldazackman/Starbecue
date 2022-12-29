
require("/stats/sbq/sbqEffectsGeneral.lua")

function init()
	script.setUpdateDelta(5)
	self.powerMultiplier = effect.duration()
	self.digested = false
	self.cdt = 0
	removeOtherBellyEffects()

end

function update(dt)
	self.powerMultiplier = (status.statusProperty("sbqDigestData") or {}).power or 1
	status.modifyResourcePercentage("health", 0.01 * dt * self.powerMultiplier)
end

function uninit()

end
