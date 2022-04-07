
---@diagnostic disable:undefined-global

penis:setChecked(sbq.predatorSettings.penis)
balls:setChecked(sbq.predatorSettings.balls)
symmetricalBalls:setChecked(sbq.predatorSettings.symmetricalBalls)
pussy:setChecked(sbq.predatorSettings.pussy)

penisCumTF:setChecked(sbq.predatorSettings.penisCumTF)
ballsCumTF:setChecked(sbq.predatorSettings.ballsCumTF)
wombEggify:setChecked(sbq.predatorSettings.wombEggify)

function penis:onClick()
	sbq.changePredatorSetting("penis", penis.checked)
end

function balls:onClick()
	sbq.changePredatorSetting("balls", balls.checked)
end

function symmetricalBalls:onClick()
	sbq.changePredatorSetting("symmetricalBalls", symmetricalBalls.checked)
end

function pussy:onClick()
	sbq.changePredatorSetting("pussy", pussy.checked)
end

function penisCumTF:onClick()
	sbq.changePredatorSetting("penisCumTF", penisCumTF.checked)
end

function ballsCumTF:onClick()
	sbq.changePredatorSetting("ballsCumTF", ballsCumTF.checked)
end

function wombEggify:onClick()
	sbq.changePredatorSetting("wombEggify", wombEggify.checked)
end
