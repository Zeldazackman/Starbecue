---@diagnostic disable: undefined-global
local oldinit = init
function init()
	oldinit()

	message.setHandler("sbqLight", function (_,_, light)
		player.setProperty("sbqLight", light)
	end)

	local light = player.getProperty( "sbqLight" )
	if light ~= nil then
		playerext.queueLight(light)
	end
end
