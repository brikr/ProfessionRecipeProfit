local addonName, ns = ...

-- Identifies us to the Auctionator API.
ns.callerID = addonName

local eventFrame = CreateFrame("Frame")
local handlers = {}

function ns.RegisterEvent(event, handler)
  if not handlers[event] then
    handlers[event] = {}
    eventFrame:RegisterEvent(event)
  end
  table.insert(handlers[event], handler)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
  for _, handler in ipairs(handlers[event]) do
    handler(...)
  end
end)

function ns.Print(fmt, ...)
  print("|cff33ccffPRP|r " .. string.format(fmt, ...))
end

function ns.Debug(fmt, ...)
  if ns.db and ns.db.debug then
    ns.Print("|cff999999" .. fmt .. "|r", ...)
  end
end

ns.RegisterEvent("ADDON_LOADED", function(loadedName)
  if loadedName ~= addonName then
    return
  end
  ProfessionRecipeProfitDB = ProfessionRecipeProfitDB or {}
  ns.db = ProfessionRecipeProfitDB
  ns.db.nameIndex = ns.db.nameIndex or {}
end)

SLASH_PROFESSIONRECIPEPROFIT1 = "/prp"
SlashCmdList.PROFESSIONRECIPEPROFIT = function(msg)
  local cmd = strtrim(msg or ""):lower()
  if cmd == "debug" then
    ns.db.debug = not ns.db.debug
    ns.Print("debug %s", ns.db.debug and "on" or "off")
  elseif cmd == "status" then
    for professionID, entry in pairs(ns.db.nameIndex) do
      local info = not entry.name and C_TradeSkillUI.GetProfessionInfoBySkillLineID
        and C_TradeSkillUI.GetProfessionInfoBySkillLineID(professionID)
      local name = entry.name or (info and info.professionName) or tostring(professionID)
      ns.Print("%s: %d recipes indexed", name, entry.count)
    end
  else
    ns.OpenOptions()
  end
end
