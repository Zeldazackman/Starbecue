local oldinit = init
local oldupdate = update
local olduninit = uninit

function init()
	oldinit()
end

function update(dt)
	oldupdate(dt)
end

function uninit()
	olduninit()
end
