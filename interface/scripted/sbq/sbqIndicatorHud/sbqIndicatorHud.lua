local owner
local buttons
local progress
local indicator
local time = 0

local colors = {
	-- color = {dark, light}
	default = {"404040", "6a6a6a"},
	white = {"8e8e8e", "ffffff"},
	black = {"404040", "000000"}, -- 'light' is actually darker here, for contrast
	red = {"6d0000", "b60000"},
	orange = {"764100", "d17300"},
	yellow = {"7c7100", "ddc900"},
	lime = {"467700", "76c800"},
	green = {"006200", "00b000"},
	cyan = {"007676", "00bebe"},
	teal = {"005290", "0072cb"},
	blue = {"262693", "3333ff"},
	purple = {"412693", "5c2de8"},
	violet = {"66009c", "8e00d9"},
	magenta = {"880088", "c500c5"},
}

local directions = { -- coordinates within indicator.png, measured from the *bottom*
	up = {42, 17, 49, 28},
	down = {42, 3, 49, 14},
	left = {33, 12, 44, 19},
	right = {47, 12, 58, 19},
	interact = {52, 22, 59, 29},
	special1 = {52, 2, 59, 9},
	special2 = {32, 2, 39, 9},
	special3 = {32, 22, 39, 29},
-- these ones could potentially be used, but aren't in the current layout
	-- space = {1, 1, 25, 7},
	-- primaryFire = {1, 35, 12, 41},
	-- secondaryFire = {14, 35, 25, 41},
	-- shift (only works if you're holding the controller)
}

local bar = {
	empty = "/interface/scripted/sbq/barempty.png",
	full = "/interface/scripted/sbq/barfull.png",
	x = 0, y = 34, h = 5, w = 61,
	color = {"9e9e9e", "c4c4c4", "e4e4e4", "ffffff"}, -- defaults in barfull.png
}

function replace(from, to)
	if to == nil or #to == 0 then return "" end
	local directive = "?replace;"
	for i, f in ipairs(from) do
		directive = directive .. f .. "=" .. to[i] .. ";"
	end
	return directive
end

function init()
	owner = config.getParameter( "owner" )
	buttons = config.getParameter( "directions" )
	progress = config.getParameter( "progress" )
	time = config.getParameter( "time" )
	location = config.getParameter( "location" )
	if not owner or not world.entityExists( owner ) or player.loungingIn() ~= owner then
		pane.dismiss() -- nothing to indicate?
	end

	indicator = widget.bindCanvas( "indicator" )

	update(0)
end

function update( dt )

	if not owner or not world.entityExists( owner ) or player.loungingIn() ~= owner then
		pane.dismiss()
		return
	end

	-- drawing
	indicator:clear()

	-- buttons
	for dir, color in pairs(buttons) do
		if directions[dir] then
			indicator:drawImageRect(
				"/interface/scripted/sbq/sbqIndicatorHud/indicator.png"
					.. replace(colors.default, colors[color]),
				directions[dir], directions[dir]
			)
		end
	end

	-- bar
	local s = (progress.percent or 0) / 100 * bar.w
	if progress.active then
		progress.percent = progress.percent + progress.dx * dt
	end
	if s < bar.w then
		indicator:drawImageRect(
			bar.empty,
			{s, 0, bar.w, bar.h},
			{bar.x + s, bar.y, bar.x + bar.w, bar.y + bar.h}
		)
	end
	if s > 0 then
		indicator:drawImageRect(
			bar.full .. replace(bar.color, progress.color),
			{0, 0, s, bar.h},
			{bar.x, bar.y, bar.x + s, bar.y + bar.h}
		)
	end

	-- time
	local hours = 1 -- if >1h, show hh:mm instead of mm:ss (not enough space for hh:mm:ss)
	if time/60 > 60 then hours = 60 end
	indicator:drawText(
		tostring(math.floor(time/60/hours/10)),
		{position = {10, 9}, horizontalAnchor = "right"},
		8, {127, 127, 127}
	)
	indicator:drawText(
		tostring(math.floor(time/60/hours%10)),
		{position = {15, 9}, horizontalAnchor = "right"},
		8, {127, 127, 127}
	)
	if time%2 < 1 then -- flash : for seconds
		indicator:drawText(
			":",
			{position = {17, 9}, horizontalAnchor = "right"},
			8, {127, 127, 127}
		)
	end
	indicator:drawText(
		tostring(math.floor(time/hours/10%6)),
		{position = {22, 9}, horizontalAnchor = "right"},
		8, {127, 127, 127}
	)
	indicator:drawText(
		tostring(math.floor(time/hours%10)),
		{position = {27, 9}, horizontalAnchor = "right"},
		8, {127, 127, 127}
	)
	time = time + dt

	-- location
	indicator:drawText(
		location,
		{position = {16, 29}, horizontalAnchor = "mid", wrapWidth = 25},
		8, {127, 127, 127}
	)
end

function uninit()
	if owner and world.entityExists(owner) then
		world.sendEntityMessage(owner, "indicatorClosed", player.id())
	end
end
