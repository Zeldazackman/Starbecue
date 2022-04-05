
---@diagnostic disable:undefined-global

penis:setChecked(sbq.predatorSettings.penis)
balls:setChecked(sbq.predatorSettings.balls)
symmetricalBalls:setChecked(sbq.predatorSettings.symmetricalBalls)

penisCumTF:setChecked(sbq.predatorSettings.penisCumTF)
ballsCumTF:setChecked(sbq.predatorSettings.ballsCumTF)

function penis:onClick()
	sbq.changePredatorSetting("penis", penis.checked)
end

function balls:onClick()
	sbq.changePredatorSetting("balls", balls.checked)
end

function symmetricalBalls:onClick()
	sbq.changePredatorSetting("balls", symmetricalBalls.checked)
end

function penisCumTF:onClick()
	sbq.changePredatorSetting("penisCumTF", penisCumTF.checked)
end

function ballsCumTF:onClick()
	sbq.changePredatorSetting("ballsCumTF", ballsCumTF.checked)
end
