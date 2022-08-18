
require "/scripts/vec2.lua"

function init()
	script.setUpdateDelta(5)
end
local timers = {}
local size = { 5, 3 }
local materials = {}
local colors = {}
local blockImages = {}
local blockViewMasks = {}
function update()
	local dt = script.updateDt()
	local position = objectAnimator.position()

	for i, time in pairs(timers) do
		timers[i] = math.max(0,time-dt)
	end
	playerViewCircle(position)
	setMaterials(position)
end

function setMaterials(position)
	localAnimator.clearDrawables()
	local width = size[1]
	local height = size[2]
	for x = 0, width-1 do
		for y = -height + 1, 0 do

			local position = vec2.add(position, {x,y})
			local material = world.material(position, "background")
			local color = world.materialColor(position, "background")
			local part = "block"..x.."_"..y
			if materials["block" .. x .. "_" .. y] ~= material or colors["block" .. x .. "_" .. y] ~= color then
				materials["block" .. x .. "_" .. y] = material
				colors["block" .. x .. "_" .. y] = color
				setMaterial(material, color, position, part)
			end
			localAnimator.addDrawable(
				{
					image = (blockImages[part] or "/empty_image.png") .. (blockViewMasks[part] or ""),
					centered = false,
					position = position
				},
				"ForegroundOverlay+1"
			)
		end
	end
end

function setMaterial(material, color, position, part)
	local hueshift = world.materialHueShift(position, "background")
	local materialConfig = root.materialConfig(material)
	if materialConfig then

		local renderTemplate = root.assetJson(materialConfig.config.renderTemplate)
		local texture = fixFilepath(materialConfig.config.renderParameters.texture, materialConfig)
		local tileType = "base"
		local imageSize = root.imageSize(texture)
		local data = renderTemplate.pieces[tileType]
		if not data then return end
		local mask = ""
		local crop1 = vec2.sub({ data.texturePosition[1], imageSize[2] - data.texturePosition[2] - data.textureSize[2] }, vec2.mul(data.colorStride, color))
		local crop2 = vec2.sub({ data.texturePosition[1] + data.textureSize[1], imageSize[2] - data.texturePosition[2] }, vec2.mul(data.colorStride, color))

		blockImages[part] = sb.replaceTags(
			"<materialImage>?crop=<cropX1>;<cropY1>;<cropX2>;<cropY2>?hueshift=<hueshift><mask>",
			{
				hueshift = hueshift,
				materialImage = texture,
				mask = mask,
				cropX1 = crop1[1],
				cropX2 = crop2[1],
				cropY1 = crop1[2],
				cropY2 = crop2[2]
			}
		)
	end
end

function playerViewCircle(position)
	local width = size[1]
	local height = size[2]
	local players = world.playerQuery(vec2.add(position,{-1,-1-height}), vec2.add(position,{width+1, 1}))
	local masks = {}
	for x = 0, width-1 do
		for y = -height+1, 0 do
			masks["block"..x.."_"..y] = ""
		end
	end
	if players and players[1] ~= nil then

		for _, player in ipairs(players) do
			local velocity = world.entityVelocity(player)
			if math.abs(velocity[1]) > 0.5 or math.abs(velocity[2]) > 0.5 then
				timers[player] = 5
			end
			if type(timers[player]) == "number" and timers[player] > 0 then
				local distance = vec2.mul(vec2.floor(vec2.mul(vec2.add(entity.distanceToEntity(player), { -7, -6 }), 8)), -1)
				for x = 0, width-1 do
					for y = -height+1, 0 do
						masks["block"..x.."_"..y] = masks["block"..x.."_"..y].. "?addmask=/objects/sbq/sbqMouseRoom/sbqMouseRoomView.png;" .. (distance[1] + (x * 8)) .. ";" .. (distance[2] + ( y * 8))
					end
				end
			end
		end
	end
	blockViewMasks = masks
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
