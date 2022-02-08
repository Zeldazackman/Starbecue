---@diagnostic disable: undefined-global
local oldinit = init
local oldupdate = update

function init(...)
	oldinit(...)

	message.setHandler("sbqLight", function (_,_, light)
		player.setProperty("sbqLight", light)
	end)

	localAnimator._clearLightSources = localAnimator.clearLightSources
	localAnimator.clearLightSources = function()
		if player.getProperty( "sbqLight" ) ~= nil then
			sb.logInfo("I'm a little bitch trying to clear the lights but I can't")
			return
		else
			--localAnimator._clearLightSources()
		end
	end
end

function update(dt, ...)
	if oldupdate ~= nil then oldupdate(dt, ...) end

	local light = player.getProperty( "sbqLight" )
	if light ~= nil then
		--localAnimator._clearLightSources()

		sb.logInfo("I am setting the light right now")
		localAnimator.addLightSource(light)
	end
end
