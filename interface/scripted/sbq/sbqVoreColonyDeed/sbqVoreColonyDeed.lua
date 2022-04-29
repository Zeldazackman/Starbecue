---@diagnostic disable: undefined-global
sbq = {}

require("/scripts/SBQ_RPC_handling.lua")

function init()
	sbq.settings = metagui.inputData.settings

	for setting, value in pairs(sbq.settings) do
		local button = _ENV[setting]
		if button ~= nil then
			button:setChecked(value)
			function button:onClick()
				sbq.changePredatorSetting(setting, button.checked)
			end
		end
	end
end

function update()
	local dt = script.updateDt()
	sbq.checkRPCsFinished(dt)
	sbq.checkTimers(dt)

end

function sbq.changePredatorSetting(settingname, value)
end
