---@diagnostic disable: undefined-global

local buyAmount = 1

local shopRecipes = root.assetJson("/recipes/auriShop/auriShopRecipes.config")
local catagoryLabels = root.assetJson("/items/categories.config").labels

local buyRecipe

function fixFilepath(string, item)
	if type(string) == "string" then
		if string == "" then return
		elseif string:find("^?") then return
		elseif string:find("^/") then
			return string
		else
			return item.directory..string
		end
	else
		return
	end
end

for tab, recipes in pairs(shopRecipes) do
	local tabScrollArea = _ENV[tab.."ScrollArea"]
	for i, recipe in ipairs(recipes) do
		local resultItemConfig = root.itemConfig(recipe.result)
		local bottom = { type = "label", text = " "}
		for _, material in ipairs(recipe.materials) do
			if material.item == "money" then
				bottom = { { mode = "horizontal" }, { type = "layout", expandMode = {1,1} }, { type = "image", file = "/interface/merchant/pixels.png", align = 1 }, { type = "label", text = (tostring( material.count )), inline = true, align = 1}}
			end
		end
		local listItem = tabScrollArea:addChild({ type = "menuItem", selectionGroup = "buyItem", children = {{ type = "panel", style = "convex", children = {{ mode = "horizontal"},
			{ type = "itemSlot", autoInteract = false, item = { name = recipe.result, count = recipe.count, parameters = recipe.parameters }},
			{
				{ type = "label", text = resultItemConfig.config.shortdescription},
				{
					{ type = "label", text = "^gray;"..(catagoryLabels[resultItemConfig.config.category] or resultItemConfig.config.category)},
					bottom
				}
			}
		}}}})

		local image = resultItemConfig.config.inventoryIcon or "/empty_image.png"
		local scale = 2
		local wasObject

		if ((((resultItemConfig.config.orientations or {})[1] or {}).imageLayers or {})[1] or {}).image ~= nil then
			image = ((((resultItemConfig.config.orientations or {})[1] or {}).imageLayers or {})[1] or {}).image
			wasObject = true
		elseif resultItemConfig.config.largeImage ~= nil then
			image = resultItemConfig.config.largeImage
			scale = 1.5
		end
		image = fixFilepath(image, resultItemConfig)

		if wasObject and image ~= nil then
			local size = root.imageSize(image)
			if size[1] > 90 or size[2] > 90 then
				local x = 90/(size[1])
				local y = 90/(size[2])
				if x > y then
					scale = y
				else
					scale = x
				end
			else
				scale = 1
			end
		end

		function listItem:onClick()
			buyRecipe = recipe
			itemInfoPanelSlot:setItem({ name = recipe.result, parameters = recipe.parameters })
			itemNameLabel:setText(resultItemConfig.config.shortdescription)
			itemCategoryLabel:setText("^gray;"..(catagoryLabels[resultItemConfig.config.category] or resultItemConfig.config.category))
			itemDescriptionLabel:setText(resultItemConfig.config.description)
			itemImage:setFile(image)
			itemImage:setScale({scale, scale})

			if sbq.data.dialogueTree.itemSelection[recipe.result] ~= nil then
				sbq.updateDialogueBox({ "itemSelection",recipe.result })
			else
				sbq.updateDialogueBox({ "greeting", "neutral", "continue" })
			end
		end
	end
end


function sbq.dismissAfterTimer(time)
	if time == -1 then
		sbq.timerList.dismissAfterTime = nil
	else
		sbq.forceTimer("dismissAfterTime", time or 10, function ()

		end)
	end
end

function decAmount:onClick()
	buyAmount = math.max(1, buyAmount - 1)
	buyAmountLabel:setText(tostring(buyAmount))
end

function incAmount:onClick()
	buyAmount = buyAmount + 1
	buyAmountLabel:setText(tostring(buyAmount))
end

function buy:onClick()
	if hasMaterials() or player.isAdmin() then
		if not player.isAdmin() then
			for _, material in ipairs(buyRecipe.materials) do
				if not player.consumeItem({ name = material.item, count = material.count * buyAmount })then
					player.consumeCurrency( material.item, material.count * buyAmount )
				end
			end
		end
		for i = 1, buyAmount do
			player.giveItem({ name = buyRecipe.result, count = buyRecipe.count, parameters = buyRecipe.parameters })
		end
	end
end

function hasMaterials()
	for _, material in ipairs(buyRecipe.materials) do
		if not ( (material.count * buyAmount) <= player.hasCountOfItem({ name = material.item}) or (material.count * buyAmount) <= player.currency(material.item)) then return false end
	end
	return true
end
