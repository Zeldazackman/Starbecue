---@diagnostic disable: undefined-global
local oldinit = init
local oldupdate = update

function init(...)
	oldinit(...)

	message.setHandler("sbqLight", function (_,_, light)
		player.setProperty("sbqLight", light)
	end)

end

function update(dt, ...)
	if oldupdate ~= nil then oldupdate(dt, ...) end

	local light = player.getProperty( "sbqLight" )
	if light ~= nil then
		localAnimator.addLightSource(light)
	end
end
