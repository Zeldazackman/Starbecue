function uninit()
	for i, id in ipairs(world.entityQuery(mcontroller.position(), 2) or {}) do
		world.sendEntityMessage(id, "animOverrideScale", config.getParameter("animOverrideScale") or 1, config.getParameter("animOverrideScaleDuration") or 1 )
	end
end
