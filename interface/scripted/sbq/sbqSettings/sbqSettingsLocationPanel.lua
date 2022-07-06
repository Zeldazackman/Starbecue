---@diagnostic disable:undefined-global

function sbq.locationPanel()
	locationPanelScrollArea:clearChildren()
	if not sbq.predatorConfig or not sbq.predatorConfig.locations then return end
	if sbq.predatorSettings.lockLocationPanel then return end
	for location, data in pairs(sbq.predatorConfig.locations) do
		if sbq.predatorSettings[location.."VisualMax"] == nil then
			sbq.predatorSettings[location.."VisualMax"] = data.max or 0
			sbq.saveSettings()
		end
	end
	local layout
	if sbq.predatorSettings.hammerspace then
		layout = locationPanelScrollArea:addChild({ type = "layout", mode = "vertical", spacing = -1})
	else
		layout = locationPanelScrollArea:addChild({ type = "layout", mode = "vertical" })
	end
	for i, location in ipairs(sbq.predatorConfig.listLocations or {}) do

		local data = sbq.predatorConfig.locations[location] or {}
		layout:addChild({ type = "layout", mode = "horizontal", children = {
			{ type = "checkBox", id = location .. "HammerspaceDisabled", checked = not sbq.predatorSettings[location.."HammerspaceDisabled"], visible = (data.hammerspace or false) and sbq.predatorSettings.hammerspace, toolTip = "Enable Hammerspace for the "..(data.name or location) },
			{ type = "iconButton", id = location .. "Locked", image = "/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png", visible = (not data.hammerspace) and sbq.predatorSettings.hammerspace, toolTip = "The "..(data.name or location).." Can't have hammerspace, but you can change the min and max size" },

			{ type = "iconButton", id = location .. "PrevMin", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png", toolTip = "Decrease the min size of the "..(data.name or location) },
			{ type = "label", id = location .. "ValueMin", text = sbq.predatorSettings[location.."VisualMin"] or data.minVisual or 0, inline = true },
			{ type = "iconButton", id = location .. "NextMin", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png", toolTip = "Increase the min size of the "..(data.name or location) },

			{ type = "iconButton", id = location .. "PrevMax", image = "/interface/pickleft.png", hoverImage = "/interface/pickleftover.png", toolTip = "Decrease the max size of the "..(data.name or location) },
			{ type = "label", id = location .. "ValueMax", text = sbq.predatorSettings[location.."VisualMax"] or 1, inline = true },
			{ type = "iconButton", id = location .. "NextMax", image = "/interface/pickright.png", hoverImage = "/interface/pickrightover.png", toolTip = "Increase the max size of the "..(data.name or location) },

			{ type = "label", text = (data.name or location), inline = true }
		} })
		local enableHammerspace = _ENV[location .. "HammerspaceDisabled"]

		local prevMax = _ENV[location .. "PrevMax"]
		local labelMax = _ENV[location .. "ValueMax"]
		local nextMax = _ENV[location .. "NextMax"]

		local prevMin = _ENV[location .. "PrevMin"]
		local labelMin = _ENV[location .. "ValueMin"]
		local nextMin = _ENV[location .. "NextMin"]

		function enableHammerspace:onClick()
			if data.sided then
				sbq.predatorSettings[location .. "LHammerspaceDisabled"] = not enableHammerspace.checked
				sbq.predatorSettings[location .. "RHammerspaceDisabled"] = not enableHammerspace.checked
			end
			sbq.predatorSettings[location.."HammerspaceDisabled"] = not enableHammerspace.checked
			sbq.saveSettings()
		end

		function prevMax:onClick()
			if data.sided then
				sbq.changeLocationMax(location .. "L", -1, labelMax, labelMin)
				sbq.changeLocationMax(location .. "R", -1, labelMax, labelMin)
			end
			sbq.changeLocationMax(location, -1, labelMax, labelMin)
		end
		function nextMax:onClick()
			if data.sided then
				sbq.changeLocationMax(location .. "L", 1, labelMax, labelMin)
				sbq.changeLocationMax(location .. "R", 1, labelMax, labelMin)
			end
			sbq.changeLocationMax(location, 1, labelMax, labelMin)
		end

		function prevMin:onClick()
			if data.sided then
				sbq.changeLocationMin(location .. "L", -1, labelMin, labelMax)
				sbq.changeLocationMin(location .. "R", -1, labelMin, labelMax)
			end
			sbq.changeLocationMin(location, -1, labelMin, labelMax)
		end
		function nextMin:onClick()
			if data.sided then
				sbq.changeLocationMin(location .. "L", 1, labelMin, labelMax)
				sbq.changeLocationMin(location .. "R", 1, labelMin, labelMax)
			end
			sbq.changeLocationMin(location, 1, labelMin, labelMax)
		end
	end
end

function sbq.changeLocationMax(location, inc, labelMax, labelMin)
	local newValue = (sbq.predatorSettings[location.."VisualMax"] or 0) + inc
	if newValue < (sbq.predatorConfig.locations[location].minVisual or 0) then return
	elseif newValue > (sbq.predatorConfig.locations[location].max or 0) then return
	elseif type(sbq.predatorSettings[location.."VisualMin"]) == "number" and newValue < (sbq.predatorSettings[location.."VisualMax"]) then
		sbq.predatorSettings[location.."VisualMin"] = newValue
		labelMin:setText(newValue)
	end

	labelMax:setText(newValue)
	sbq.predatorSettings[location.."VisualMax"] = newValue
	sbq.saveSettings()
end

function sbq.changeLocationMin(location, inc, labelMin, labelMax)
	local newValue = (sbq.predatorSettings[location.."VisualMin"] or 0) + inc
	if newValue < (sbq.predatorConfig.locations[location].minVisual or 0) then return
	elseif newValue > (sbq.predatorConfig.locations[location].max or 0) then return
	elseif type(sbq.predatorSettings[location.."VisualMax"]) == "number" and newValue > (sbq.predatorSettings[location.."VisualMax"]) then
		sbq.predatorSettings[location.."VisualMax"] = newValue
		labelMax:setText(newValue)
	end

	labelMin:setText(newValue)
	sbq.predatorSettings[location.."VisualMin"] = newValue
	sbq.saveSettings()
end
