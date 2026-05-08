local cooldowns = {}


local cooldowns = {}

local deptCache = {}
for deptId, data in pairs(Config.Departments) do
    deptCache[deptId] = data
end

local function nowSeconds()
    return os.time()
end

local function getCooldownRemaining(source, deptId)
    local perPlayer = cooldowns[source]
    if not perPlayer then return 0 end

    local untilTs = perPlayer[deptId]
    if not untilTs then return 0 end

    local remain = untilTs - nowSeconds()
    if remain < 0 then return 0 end

    return remain
end

local function setCooldown(source, deptId, seconds)
    cooldowns[source] = cooldowns[source] or {}
    cooldowns[source][deptId] = nowSeconds() + seconds
end

AddEventHandler("playerDropped", function()
    cooldowns[source] = nil
end)

local function findDepartment(deptId)
    return deptCache[deptId]
end

local function clampPriority(priority)
    if priority == "low" or priority == "medium" or priority == "high" then
        return priority
    end

    return Config.Dispatch.DefaultPriority
end

local function getCharacterName(source, L)
    local ok, player = pcall(function()
        return exports.qbx_core:GetPlayer(source)
    end)

    if ok and player and player.PlayerData then
        local charinfo = player.PlayerData.charinfo

        if charinfo and charinfo.firstname and charinfo.lastname then
            return ("%s %s"):format(charinfo.firstname, charinfo.lastname)
        end

        if player.PlayerData.name and player.PlayerData.name ~= "" then
            return tostring(player.PlayerData.name)
        end
    end

    return L.dispatch_sender_unknown or ("ID " .. tostring(source))
end

local function prettyPriority(priority, L)
    if priority == "low" then return L.priority_low or "low" end
    if priority == "medium" then return L.priority_medium or "medium" end
    if priority == "high" then return L.priority_high or "high" end

    return tostring(priority)
end

lib.callback.register("dispatch_phone:server:addDispatch", function(source, data)
    print("[DispatchApp] Callback getriggert von:", source)
    local L = GetLocale(Config.Language or "de")

    if GetResourceState('kartik-mdt') ~= 'started' then
        return {
            success = false,
            message = 'Kartik MDT wurde nicht gestartet.'
        }
    end

    if type(data) ~= "table" then
        return { success = false, message = L.err_failed }
    end

    local dept = findDepartment(data.department)
    if not dept then
        return { success = false, message = L.err_unknown_department }
    end

    local cd = tonumber(Config.Dispatch.CooldownSeconds) or 0

    if cd > 0 then
        local remaining = getCooldownRemaining(source, data.department)

        if remaining > 0 then
            local mins = math.ceil(remaining / 60)

            return {
                success = false,
                message = LocaleFormat(L.cooldown_active or "Bitte warten: Du kannst an {dept} erst in {mins} Minute(n) wieder senden.", {
                    dept = dept.label,
                    mins = mins
                })
            }
        end
    end

    local msg = tostring(data.message or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    if #msg < 3 then
        return {
            success = false,
            message = L.err_text_too_short
        }
    end

    if #msg > 500 then
        msg = msg:sub(1, 500)
    end

    local priority = clampPriority(data.priority)

    local location = data.location or {
        label = (L.location_unknown or "Unbekannt"),
        coords = {
            x = 0.0,
            y = 0.0,
            z = 0.0
        }
    }

    local anonymous = (data.anonymous == true)

    local senderName = anonymous
        and (L.dispatch_sender_unknown or "Unbekannt")
        or getCharacterName(source, L)

    local priorityLabel = prettyPriority(priority, L)

    local blipColor = 2

    if priority == "high" then
        blipColor = 1
    elseif priority == "medium" then
        blipColor = 5
    end

    local coords = location.coords or {}

    local ok = pcall(function()
        print("[DispatchApp] Sende an kartik-mdt:", json.encode({
            title = LocaleFormat(L.dispatch_title, { dept = dept.label }),
            jobs = { [dept.mdtCategory or dept.job] = true },
            x = tonumber(coords.x) or 0.0,
            y = tonumber(coords.y) or 0.0,
            z = tonumber(coords.z) or 0.0,
        }))
        TriggerEvent('kartik-mdt:server:sendDispatchNotification', {
            priority = priority,
            code        = 'Dispatch App',
            title       = LocaleFormat(L.dispatch_title, { dept = dept.label }),
            description = ('%s | %s | %s'):format(dept.label, senderName, msg),
            location    = location.label or (L.location_unknown or 'Unbekannt'),
            x           = tonumber(coords.x) or 0.0,
            y           = tonumber(coords.y) or 0.0,
            z           = tonumber(coords.z) or 0.0,
            sound       = 'dispatch',
            type        = 'Alert',
            blip = {
                radius  = 0.0,
                sprite  = 431,
                color   = blipColor,
                scale   = 1.2,
                length  = math.max(1, math.floor(Config.Dispatch.DurationSeconds / 60)),
            },
            jobs = { [dept.mdtCategory or dept.job] = true },
        })
    end)

    if not ok then
        return {
            success = false,
            message = L.err_failed
        }
    end

    if cd > 0 then
        setCooldown(source, data.department, cd)
    end

    return {
        success = true
    }
end)