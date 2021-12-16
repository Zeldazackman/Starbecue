function init()
end

function update(dt)
	local scale = status.statusProperty("sbqScaling") or {}
	effect.setParentDirectives("scalenearest="..(scale[1] or 1)..";"..(scale[2] or 1))
end

function uninit()
end
