local addonName, ns = ...

local DEFAULTS = {
  tooltipCost = true,
  tooltipValue = true,
  tooltipProfit = true,
  listProfit = true,
}

local category

ns.RegisterEvent("ADDON_LOADED", function(loadedName)
  if loadedName ~= addonName then
    return
  end
  ns.db.options = ns.db.options or {}
  local options = ns.db.options
  for key, value in pairs(DEFAULTS) do
    if options[key] == nil then
      options[key] = value
    end
  end

  local layout
  category, layout = Settings.RegisterVerticalLayoutCategory(C_AddOns.GetAddOnMetadata(addonName, "Title"))

  local function AddHeader(text)
    if layout and CreateSettingsListSectionHeaderInitializer then
      layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
  end

  local function AddCheckbox(key, label, tooltip, onChange)
    local setting = Settings.RegisterAddOnSetting(category, "PRP_" .. key, key, options, "boolean", label, DEFAULTS[key])
    Settings.CreateCheckbox(category, setting, tooltip)
    if onChange then
      setting:SetValueChangedCallback(onChange)
    end
  end

  AddHeader("Tooltips")
  AddCheckbox("tooltipCost", "Show cost", "Show the reagent cost on trainer and recipe item tooltips.")
  AddCheckbox("tooltipValue", "Show value", "Show the auction value of the crafted item (after AH cut) on trainer and recipe item tooltips.")
  AddCheckbox("tooltipProfit", "Show profit", "Show the estimated profit on trainer and recipe item tooltips.")

  AddHeader("Profession window")
  AddCheckbox("listProfit", "Show profit in recipe list", "Show the estimated profit next to each recipe in the profession window's recipe list.", function()
    if ns.UI.RefreshRecipeList then
      ns.UI.RefreshRecipeList()
    end
  end)

  Settings.RegisterAddOnCategory(category)
end)

function ns.OpenOptions()
  Settings.OpenToCategory(category:GetID())
end
