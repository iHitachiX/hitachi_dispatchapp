local RESOURCE = GetCurrentResourceName()
local LANG = Config.Language or "de"

local deptLabelCache = {}
for deptId, data in pairs(Config.Departments) do
    deptLabelCache[deptId] = data.label
end

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
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
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

CreateThread(function()
    Wait(500)
    RegisterApp()
end)

RegisterNetEvent('17mov_Phone:Client:Ready', function()
    RegisterApp()
end)

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

RegisterNUICallback("Core:GetLanguage", function(_, cb)
    cb(getLanguageResponse())
end)

RegisterNUICallback("Dispatch:GetConfig", function(_, cb)
    -- Config.Departments ist key-value { sasp = { label, job } }
    -- UI erwartet Array { { id, label, tabletJob } }
    local deptArray = {}
    for id, data in pairs(Config.Departments) do
        table.insert(deptArray, {
            id       = id,
            label    = data.label,
            tabletJob = data.job,
        })
    end
    -- Alphabetisch sortieren für konsistente Reihenfolge
    table.sort(deptArray, function(a, b) return a.label < b.label end)

    cb({
        departments     = deptArray,
        defaultPriority = Config.Dispatch.DefaultPriority,
    })
end)

RegisterNUICallback("Core:SendDispatch", function(data, cb)
    local lang = Config.Language or "de"
    local L = GetLocale(lang)

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

    cb(res)

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