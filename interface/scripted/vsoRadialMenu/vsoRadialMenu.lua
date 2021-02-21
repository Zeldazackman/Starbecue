local settings
local current
local canvas
local options

function init()
	settings = config.getParameter( "settings", {} )
	current = config.getParameter( "current" )
	canvas = widget.bindCanvas( "canvas" )
	widget.focus("canvas")


	options = {{
		name = "settings",
		icon = "/interface/title/modsover.png"
	}}
	if settings and settings.vsos then
		for k, v in pairs(settings.vsos) do
			if k == current then
				table.insert(options, {
					name = "despawn",
					icon = "/interface/bookmarks/icons/beamparty.png"
				})
			elseif v.enabled ~= false then -- treat nil as true
				table.insert(options, {
					name = k,
					icon = "/vehicles/spov/"..k.."/"..k.."icon.png"
				})
			end
		end
	end
end

function radialPoint(theta, radius)
	return {
		100 + radius * math.sin(theta * math.pi/180),
		100 + radius * math.cos(theta * math.pi/180)
	}
end

function generateSegment(size, angle, sides, spacingOffset, inner, outer)
	-- generate points
	local innerpoints = {}
	local outerpoints = {}
	local sideSize = size / sides
	for j = 1, (sides + 1) do
		local sideAngle = angle + sideSize * (j - 1)
		-- add points at *
		--   *---*---* outer
		--   |\ / \ /|
		-- * o-*---*-o inner
		table.insert(innerpoints, radialPoint(sideAngle - sideSize/2, inner))
		table.insert(outerpoints, radialPoint(sideAngle, outer))
	end
	-- fix end points at o
	innerpoints[1] = radialPoint(angle + spacingOffset, inner)
	table.insert(innerpoints, radialPoint(angle + size - spacingOffset, inner))

	-- generate tris
	-- 1---2---3 outer
	-- |\ / \ /|
	-- 1-2---3-3 inner
	local tris = {}
	table.insert(tris, {innerpoints[1], outerpoints[1], innerpoints[2]})
	for j = 2, (sides + 1) do
		table.insert(tris, {outerpoints[j - 1], innerpoints[j], outerpoints[j]})
		table.insert(tris, {innerpoints[j], outerpoints[j], innerpoints[j + 1]})
	end
	return tris
end

function update( dt )

	if options == nil then return end
	
	local segments = #options
	local segmentSpacing = 3
	local spacingOffset = 1 -- difference from segmentSpacing
	local sidesPerSegment
	local innerRadius
	if segments <= 6 then
		sidesPerSegment = 10
		innerRadius = 20
	elseif segments <= 10 then
		sidesPerSegment = 5
		innerRadius = 40
	else
		sidesPerSegment = 2
		innerRadius = 70
		spacingOffset = 0.5
	end
	local segmentSize = 360 / segments
	local iconRadius = innerRadius + 10
	local outerRadius = innerRadius + 20

	-- mouse handling
	local mpos = canvas:mousePosition()
	mpos = {mpos[1] - 100, mpos[2] - 100} -- move (0, 0) to center instead of corner
	local mouseAngle = math.atan(mpos[1], mpos[2]) * 180/math.pi + 180
	local activeSegment = (math.floor(mouseAngle / segmentSize + 0.5) + segments) % segments + 1
	sb.setLogMap("activeSegment", activeSegment)

	-- drawing
	canvas:clear()
	local tris = {}
	local activeTris = {}
	for i = 1, segments do
		local segmentAngle = segmentSize * (i - 1.5) + segmentSpacing / 2 + 180
		local r1, r2, ri, color
		if i == activeSegment then
			r1 = innerRadius + 5
			r2 = outerRadius + 10
			ri = iconRadius + 7.5
			color = {200, 220, 240, 200}
		else
			r1 = innerRadius
			r2 = outerRadius
			ri = iconRadius
			color = {190, 200, 210, 100}
		end
		canvas:drawTriangles(
			generateSegment(segmentSize - segmentSpacing, segmentAngle, sidesPerSegment, spacingOffset, r1, r2),
			color
		)
		canvas:drawImage(options[i].icon, radialPoint(segmentSize * (i - 1) + 180, ri), nil, nil, true)
	end

	-- save selection
	if settings.selected ~= options[activeSegment].name then
		settings.selected = options[activeSegment].name
		player.setProperty( "vsoSettings", settings )
	end
end