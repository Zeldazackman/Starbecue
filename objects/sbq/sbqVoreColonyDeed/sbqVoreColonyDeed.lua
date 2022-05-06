
local _init = init
local _onInteraction = onInteraction
local _countTags = countTags


function init()
	_init()

	message.setHandler("sbqSaveSettings", function (_,_, settings)
		storage.settings = settings
	end)

	message.setHandler("sbqSavePreySettings", function (_,_, settings)
		storage.preySettings = settings
	end)
	message.setHandler("sbqDeedInteract", function (_,_, args)
		_onInteraction(args)
	end)


end

function countTags(...)
	local tags = _countTags(...)
	tags["sbqVore"] = 1
	return tags
end

function onInteraction(args)
	return {"ScriptPane", { data = storage, gui = { }, scripts = {"/metagui.lua"}, ui = "starbecue:voreColonyDeed" }}
end
