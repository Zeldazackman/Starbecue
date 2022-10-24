function sbq.handleUnderwear()
end

function sbq.handleBodyParts()
	local defaultSbqData = sbq.defaultSbqData
	if sbq.settings.penis then
		sbq.setStatusValue( "cockVisible", "")
		sbq.sbqData.locations.shaft.max = defaultSbqData.locations.shaft.max
	else
		sbq.setStatusValue( "cockVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.shaft.max = 0
	end
	if sbq.settings.balls then
		sbq.setStatusValue( "ballsVisible", "")
		sbq.sbqData.locations.ballsL.max = defaultSbqData.locations.balls.max
		sbq.sbqData.locations.ballsR.max = defaultSbqData.locations.balls.max
	else
		sbq.setStatusValue( "ballsVisible", "?crop;0;0;0;0")
		sbq.sbqData.locations.ballsL.max = 0
		sbq.sbqData.locations.ballsR.max = 0
	end
	if sbq.settings.pussy then
		sbq.setStatusValue( "pussyVisible", "")
	else
		sbq.setStatusValue( "pussyVisible", "?crop;0;0;0;0")
	end
end
