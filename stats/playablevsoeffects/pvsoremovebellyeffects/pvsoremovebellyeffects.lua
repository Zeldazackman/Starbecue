
require("/stats/playablevsoeffects/pvsoEffectsGeneral.lua")

function init()
	removeOtherBellyEffects("pvsoRemoveOtherBellyEffects")
end

function update(dt)
	effect.expire()
end

function uninit()
end
