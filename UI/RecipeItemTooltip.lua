local _, ns = ...

local RECIPE_CLASS = Enum.ItemClass.Recipe

-- Recipe item subclass -> profession skill line ID.
local SKILL_LINE_BY_SUBCLASS = {
  [1] = 165, -- Leatherworking
  [2] = 197, -- Tailoring
  [3] = 202, -- Engineering
  [4] = 164, -- Blacksmithing
  [5] = 185, -- Cooking
  [6] = 171, -- Alchemy
  [7] = 129, -- First Aid
  [8] = 333, -- Enchanting
  [9] = 356, -- Fishing
  [10] = 755, -- Jewelcrafting
  [11] = 773, -- Inscription
}

local function PlayerHasProfession(skillLine)
  for _, index in pairs({ GetProfessions() }) do
    if select(7, GetProfessionInfo(index)) == skillLine then
      return true
    end
  end
  return false
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
  if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then
    return
  end
  local itemID = data and data.id
  if not itemID then
    return
  end
  local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
  local skillLine = SKILL_LINE_BY_SUBCLASS[subClassID]
  if classID ~= RECIPE_CLASS or not skillLine or not PlayerHasProfession(skillLine) then
    return
  end

  local itemName = data.lines and data.lines[1] and data.lines[1].leftText
  local recipe = ns.Recipes.GetForRecipeItem(itemID, itemName)
  if recipe then
    ns.UI.AddTooltipLines(tooltip, recipe)
  elseif not ns.db.nameIndex[skillLine] then
    ns.UI.AddTooltipHint(tooltip, "Open this profession's window once to load recipe data")
  end
end)
