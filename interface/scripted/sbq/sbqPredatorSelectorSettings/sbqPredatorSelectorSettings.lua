---@diagnostic disable:undefined-global

sbq = {
	sbqSettings = player.getProperty("sbqSettings") or {}
}

for name, data in pairs(sbq.sbqSettings.types) do
	local name = name
	local predPanel = predatorScrollArea:addChild({ type = "panel", id = name.."Panel", style = "convex", mode = "horizontal", children = {
		{ type = "image", file = "/vehicles/sbq/"..name.."/skins/"..((sbq.sbqSettings[name].skinNames or {}).head or "default").."/icon.png"..(sbq.sbqSettings[name].directives or "")},
		{ type = "panel", id = name.."Layout", style = "concave", mode = "vertical", children = {
			{ type = "label", inline = true, text = name:gsub("^sbq", "")},
			{ type = "layout", id = name.."Layout2", mode = "horizontal", children = {
				{ type = "checkBox", id = name.."checkBox", checked = data.enable ~= false, toolTip = "Enable or disable pred appearing on selection wheel"},
				{ type = "iconButton", id = name.."prev", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png", toolTip = "Priority of appearance on selection wheel (clockwise from bottom)"},
				{ type = "label", id = name.."label", text = tostring(data.index)},
				{ type = "iconButton", id = name.."next", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png", toolTip = "Priority of appearance on selection wheel (clockwise from bottom)"}
			}}
		}}
	}})

	local checkBox = _ENV[name.."checkBox"]
	local prev = _ENV[name.."prev"]
	local label = _ENV[name.."label"]
	local next = _ENV[name.."next"]

	function checkBox:onClick()
		sbq.togglePred(name, checkBox)
	end
	function prev:onClick()
		sbq.adjustPredPriority(name, label, -1)
	end
	function next:onClick()
		sbq.adjustPredPriority(name, label, 1)
	end
end

function sbq.togglePred(name, checkBox)
	sbq.sbqSettings.types[name].enable = checkBox.checked
	sb.logInfo(tostring(checkBox.checked))

	player.setProperty("sbqSettings", sbq.sbqSettings)
	world.sendEntityMessage(player.id(), "sbqRefreshSettings", sbq.sbqSettings)
end

function sbq.adjustPredPriority(name, label, inc)
	sbq.sbqSettings.types[name].index = math.max(1, (sbq.sbqSettings.types[name].index or 1) + inc)
	label:setText(tostring(sbq.sbqSettings.types[name].index))

	player.setProperty("sbqSettings", sbq.sbqSettings)
	world.sendEntityMessage(player.id(), "sbqRefreshSettings", sbq.sbqSettings)
end
