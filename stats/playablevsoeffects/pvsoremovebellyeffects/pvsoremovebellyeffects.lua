
require("/stats/playablevsoeffects/pvsoEffectsGeneral.lua")

function init()
	removeOtherBellyEffects("pvsoRemoveBellyEffects")
end

function update(dt)
	effect.expire()
end

function uninit()
end
