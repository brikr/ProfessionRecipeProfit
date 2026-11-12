local _, ns = ...

local function UpdateDetails(text, recipeInfo)
  local recipe = recipeInfo and ns.Recipes.Get(recipeInfo.recipeID)
  if not recipe then
    text:Hide()
    return
  end
  local parts = {}
  for _, line in ipairs(ns.UI.GetProfitLines(recipe)) do
    table.insert(parts, NORMAL_FONT_COLOR:WrapTextInColorCode(line.label .. ":") .. " " .. line.text)
  end
  text:SetText(table.concat(parts, "\n"))
  text:Show()
end

local function UpdateRow(row, elementData)
  local data = elementData and elementData.GetData and elementData:GetData()
  local recipe = ns.db.options.listProfit and data and data.recipeInfo and ns.Recipes.Get(data.recipeInfo.recipeID)
  local result = recipe and ns.Pricing.GetRecipeProfit(recipe)

  if not row.prpProfit then
    if not (result and result.profit) then
      return
    end
    row.prpProfit = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.prpProfit:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  end

  if result and result.profit then
    local text = ns.Pricing.FormatShort(result.profit)
    if #result.missing > 0 then
      text = text .. "?"
    end
    row.prpProfit:SetText(ns.UI.ProfitColor(result.profit):WrapTextInColorCode(text))
    row.prpProfit:Show()
  else
    row.prpProfit:Hide()
  end
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", function()
  local craftingPage = ProfessionsFrame.CraftingPage
  local form = craftingPage.SchematicForm

  local text = form:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetJustifyH("LEFT")
  if form.Reagents then
    text:SetPoint("TOPLEFT", form.Reagents, "BOTTOMLEFT", 0, -12)
  else
    text:SetPoint("BOTTOMLEFT", form, "BOTTOMLEFT", 25, 40)
  end
  text:Hide()
  hooksecurefunc(form, "Init", function(_, recipeInfo)
    UpdateDetails(text, recipeInfo)
  end)

  local scrollBox = craftingPage.RecipeList.ScrollBox
  function ns.UI.RefreshRecipeList()
    scrollBox:ForEachFrame(function(row)
      UpdateRow(row, row:GetElementData())
    end)
  end

  if ScrollUtil.AddInitializedFrameCallback then
    ScrollUtil.AddInitializedFrameCallback(scrollBox, function(_, row, elementData)
      UpdateRow(row, elementData)
    end, ns, true)
  else
    hooksecurefunc(scrollBox, "Update", ns.UI.RefreshRecipeList)
  end
end)
