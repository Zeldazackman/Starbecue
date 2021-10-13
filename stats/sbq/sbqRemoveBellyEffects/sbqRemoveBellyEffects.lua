
require("/stats/sbq/sbqEffectsGeneral.lua")

function init()
	removeOtherBellyEffects("sbqRemoveBellyEffects")
end

function update(dt)
	effect.expire()
end

function uninit()
end
