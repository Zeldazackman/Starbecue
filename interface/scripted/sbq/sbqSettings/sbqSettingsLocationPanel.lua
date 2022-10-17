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

		visualMin:setText(tostring(sbq.overrideSettings[location .. "VisualMin"] or sbq.predatorSettings[location ..
			"VisualMin"] or 0))
		visualMin.toolTip = "Minimum fullness (Min of " ..
			(sbq.overrideSettings[location .. "VisualMin"] or data.minVisual or 0) .. ")"

		local color = "00FF00"
		if (sbq.predatorSettings[location.."VisualMin"] or 0) >= (sbq.overrideSettings[location.."VisualMax"] or data.max or math.huge) then
			color = "FF0000"
		end
		visualMin:setColor(color)

		function visualMin:onEnter()
			local value = tonumber(visualMin.text)
			local isNumber = type(value) == "number"
			if isNumber and sbq.overrideSettings[location.."VisualMin"] == nil then
				local newValue = math.min( sbq.overrideSettings[location.."VisualMax"] or sbq.predatorSettings[location.."VisualMax"] or math.huge, math.max(value, ( sbq.overrideSettings[location.."VisualMin"] or data.minVisual or 0 ) ), (sbq.overrideSettings[location.."VisualMax"] or data.max or math.huge))
				sbq.predatorSettings[location.."VisualMin"] = newValue
				if data.sided then
					sbq.predatorSettings[location.."LVisualMin"] = newValue
					sbq.predatorSettings[location.."RVisualMin"] = newValue
				end
				local color = "00FF00"
				if newValue >= (sbq.overrideSettings[location.."VisualMax"] or data.max or math.huge) then
					color = "FF0000"
				end
				visualMin:setColor(color)

				sbq.saveSettings()
			else
				visualMin:setText(tostring(sbq.overrideSettings[location.."VisualMin"] or sbq.predatorSettings[location.."VisualMin"] or 0))
			end
		end

		visualMax:setText(tostring(sbq.overrideSettings[location .. "VisualMax"] or sbq.predatorSettings[location .."VisualMax"] or data.max or 0))
		visualMax.toolTip = "Maximum fullness (Max of "..(sbq.overrideSettings[location.."VisualMax"] or data.max)..")\nIf Hammerspace is on, this only controls the visuals"
		local color = "00FF00"
		if (sbq.predatorSettings[location.."VisualMax"] or sbq.overrideSettings[location.."VisualMax"] or data.max) >= (sbq.overrideSettings[location.."VisualMax"] or data.max or math.huge) then
			color = "FF0000"
		end
		visualMax:setColor(color)

		function visualMax:onEnter()
			local value = tonumber(visualMax.text)
			local isNumber = type(value) == "number"
			if isNumber and sbq.overrideSettings[location.."VisualMax"] == nil then
				local newValue = math.min(math.max(sbq.overrideSettings[location.."VisualMin"] or sbq.predatorSettings[location.."VisualMin"] or 0, value, ( sbq.overrideSettings[location.."VisualMin"] or data.minVisual or 0 ) ), (sbq.overrideSettings[location.."VisualMax"] or data.max or math.huge))
				sbq.predatorSettings[location.."VisualMax"] = newValue
				if data.sided then
					sbq.predatorSettings[location.."LVisualMax"] = newValue
					sbq.predatorSettings[location.."RVisualMax"] = newValue
				end
				local color = "00FF00"
				if newValue >= (sbq.overrideSettings[location.."VisualMax"] or data.max or math.huge) then
					color = "FF0000"
				end
				visualMax:setColor(color)

				sbq.saveSettings()
			else
				visualMax:setText(tostring(sbq.overrideSettings[location.."VisualMax"] or sbq.predatorSettings[location.."VisualMax"] or 0))
			end
		end
		multiplier:setText(tostring(sbq.overrideSettings[location.."Multiplier"] or sbq.predatorSettings[location.."Multiplier"] or 1))
		function multiplier:onEnter()
			local value = tonumber(multiplier.text)
			local isNumber = type(value) == "number"
			if isNumber and sbq.overrideSettings[location.."Multiplier"] == nil then
				sbq.predatorSettings[location.."Multiplier"] = value
				if data.sided then
					sbq.predatorSettings[location.."LMultiplier"] = value
					sbq.predatorSettings[location.."RMultiplier"] = value
				end
				sbq.saveSettings()
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
