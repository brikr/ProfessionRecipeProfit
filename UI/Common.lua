local _, ns = ...

local UI = {}
ns.UI = UI

local LABEL = "|cff33ccffPRP|r "
local GREEN = CreateColor(0.1, 1, 0.1)
local RED = CreateColor(1, 0.25, 0.25)
local GRAY = CreateColor(0.6, 0.6, 0.6)

function UI.ProfitColor(profit)
  return profit >= 0 and GREEN or RED
end

-- Returns Cost/Value/Profit as { key, label, text } entries; key matches the tooltip option.
function UI.GetProfitLines(recipe)
  local result = ns.Pricing.GetRecipeProfit(recipe)
  local Pricing = ns.Pricing

  local cost = Pricing.FormatMoney(result.cost)
  if #result.missing > 0 then
    cost = cost .. GRAY:WrapTextInColorCode(string.format(" (+%d unpriced)", #result.missing))
  end
  local lines = { { key = "tooltipCost", label = "Cost", text = cost } }

  if recipe.outputItemID then
    table.insert(lines, {
      key = "tooltipValue",
      label = "Value",
      text = result.value and Pricing.FormatMoney(result.value) or GRAY:WrapTextInColorCode("no AH price"),
    })
    if result.profit then
      table.insert(lines, {
        key = "tooltipProfit",
        label = "Profit",
        text = UI.ProfitColor(result.profit):WrapTextInColorCode(Pricing.FormatMoney(result.profit) .. (#result.missing > 0 and "?" or "")),
      })
    end
  end
  return lines
end

function UI.AddTooltipLines(tooltip, recipe)
  for _, line in ipairs(UI.GetProfitLines(recipe)) do
    if ns.db.options[line.key] then
      tooltip:AddDoubleLine(LABEL .. line.label, line.text, 1, 0.82, 0, 1, 1, 1)
    end
  end
end

function UI.AddTooltipHint(tooltip, text)
  tooltip:AddLine(LABEL .. GRAY:WrapTextInColorCode(text))
end
