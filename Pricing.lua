local _, ns = ...

local Pricing = {}
ns.Pricing = Pricing

-- Auction house deposit/cut taken from the sale price.
local AH_CUT = 0.95

local function GetAuctionPrice(itemID)
  return Auctionator.API.v1.GetAuctionPriceByItemID(ns.callerID, itemID)
end

-- Price the item is sold for by a merchant, cached by Auctionator when merchants are visited.
local function GetVendorPrice(itemID)
  return Auctionator.API.v1.GetVendorPriceByItemID(ns.callerID, itemID)
end

-- Cheapest known way to acquire one of the item, or nil if unpriced.
function Pricing.GetUnitCost(itemID)
  local auction, vendor = GetAuctionPrice(itemID), GetVendorPrice(itemID)
  if auction and vendor then
    return math.min(auction, vendor)
  end
  return auction or vendor
end

-- Returns { cost, value, profit, missing } where value/profit are nil when the output
-- has no auction price (or the recipe makes no item, e.g. enchants), and missing lists
-- reagent itemIDs with no price (cost excludes them).
function Pricing.GetRecipeProfit(recipe)
  local result = { cost = 0, missing = {} }
  for _, reagent in ipairs(recipe.reagents) do
    local unitCost = Pricing.GetUnitCost(reagent.itemID)
    if unitCost then
      result.cost = result.cost + unitCost * reagent.qty
    else
      table.insert(result.missing, reagent.itemID)
    end
  end

  if recipe.outputItemID then
    local price = GetAuctionPrice(recipe.outputItemID)
    if price then
      result.value = math.floor(price * recipe.outputQty * AH_CUT)
      result.profit = result.value - result.cost
    end
  end
  return result
end

function Pricing.FormatMoney(copper)
  if copper < 0 then
    return "-" .. GetMoneyString(-copper, true)
  end
  return GetMoneyString(copper, true)
end

-- Compact form for list rows, e.g. "1.5g", "45s", "7c".
function Pricing.FormatShort(copper)
  local amount = math.abs(copper)
  local text
  if amount >= COPPER_PER_GOLD * 100 then
    text = string.format("%dg", amount / COPPER_PER_GOLD)
  elseif amount >= COPPER_PER_GOLD then
    text = string.format("%.1fg", amount / COPPER_PER_GOLD)
  elseif amount >= COPPER_PER_SILVER then
    text = string.format("%ds", amount / COPPER_PER_SILVER)
  else
    text = string.format("%dc", amount)
  end
  return (copper < 0 and "-" or "+") .. text
end
