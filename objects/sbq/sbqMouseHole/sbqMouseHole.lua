
require "/scripts/vec2.lua"

function init()
	script.setUpdateDelta(5)
end
local timers = {}
function update(dt)
	for i, time in pairs(timers) do
		timers[i] = math.max(0,time-dt)
	end
	local position = object.position()
	local material = world.material(position, "background")
	local color = world.materialColor(position, "background")
	local hueshift = world.materialHueShift(position, "background")
	animator.setGlobalTag("hueshift", hueshift)
	local materialConfig = root.materialConfig(material)
	if materialConfig then
		local viewCircle = ""
		local viewCircle2 = ""
		local players = world.playerQuery(vec2.add(position, 0.5), 2)
		if players and players[1] ~= nil then
			for i, player in ipairs(players) do
				local velocity = world.entityVelocity(player)
				if math.abs(velocity[1]) > 0.5 or math.abs(velocity[2]) > 0.5 then
					timers[player] = 5
				end
				if type(timers[player]) == "number" and timers[player] > 0 then
					local distance = vec2.mul(vec2.floor(vec2.mul(vec2.add(entity.distanceToEntity(player), { -4, -6 }), 8)),-1)

					viewCircle = viewCircle.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHoleView.png;"..distance[1]..";"..distance[2]
					viewCircle2 = viewCircle2.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHoleView.png;"..(distance[1])..";"..(distance[2]-8)
				end
			end
		end
		local above = world.material(vec2.add(position, { 0, 1 }), "foreground")
		local below = world.material(vec2.add(position, { 0, -1 }), "foreground")
		local left = world.material(vec2.add(position, { -1, 0 }), "foreground")
		local right = world.material(vec2.add(position, { 1, 0 }), "foreground")
		local leftFloor = world.material(vec2.add(position, { -1, -1 }), "foreground")
		local rightFloor = world.material(vec2.add(position, { 1, -1 }), "foreground")

		local objectAbove = world.objectAt(vec2.add(position, { 0, 1 }))
		local objectBelow = world.objectAt(vec2.add(position, { 0, -1 }))
		local objectLeft = world.objectAt(vec2.add(position, { -1, 0 }))
		local objectRight = world.objectAt(vec2.add(position, { 1, 0 }))

		if below then
			local materialConfigBelow = root.materialConfig(below)
			if materialConfigBelow and materialConfigBelow.config.collisionKind == "platform" then
				animator.setAnimationState("coverPlatform", "cover")
			else
				animator.setAnimationState("coverPlatform", "none")
			end
		else
			animator.setAnimationState("coverPlatform", "none")
		end

		local mask = ""
		if not above and (not objectAbove or world.entityName(objectAbove) ~= "sbqMouseHole") then
			mask = mask.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHole.png:up;0;0"
		end

		if not below and (not objectBelow or world.entityName(objectBelow) ~= "sbqMouseHole") then
			mask = mask.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHole.png:down;0;0"
		end

		if not left and (not objectLeft or world.entityName(objectLeft) ~= "sbqMouseHole") then
			if leftFloor then
				mask = mask.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHole.png:left.floor;0;0"
			else
				mask = mask.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHole.png:left.wall;0;0"
			end
		end

		if not right and (not objectRight or world.entityName(objectRight) ~= "sbqMouseHole") then
			if rightFloor then
				mask = mask.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHole.png:right.floor;0;0"
			else
				mask = mask.."?addmask=/objects/sbq/sbqMouseHole/sbqMouseHole.png:right.wall;0;0"
			end
		end

		local renderTemplate = root.assetJson(materialConfig.config.renderTemplate)
		local texture = fixFilepath(materialConfig.config.renderParameters.texture, materialConfig)
		local tileType = "base"
		local imageSize = root.imageSize(texture)
		local data = renderTemplate.pieces[tileType]
		local crop1 = vec2.sub({ data.texturePosition[1], imageSize[2] - data.texturePosition[2] - data.textureSize[2] }, vec2.mul(data.colorStride, color))
		local crop2 = vec2.sub({ data.texturePosition[1] + data.textureSize[1], imageSize[2] - data.texturePosition[2] }, vec2.mul(data.colorStride, color))

		animator.setGlobalTag("materialImage", texture)
		animator.setGlobalTag("mask", mask)
		animator.setGlobalTag( "viewCircle", viewCircle)
		animator.setGlobalTag( "viewCircle2", viewCircle2)
		animator.setGlobalTag( "cropX1", crop1[1])
		animator.setGlobalTag( "cropX2", crop2[1])
		animator.setGlobalTag( "cropY1", crop1[2])
		animator.setGlobalTag( "cropY2", crop2[2])
	end
end

function fixFilepath(string, item)
	if type(string) == "string" then
		if string == "" then return
		elseif string:find("^?") then return
		elseif string:find("^/") then
			return string
		else
			local lastSlash = 1
			local found = item.path:find("/", lastSlash+1)
			while found ~= nil do
				lastSlash = found
				found = item.path:find("/", lastSlash+1)
			end
			return item.path:sub(1,lastSlash)..string
		end
	else
		return
	end
end
