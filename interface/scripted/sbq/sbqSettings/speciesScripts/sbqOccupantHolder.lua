---@diagnostic disable: undefined-global

local genderList = {
	noChange = "No Change",
	swap = "Swap",
	random = "Random",
	male = "Male",
	female = "Female"
}
genderSwapButton:setText(genderList[sbq.predatorSettings.TFTG])

sbq.dropdownButton(genderSwapButton, "TFTG", {
	{ "noChange", "No Change" },
	{ "swap", "Swap" },
	{ "random", "Random" },
	{ "male", "Male" },
	{ "female", "Female"}
}, "changePredatorSetting", "overrideSettings")

if sbq.overrideSettings.TFTGEnable == false then
	genderswapPanel:setVisible(false)
end

scaleValue:setVisible(player.hasItem("sbqSizeRay"))
scaleValue:setText(tostring(sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1))
function scaleValue:onEnter()
	local value = tonumber(scaleValue.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.animOverrideOverrideSettings.scale == nil and player.hasItem("sbqSizeRay")
	and (
		(sbq.animOverrideOverrideSettings.scaleMin == nil and sbq.animOverrideOverrideSettings.scaleMax == nil)
		or (sbq.animOverrideOverrideSettings.scaleMin <= value and sbq.animOverrideOverrideSettings.scaleMax == nil)
		or (sbq.animOverrideOverrideSettings.scaleMin == nil and sbq.animOverrideOverrideSettings.scaleMax >= value)
		or (sbq.animOverrideOverrideSettings.scaleMin <= value and sbq.animOverrideOverrideSettings.scaleMax >= value)
	)
	then
		sbq.changeAnimOverrideSetting("scale", value)
	else
		scaleValue:setText(tostring(sbq.animOverrideOverrideSettings.scale or sbq.animOverrideSettings.scale or 1))
	end
end
function scaleValue:onEscape() self:onEnter() end


scaleValueMin:setText(tostring(sbq.animOverrideOverrideSettings.scaleMin or sbq.animOverrideSettings.scaleMin or 0.1))
function scaleValueMin:onEnter()
	local value = tonumber(scaleValueMin.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMin == nil and (value <= 1 or player.hasItem("sbqSizeRay") ) and value > 0 then
		sbq.changeAnimOverrideSetting("scaleMin", value)
	else
		scaleValueMin:setText(tostring(sbq.animOverrideOverrideSettings.scaleMin or sbq.animOverrideSettings.scaleMin or 0.1))
	end
end
function scaleValueMin:onEscape() self:onEnter() end


scaleValueMax:setText(tostring(sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3))
function scaleValueMax:onEnter()
	local value = tonumber(scaleValueMax.text)
	local isNumber = type(value) == "number"
	if isNumber and sbq.animOverrideOverrideSettings.scale == nil and sbq.animOverrideOverrideSettings.scaleMax == nil and (value >= 1 or player.hasItem("sbqSizeRay")) and value > 0 then
		sbq.changeAnimOverrideSetting("scaleMax", value)
	else
		scaleValueMax:setText(tostring(sbq.animOverrideOverrideSettings.scaleMax or sbq.animOverrideSettings.scaleMax or 3))
	end
end
function scaleValueMax:onEscape() self:onEnter() end
