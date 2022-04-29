
local _init = init
local _onInteraction = onInteraction
local _countTags = countTags


function init()
	_init()

	message.setHandler("sbqGetSettings", function (_,_)
	end)

end

function countTags(...)
	local tags = _countTags(...)
	tags["sbqVore"] = 1
end

function onInteraction(args)
	return {"ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:voreColonyDeed" }}
end
