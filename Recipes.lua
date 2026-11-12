local _, ns = ...

local Recipes = {}
ns.Recipes = Recipes

local BASIC_REAGENT = Enum.CraftingReagentType and Enum.CraftingReagentType.Basic

-- spellID -> recipe, or false for spells that aren't recipes. Recipe definitions are
-- static, so this lives for the session only.
local recipeCache = {}

local function BuildRecipe(spellID)
  local ok, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, spellID, false)
  if not ok or not schematic then
    return nil
  end

  local recipe = {
    spellID = spellID,
    name = schematic.name,
    outputItemID = schematic.outputItemID,
    outputQty = math.max(1, ((schematic.quantityMin or 1) + (schematic.quantityMax or 1)) / 2),
    reagents = {},
  }
  for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
    local reagent = slot.reagents and slot.reagents[1]
    if reagent and reagent.itemID and (BASIC_REAGENT == nil or slot.reagentType == BASIC_REAGENT) then
      table.insert(recipe.reagents, { itemID = reagent.itemID, qty = slot.quantityRequired or 1 })
    end
  end

  if not recipe.outputItemID and #recipe.reagents == 0 then
    return nil
  end
  return recipe
end

function Recipes.Get(spellID)
  if not spellID then
    return nil
  end
  local recipe = recipeCache[spellID]
  if recipe == nil then
    recipe = BuildRecipe(spellID) or false
    recipeCache[spellID] = recipe
  end
  return recipe or nil
end

-- Name index -----------------------------------------------------------------
-- Maps recipe names to spellIDs per profession so recipe items and trainer entries
-- can be resolved. Rebuilt only when a profession's recipe count changes.

local function IsOwnProfessionView()
  for _, check in ipairs({ "IsTradeSkillLinked", "IsTradeSkillGuild", "IsNPCCrafting" }) do
    local fn = C_TradeSkillUI[check]
    if fn and fn() then
      return false
    end
  end
  return true
end

local function UpdateNameIndex()
  if not IsOwnProfessionView() then
    return
  end
  local info = C_TradeSkillUI.GetBaseProfessionInfo()
  local professionID = info and info.professionID
  if not professionID or professionID == 0 then
    return
  end

  local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
  if not recipeIDs or #recipeIDs == 0 then
    return
  end
  local entry = ns.db.nameIndex[professionID]
  if entry and entry.count == #recipeIDs then
    ns.Debug("name index for profession %d up to date (%d recipes)", professionID, #recipeIDs)
    return
  end

  local byName = {}
  for _, recipeID in ipairs(recipeIDs) do
    local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
    if recipeInfo and recipeInfo.name then
      byName[recipeInfo.name] = recipeID
    end
  end
  ns.db.nameIndex[professionID] = { count = #recipeIDs, name = info.professionName, byName = byName }
  ns.Debug("indexed %d recipes for profession %d", #recipeIDs, professionID)
end

-- The event fires in bursts; handle each burst once.
local updatePending = false
ns.RegisterEvent("TRADE_SKILL_LIST_UPDATE", function()
  if updatePending then
    return
  end
  updatePending = true
  C_Timer.After(0, function()
    updatePending = false
    UpdateNameIndex()
  end)
end)

function Recipes.FindByName(name)
  for _, entry in pairs(ns.db.nameIndex) do
    local spellID = entry.byName[name]
    if spellID then
      return spellID
    end
  end
end

-- Recipe items -----------------------------------------------------------------

local recipeItemCache = {}

function Recipes.GetForRecipeItem(itemID, itemName)
  local spellID = recipeItemCache[itemID]
  if not spellID then
    local _, itemSpellID = C_Item.GetItemSpell(itemID)
    if itemSpellID and Recipes.Get(itemSpellID) then
      spellID = itemSpellID
      ns.Debug("item %d -> spell %d (item spell)", itemID, spellID)
    else
      itemName = itemName or C_Item.GetItemNameByID(itemID)
      if itemName then
        -- Strip the "Recipe: " / "Pattern: " / "Formula: " etc. prefix.
        spellID = Recipes.FindByName(itemName:match("^[^:]+:%s*(.+)$") or itemName)
        ns.Debug("item %d -> spell %s (name '%s')", itemID, tostring(spellID), itemName)
      end
    end
    -- Misses aren't cached: the name index may grow when another profession is opened.
    recipeItemCache[itemID] = spellID
  end
  return Recipes.Get(spellID)
end

-- Trainer services ---------------------------------------------------------------

function Recipes.GetForTrainerService(index, tooltipData)
  local id = tooltipData and tooltipData.id
  ns.Debug("trainer service %d: tooltip type %s id %s", index, tostring(tooltipData and tooltipData.type), tostring(id))
  local recipe = id and Recipes.Get(id)
  if recipe then
    return recipe
  end
  local name = GetTrainerServiceInfo(index)
  return name and Recipes.Get(Recipes.FindByName(name))
end
