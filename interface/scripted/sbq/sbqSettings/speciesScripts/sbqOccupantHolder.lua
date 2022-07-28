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

scaleValue:setVisible(player.hasItem("sbqSizeRay"))
scaleValue:setText(tostring(sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1))
function scaleValue:onEnter()
	local value = tonumber(scaleValue.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMin == nil and sbq.animOverrideOverrideSettings.scaleMax == nil
	or isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMin <= value and sbq.animOverrideOverrideSettings.scaleMax == nil
	or isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMin == nil and sbq.animOverrideOverrideSettings.scaleMax >= value
	or isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMin <= value and sbq.animOverrideOverrideSettings.scaleMax >= value
	then
		sbq.changeAnimOverrideSetting("scale", value)
	else
		scaleValue:setText(tostring(sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1))
	end
end

scaleValueMin:setText(tostring(sbq.animOverrideOverrideSettings.scaleMin or sbq.animOverrideSettings.scaleMin or 0.1))
function scaleValueMin:onEnter()
	local value = tonumber(scaleValueMin.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMin == nil then
		sbq.changeAnimOverrideSetting("scaleMin", value)
	else
		scaleValueMin:setText(tostring(sbq.animOverrideOverrideSettings.scaleMin or sbq.animOverrideSettings.scaleMin or 0.1))
	end
end

scaleValueMax:setText(tostring(sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3))
function scaleValueMax:onEnter()
	local value = tonumber(scaleValueMax.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMax == nil then
		sbq.changeAnimOverrideSetting("scaleMax", value)
	else
		scaleValueMax:setText(tostring(sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3))
	end
end
