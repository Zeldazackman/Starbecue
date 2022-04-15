
local _init = init
function init()
	_init()

	message.setHandler("sbqGetSettings", function (_,_)
	end)

end

local _onInteraction = onInteraction

function onInteraction(args)
	return {"ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:voreColonyDeed" }}
end
