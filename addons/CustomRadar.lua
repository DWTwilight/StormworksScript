-- g_savedata table that persists between game sessions
g_savedata = {
    GROUP_IDS = {}
}

DETACH_DISTANCE = 25 -- sub vehicle to main vehicle
SEND_BATCH_SIZE = 6  -- send at most 6 vehicle data in one tick
TARGET_DIAL_NAME = "[CR] targetId"
TARGET_ID_PAD_NAME_FORMAT = "[CR] t%did"
TARGET_POS_PAD_NAME_FORMAT = "[CR] t%d%s"
TARGET_TTL_PAD_NAME_FORMAT = "[CR] ttl"
SELF_ID_PAD_NAME = "[CR] id"
EXCLUDE_TAGS = { "trade", "resource", "storage" }
TARGET_ID_PAD_NAMES = {}
for i = 1, SEND_BATCH_SIZE do
    table.insert(TARGET_ID_PAD_NAMES, string.format(TARGET_ID_PAD_NAME_FORMAT, i))
end
TARGET_POS_PAD_NAMES = {}
for i = 1, SEND_BATCH_SIZE do
    table.insert(TARGET_POS_PAD_NAMES, {
        x = string.format(TARGET_POS_PAD_NAME_FORMAT, i, "x"),
        y = string.format(TARGET_POS_PAD_NAME_FORMAT, i, "y"),
        z = string.format(TARGET_POS_PAD_NAME_FORMAT, i, "z")
    })
end

-- vehicle groups
VEHICLE_GROUPS = {}
VG_MAPPING = {}

-- vehicles that need to send
TARGET_LIST = {}
TARGET_MAPPING = {}
-- vehicles to send data to
SEND_LIST = {}
-- refresh settings
REFRESH_INTERVAL = 1 -- how many ticks to recalculate target list & send list
CURRENT_INTERVAL = 0 -- current interval

function vehicle(id, groupId)
    return {
        id = id,
        groupId = groupId,
        matrix = nil,
        hasRadar = false,
        targetId = 0,
        detached = false,
        update = function(v)
            local m, _ = server.getVehiclePos(v.id)
            v.matrix = m
            if v.hasRadar then
                -- try to update target info
                DATA, _ = server.getVehicleDial(v.id, TARGET_DIAL_NAME)
                if DATA ~= nil then
                    v.targetId = DATA["value"]
                end
            end
        end
    }
end

function vehicleGroup(id)
    return {
        id = id,
        main_vid = nil,
        vehicles = {},
        update = function(group)
            if group.main_vid == nil then
                -- the main v is gone, all sub vehicles are detached
                for _, v in pairs(group.vehicles) do
                    v:update()
                    v.detached = true
                end
            else
                -- update main v
                local mainV = group.vehicles[group.main_vid]
                mainV:update()
                -- update sub vs
                for vehicle_id, v in pairs(group.vehicles) do
                    if vehicle_id ~= group.main_vid then
                        v:update()
                        if not v.detached and mainV.matrix ~= nil and v.matrix ~= nil then
                            v.detached = matrix.distance(mainV.matrix, v.matrix) >= DETACH_DISTANCE
                        end
                    end
                end
            end
        end
    }
end

function getVehicleInfo(vehicle_id, group_id)
    VEHICLE_DATA, is_success = server.getVehicleData(vehicle_id)
    if VEHICLE_DATA ~= nil and not VEHICLE_DATA["static"] then
        local fullTag = VEHICLE_DATA["tags_full"]
        local flag = true
        for _, tag in ipairs(EXCLUDE_TAGS) do
            if string.find(fullTag, tag) then
                flag = false
                break
            end
        end
        if flag then
            return vehicle(vehicle_id, group_id)
        end
    end
    return nil
end

function onGroupSpawn(group_id, peer_id, x, y, z, group_cost)
    local group = vehicleGroup(group_id)
    -- get list of vehicles of this group
    local vehicleIds, is_success = server.getVehicleGroup(group_id)

    if vehicleIds ~= nil then
        local flag = true
        for i, vid in ipairs(vehicleIds) do
            local v = getVehicleInfo(vid, group_id)
            -- check if v is excluded(nil)
            if v == nil then
                flag = false
                break
            end
            -- set the fisrt v to main v of group
            if group.main_vid == nil then
                group.main_vid = vid
            end
            group.vehicles[vid] = v
        end
        if flag then
            -- add group to mapping
            VEHICLE_GROUPS[group_id] = group
            -- add each vid -> gid mapping
            for vid, v in pairs(group.vehicles) do
                VG_MAPPING[vid] = group_id
            end
            -- add g_savedata
            g_savedata.GROUP_IDS[group_id] = true
            server.announce("[Custom Radar]", string.format("group: %d added", group_id))
        end
    end
end

function onVehicleDespawn(vehicle_id, peer_id)
    -- get gid of vehicle
    local group_id = VG_MAPPING[vehicle_id]
    -- ensure group exists
    if group_id ~= nil then
        local group = VEHICLE_GROUPS[group_id]
        if group ~= nil then
            -- remove from group list
            group.vehicles[vehicle_id] = nil
            -- remove if is the main vid
            if group.main_vid == vehicle_id then
                group.main_vid = nil
            end
            -- remove group if group has no v
            if next(group.vehicles) == nil then
                -- rm group
                VEHICLE_GROUPS[group_id] = nil
                -- rm g_savedata
                g_savedata.GROUP_IDS[group_id] = nil
            end
            -- remove from VG_MAPPING
            VG_MAPPING[vehicle_id] = nil
        end
    end
end

function onVehicleLoad(vehicle_id)
    local group_id = VG_MAPPING[vehicle_id]
    if group_id ~= nil then
        -- update if hasRadar
        DATA, is_success = server.getVehicleDial(vehicle_id, TARGET_DIAL_NAME)
        if DATA ~= nil then
            local v = VEHICLE_GROUPS[group_id].vehicles[vehicle_id]
            v.hasRadar = true
            v.targetId = DATA["value"]
        end
    end
end

function onCreate(is_world_create)
    -- restore data
    for group_id, _ in pairs(g_savedata.GROUP_IDS) do
        onGroupSpawn(group_id)
    end
    server.announce("[Custom Radar]", "data resotred")
end

-- Tick function that will be executed every logic tick
function onTick(game_ticks)
    -- update each group
    for _, group in pairs(VEHICLE_GROUPS) do
        group:update()
    end

    if CURRENT_INTERVAL >= REFRESH_INTERVAL then
        -- reset target list and send list
        TARGET_LIST = {}
        TARGET_MAPPING = {}
        SEND_LIST = {}
        CURRENT_INTERVAL = 0
        -- refresh lists
        for _, group in pairs(VEHICLE_GROUPS) do
            -- add mainV to target
            local main_vid = group.main_vid
            if main_vid ~= nil then
                local mainV = group.vehicles[main_vid]
                if mainV ~= nil then
                    table.insert(TARGET_LIST, mainV)
                    TARGET_MAPPING[main_vid] = mainV
                end
            end
            for vid, v in pairs(group.vehicles) do
                -- add sub vehicles that are detached to target list
                if vid ~= main_vid and v.detached then
                    table.insert(TARGET_LIST, v)
                    TARGET_MAPPING[vid] = v
                end
                -- add vehicles that have radar to send list
                if v.hasRadar and v.targetId ~= 0 then
                    SEND_LIST[vid] = v
                end
            end
        end
        -- update interval
        REFRESH_INTERVAL = (#TARGET_LIST // 6) + 1
    end
    CURRENT_INTERVAL = CURRENT_INTERVAL + 1

    -- send data to radars
    local cachedPage = nil
    for vid, v in pairs(SEND_LIST) do
        if v.targetId == -1 then
            -- regular radar
            -- set id
            server.setVehicleKeypad(vid, SELF_ID_PAD_NAME, vid)
            -- send page with ttl
            -- initialize page if not
            if cachedPage == nil then
                cachedPage = {}
                for i = (CURRENT_INTERVAL - 1) * SEND_BATCH_SIZE + 1, math.min(CURRENT_INTERVAL * SEND_BATCH_SIZE, #TARGET_LIST) do
                    local v = TARGET_LIST[i]
                    local x, y, z = matrix.position(v.matrix)
                    table.insert(cachedPage, { id = v.id, x = x, y = y, z = z })
                end
            end
            -- send target data
            for i = 1, SEND_BATCH_SIZE do
                local tData = cachedPage[i]
                if tData == nil or tData.id == vid then
                    -- nil target or self
                    -- set target id pad to 0
                    server.setVehicleKeypad(vid, TARGET_ID_PAD_NAMES[i], 0)
                else
                    -- set id
                    server.setVehicleKeypad(vid, TARGET_ID_PAD_NAMES[i], tData.id)
                    -- set pos
                    server.setVehicleKeypad(vid, TARGET_POS_PAD_NAMES[i].x, tData.x)
                    server.setVehicleKeypad(vid, TARGET_POS_PAD_NAMES[i].y, tData.y)
                    server.setVehicleKeypad(vid, TARGET_POS_PAD_NAMES[i].z, tData.z)
                end
            end
            -- send ttl
            server.setVehicleKeypad(vid, TARGET_TTL_PAD_NAME_FORMAT, REFRESH_INTERVAL)
        else
            -- target-specific radar
            local t = TARGET_MAPPING[v.targetId]
            if t ~= nil then
                local x, y, z = matrix.position(t.matrix)
                -- set pos
                server.setVehicleKeypad(vid, TARGET_POS_PAD_NAMES[1].x, x)
                server.setVehicleKeypad(vid, TARGET_POS_PAD_NAMES[1].y, y)
                server.setVehicleKeypad(vid, TARGET_POS_PAD_NAMES[1].z, z)
            end
        end
    end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
    if command == "?cr" then
        if one == "ps" then
            server.announce("[Custom Radar]", "current vehicles:")
            for group_id, group in pairs(VEHICLE_GROUPS) do
                server.announce("[Custom Radar]", string.format("group_id: %d, main_vid: %d", group_id, group.main_vid))
                for vehicle_id, v in pairs(group.vehicles) do
                    local x, y, z = matrix.position(v.matrix)
                    server.announce("[Custom Radar]",
                        string.format("    id: %d, targetId: %d, detached: %s, pos: {%f, %f, %f}",
                            vehicle_id,
                            v.hasRadar and v.targetId or -999,
                            tostring(v.detached),
                            x, y, z))
                end
            end
        end
    end
end
