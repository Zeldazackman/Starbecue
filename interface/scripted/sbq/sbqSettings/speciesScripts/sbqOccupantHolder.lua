---@diagnostic disable: undefined-global

TFTGNoChange:selectValue(sbq.predatorSettings.TFTG or "noChange")

function sbq.TFTGButton()
	local value = TFTGNoChange:getGroupChecked().value
	sbq.predatorSettings.TFTG = value
	sbq.saveSettings()
end

function TFTGNoChange:onClick() sbq.TFTGButton() end
function TFTGSwap:onClick() sbq.TFTGButton() end
function TFTGRandom:onClick() sbq.TFTGButton() end
function TFTGMale:onClick() sbq.TFTGButton() end
function TFTGFemale:onClick() sbq.TFTGButton() end

if sbq.overrideSettings.TFTGEnable == false then
	genderswapPanel:setVisible(false)
end
if sbq.overrideSettings.TFTGNoChangeEnable ~= false then
	TFTGNoChange:setVisible(true)
	TFTGNoChangeLabel:setVisible(true)
end
if sbq.overrideSettings.TFTGSwapEnable ~= false then
	TFTGSwap:setVisible(true)
	TFTGSwapLabel:setVisible(true)
end
if sbq.overrideSettings.TFTGRandomEnable ~= false then
	TFTGRandom:setVisible(true)
	TFTGRandomLabel:setVisible(true)
end
if sbq.overrideSettings.TFTGMaleEnable ~= false then
	TFTGMale:setVisible(true)
	TFTGMaleLabel:setVisible(true)
end
if sbq.overrideSettings.TFTGFemaleEnable ~= false then
	TFTGFemale:setVisible(true)
	TFTGFemaleLabel:setVisible(true)
end
