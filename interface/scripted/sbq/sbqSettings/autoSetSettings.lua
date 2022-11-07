
function sbq.autoSetSettings(settingname, value)
	local autoSettings = (((sbq.predatorConfig.autoSetSettings or {})[settingname] or {})[tostring(value)])
	for newSetting, newValue in pairs(autoSettings or {}) do
		sbq.predatorSettings[newSetting] = newValue
		if type(newValue) == "boolean" then
			local button = _ENV[newSetting]
			if button ~= nil then
				button:setChecked(newValue)
			end
		end
	end
end
