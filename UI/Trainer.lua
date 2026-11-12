local _, ns = ...

hooksecurefunc(GameTooltip, "SetTrainerService", function(tooltip, index)
  local tooltipData = tooltip.GetTooltipData and tooltip:GetTooltipData()
  local recipe = ns.Recipes.GetForTrainerService(index, tooltipData)
  if recipe then
    ns.UI.AddTooltipLines(tooltip, recipe)
    tooltip:Show()
  end
end)
