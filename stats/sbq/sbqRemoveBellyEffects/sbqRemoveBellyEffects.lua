
require("/stats/sbq/sbqEffectsGeneral.lua")

function init()
	removeOtherBellyEffects()
end

function update(dt)
	effect.expire()
end

function uninit()
end
