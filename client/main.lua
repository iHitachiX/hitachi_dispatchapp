local RESOURCE = GetCurrentResourceName()
local LANG = Config.Language or "de"

-- Department cache (O(1) lookup statt O(n) Loop)
local deptCache = {}
local deptLabelCache = {}
for _, d in ipairs(Config.Departments) do
  deptCache[d.id] = d
  deptLabelCache[d.id] = d.label
end

-- Helper um NUI-URLs konsistent zu bauen (double-slash für 17mov_Phone)
local function nuiUrl(path)
  return ("https://cfx-nui-%s//%s"):format(RESOURCE, path)
end

local function getDeptLabel(deptId)
  return deptLabelCache[deptId] or deptId or "Dispatch"
end

local function getPlayerLocation()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)

  local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
  local streetName = GetStreetNameFromHashKey(streetHash)

  local label = (streetName and streetName ~= "") and streetName
      or ("X: %.1f Y: %.1f"):format(coords.x, coords.y)

  return {
    label = label,
    coords = { x = coords.x, y = coords.y }
  }
end

local function RegisterApp()
  exports['17mov_Phone']:AddApplication({
    name = Config.App.Name,
    label = Config.App.Label,
    ui = nuiUrl("web/build/index.html"),
    icon = nuiUrl("web/build/icon.svg"),
    iconBackground = Config.App.IconBackground,
    default = Config.App.Default,
    preInstalled = Config.App.PreInstalled,
    resourceName = RESOURCE,
    rating = 5.0,
  })
end

-- Initial registration
CreateThread(function()
  Wait(500)
  RegisterApp()
end)

-- Re-register if phone restarts
RegisterNetEvent('17mov_Phone:Client:Ready', function()
  RegisterApp()
end)

-- Unified language callback (für beide Callbacks)
local function getLanguageResponse()
  local lang = Config.Language or "de"
  local L = GetLocale(lang)

  local strings = {}
  for k, v in pairs(L) do
    strings[k] = v
  end

  return {
    language = lang,
    strings = strings,
  }
end

RegisterNUICallback("Dispatch:GetLanguage", function(_, cb)
  cb(getLanguageResponse())
end)

-- Fallback für Phone/Boilerplate
RegisterNUICallback("Core:GetLanguage", function(_, cb)
  cb(getLanguageResponse())
end)

-- UI liest Departments + Defaults dynamisch aus Config
RegisterNUICallback("Dispatch:GetConfig", function(_, cb)
  cb({
    departments = Config.Departments,
    defaultPriority = Config.Dispatch.DefaultPriority,
  })
end)

-- UI -> Dispatch senden (Server) -> native 17mov Notify
RegisterNUICallback("Core:SendDispatch", function(data, cb)
  local lang = Config.Language or "de"
  local L = GetLocale(lang)

  -- Validate client input
  if type(data) ~= "table" or not data.department or not data.message then
    cb({ success = false, message = L.err_failed })
    return
  end

  local payload = {
    department = data.department,
    message = data.message,
    priority = data.priority,
    anonymous = (data.anonymous == true),
    location = getPlayerLocation(),
  }

  local res = lib.callback.await("dispatch_phone:server:addDispatch", false, payload)

  -- UI bekommt immer Response (damit busy state sauber endet)
  cb(res)

  -- 17mov-Phone Notification (mit pcall für Sicherheit)
  local ok, phoneExport = pcall(function()
    return exports["17mov_Phone"]
  end)

  if not ok or not phoneExport then return end

  local number = phoneExport:GetPlayerNumber()

  if res and res.success then
    local deptLabel = getDeptLabel(data.department)

    phoneExport:CreateNotification({
      app = Config.App.Name,
      title = L.notify_sent_title,
      message = LocaleFormat(L.notify_sent_message, { dept = deptLabel }),
      number = number,
      data = { alwaysShow = true }
    })
  else
    local reason = (res and res.message) and tostring(res.message) or L.err_failed

    phoneExport:CreateNotification({
      app = Config.App.Name,
      title = L.notify_failed_title,
      message = LocaleFormat(L.notify_failed_message, { reason = reason }),
      number = number,
      data = { alwaysShow = true }
    })
  end
end)
