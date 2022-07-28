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
	local layout = locationPanelScrollArea:addChild({ type = "layout", mode = "vertical", spacing = -1})
	for i, location in ipairs(sbq.predatorConfig.listLocations or {}) do
		local data = sbq.predatorConfig.locations[location] or {}
		layout:addChild({ type = "layout", mode = "horizontal", spacing = -1, children = {
			{ type = "label", text = " "..(data.name or location).." ", align = "right", inline = true, size = {40,10}},
			{
				{ mode = "horizontal" },
				{ type = "checkBox", id = location .. "HammerspaceDisabledButton", checked = not sbq.predatorSettings[location.."HammerspaceDisabled"], visible = (data.hammerspace or false) and sbq.predatorSettings.hammerspace, toolTip = "Enable Hammerspace for the "..(data.name or location) },
				{ type = "iconButton", id = location .. "HammerspaceLocked", image = "/interface/scripted/sbq/sbqVoreColonyDeed/lockedDisabled.png", visible = (not data.hammerspace) and sbq.predatorSettings.hammerspace, toolTip = "The "..(data.name or location).." Can't have hammerspace." },
				{ type = "checkBox", id = location .. "CompressionButton", checked = sbq.predatorSettings[location.."Compression"], visible = sbq.overrideSettings[location .. "Compression"] == nil, toolTip = "Enable compression within "..(data.name or location) },
				{ type = "textBox", id = location .. "VisualMin", toolTip = "Minimum Occupancy"},
				{ type = "textBox", id = location .. "VisualMax", toolTip = "Maximum Occupancy"},
				{ type = "textBox", id = location .. "Multiplier", toolTip = "Occupant Multiplier"}
			},
		} })
		local enableHammerspace = _ENV[location .. "HammerspaceDisabledButton"]

		local visualMin = _ENV[location .. "VisualMin"]
		local visualMax = _ENV[location .. "VisualMax"]
		local multiplier = _ENV[location .. "Multiplier"]

		local compression = _ENV[location .. "CompressionButton"]

		visualMin:setText(tostring(sbq.overrideSettings[location.."VisualMin"] or sbq.predatorSettings[location.."VisualMin"] or 0))
		function visualMin:onEnter()
			local value = tonumber(visualMin.text)
			local isNumber = type(value) == "number"
			if isNumber and sbq.overrideSettings[location.."VisualMin"] == nil
			and value <= (sbq.overrideSettings[location.."VisualMax"] or sbq.predatorSettings[location.."VisualMax"] or data.max or 0 )
			then
				sbq.changePredatorSetting(location.."VisualMin", value)
			else
				visualMin:setText(tostring(sbq.overrideSettings[location.."VisualMin"] or sbq.predatorSettings[location.."VisualMin"] or 0))
			end
		end

		visualMax:setText(tostring(sbq.overrideSettings[location.."VisualMax"] or sbq.predatorSettings[location.."VisualMax"] or 0))
		function visualMax:onEnter()
			local value = tonumber(visualMax.text)
			local isNumber = type(value) == "number"
			if isNumber and sbq.overrideSettings[location.."VisualMax"] == nil
			and value >= (sbq.overrideSettings[location.."VisualMin"] or sbq.predatorSettings[location.."VisualMin"] or data.minVisual or 0 )
			then
				sbq.changePredatorSetting(location.."VisualMax", value)
			else
				visualMax:setText(tostring(sbq.overrideSettings[location.."VisualMax"] or sbq.predatorSettings[location.."VisualMax"] or 0))
			end
		end
		multiplier:setText(tostring(sbq.overrideSettings[location.."Multiplier"] or sbq.predatorSettings[location.."Multiplier"] or 1))
		function multiplier:onEnter()
			local value = tonumber(multiplier.text)
			local isNumber = type(value) == "number"
			if isNumber and sbq.overrideSettings[location.."Multiplier"] == nil then
				sbq.changePredatorSetting(location.."Multiplier", value)
			else
				multiplier:setText(tostring(sbq.overrideSettings[location.."Multiplier"] or sbq.predatorSettings[location.."Multiplier"] or 1))
			end
		end

		function enableHammerspace:onClick()
			if data.sided then
				sbq.predatorSettings[location .. "LHammerspaceDisabled"] = not enableHammerspace.checked
				sbq.predatorSettings[location .. "RHammerspaceDisabled"] = not enableHammerspace.checked
			end
			sbq.predatorSettings[location.."HammerspaceDisabled"] = not enableHammerspace.checked
			sbq.saveSettings()
		end
		function compression:onClick()
			if data.sided then
				sbq.predatorSettings[location .. "LCompression"] = compression.checked
				sbq.predatorSettings[location .. "RCompression"] = compression.checked
			end
			sbq.predatorSettings[location.."Compression"] = compression.checked
			sbq.saveSettings()
		end

	end
end
