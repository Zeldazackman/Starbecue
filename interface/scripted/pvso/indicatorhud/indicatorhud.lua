local owner
local data
local indicator

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
	up = {10, 23, 16, 33},
	down = {10, 9, 16, 19},
	left = {1, 18, 11, 24},
	right = {15, 18, 25, 24},
	interact = {18, 26, 25, 33},
	special1 = {1, 26, 8, 33},
	special2 = {1, 9, 8, 16},
	special3 = {18, 9, 25, 16},
	space = {1, 1, 25, 7},
	primaryFire = {1, 35, 12, 41},
	secondaryFire = {14, 35, 25, 41},
}

function init()
	owner = config.getParameter( "owner" )
	data = config.getParameter( "directions" )
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

	-- indicator:drawRect({0, 0, 26, 42}, {255, 255, 255})
	-- indicator:drawImage("/interface/scripted/pvso/indicatorhud/indicator.png", {0, 0})

	sb.setLogMap("indicator", sb.print(data))

	for dir, color in pairs(data) do
		if directions[dir] then
			indicator:drawImageRect(
				"/interface/scripted/pvso/indicatorhud/indicator.png?replace;"
					.. colors.default[1] .. "=" .. colors[color][1] .. ";"
					.. colors.default[2] .. "=" .. colors[color][2],
				directions[dir], directions[dir]
			)
		end
	end
end

function uninit()
	if owner and world.entityExists(owner) then
		world.sendEntityMessage(owner, "indicatorClosed", player.id())
	end
end