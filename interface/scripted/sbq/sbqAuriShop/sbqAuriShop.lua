---@diagnostic disable: undefined-global

local buyAmount = 1

local shopRecipes = root.assetJson("/recipes/auriShop/auriShopRecipes.config")
local catagoryLabels = root.assetJson("/items/categories.config").labels

local buyRecipe

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
		local listItem = tabScrollArea:addChild({ type = "listItem", selectionGroup = "buyItem", children = {{ type = "panel", style = "convex", children = {{ mode = "horizontal"},
			{ type = "itemSlot", autoInteract = false, item = { name = recipe.result, count = recipe.count, parameters = recipe.parameters }},
			{
				{ type = "label", text = resultItemConfig.config.shortdescription},
				{
					{ type = "label", text = "^gray;"..(catagoryLabels[resultItemConfig.config.category] or resultItemConfig.config.category)},
					bottom
				}
			}
		}}}})
		function listItem:onSelected()
			itemInfoPanelSlot:setItem({ name = recipe.result, parameters = recipe.parameters })
			itemNameLabel:setText(resultItemConfig.config.shortdescription)
			itemCategoryLabel:setText("^gray;"..(catagoryLabels[resultItemConfig.config.category] or resultItemConfig.config.category))
			itemIdLabel:setText(recipe.result)
			buyRecipe = recipe
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
