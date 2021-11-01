sbq = {
	sbqSettings = player.getProperty("sbqSettings") or {}
}

for name, data in pairs(sbq.sbqSettings.types) do
	local predPanel = predatorScrollArea:addChild({ type = "panel", id = name.."Panel", style = "convex", size = {96, 16}, mode = "horizontal", children = {}})
	predPanel:addChild({ type = "image", file = "/vehicles/sbq/"..name.."/skins/"..((sbq.sbqSettings[name].skinNames or {}).head or "default").."/icon.png"..(sbq.sbqSettings[name].directives or "")})

	local predLayout = predPanel:addChild({ type = "layout", id = name.."Layout", mode = "vertical", children = {}})

	predLayout:addChild({ type = "label", text = name:gsub("^sbq", "")})

	local predLayout2 = predLayout:addChild({ type = "layout", id = name.."Layout2", mode = "horizontal", children = {}})

	local checkBox = predLayout2:addChild({ type = "checkBox", id = name.."checkBox", checked = data.enabled or data.enabled == nil, toolTip = "Enable or disable pred appearing on selection wheel"})
	function checkBox:onClick()
		sbq.togglePred(name, checkBox)
	end

	local prev = predLayout2:addChild({ type = "iconButton", id = name.."prev", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png", toolTip = "Priority of appearance on selection wheel (clockwise from bottom)"})
	local label = predLayout:addChild({ type = "label", id = name.."label", text = tostring(data.index)})
	local next = predLayout2:addChild({ type = "iconButton", id = name.."next", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png", toolTip = "Priority of appearance on selection wheel (clockwise from bottom)"})

	function prev:onClick()
		sbq.adjustPredPriority(name, label, -1)
	end
	function next:onClick()
		sbq.adjustPredPriority(name, label, 1)
	end

end

function sbq.togglePred(name, checkBox)
	sbq.sbqSettings.types[name].enable = checkBox.checked

	player.setProperty("sbqSettings", sbq.settings)
	world.sendEntityMessage(player.id(), "sbqRefreshSettings", sbq.settings)
end

function sbq.adjustPredPriority(name, label, inc)
	sbq.sbqSettings.types[name].index = math.max(1, (sbq.sbqSettings.types[name].index or 1) + inc)
	label:setText(tostring(sbq.sbqSettings.types[name].index))

	player.setProperty("sbqSettings", sbq.settings)
	world.sendEntityMessage(player.id(), "sbqRefreshSettings", sbq.settings)
end
