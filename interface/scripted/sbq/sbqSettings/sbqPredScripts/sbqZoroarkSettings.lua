
---@diagnostic disable:undefined-global

tail:setChecked(sbq.predatorSettings.tail)
tailMaw:setChecked(sbq.predatorSettings.tailMaw)

penis:setChecked(sbq.predatorSettings.penis)
balls:setChecked(sbq.predatorSettings.balls)
breasts:setChecked(sbq.predatorSettings.breasts)

penisCumTF:setChecked(sbq.predatorSettings.penisCumTF)
ballsCumTF:setChecked(sbq.predatorSettings.ballsCumTF)

function tail:onClick()
	sbq.changePredatorSetting("tail", tail.checked)
end

function tailMaw:onClick()
	sbq.changePredatorSetting("tailMaw", tailMaw.checked)
end
function penis:onClick()
	sbq.changePredatorSetting("penis", penis.checked)
end

function balls:onClick()
	sbq.changePredatorSetting("balls", balls.checked)
end

function breasts:onClick()
	sbq.changePredatorSetting("breasts", breasts.checked)
end

function penisCumTF:onClick()
	sbq.changePredatorSetting("penisCumTF", penisCumTF.checked)
end

function ballsCumTF:onClick()
	sbq.changePredatorSetting("ballsCumTF", ballsCumTF.checked)
end
