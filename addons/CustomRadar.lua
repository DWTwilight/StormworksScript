-- g_savedata table that persists between game sessions
g_savedata = {}

TARGET_DIAL_NAME = "[CR] targetId"
EXCLUDE_TAGS = { "trade", "resource", "storage" }
DETACH_DISTANCE = 25 -- sub vehicle to main vehicle

function vehicle(id, groupId, targetId)
    return {
        id = id,
        groupId = groupId,
        matrix = nil,
        hasRadar = false,
        targetId = targetId,
        detached = false,
        update = function(v)
            local m, _ = server.getVehiclePos(v.id)
            v.matrix = m
            if v.hasRadar then
                -- try to update target info
                DATA, _ = server.getVehicleDial(vehicle_id, TARGET_DIAL_NAME)
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
                        v.detached = matrix.distance(mainV.matrix, v.matrix) >= DETACH_DISTANCE
                    end
                end
            end
        end
    }
end

-- vehicle groups
VEHICLE_GROUPS = {}
VG_MAPPING = {}

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
            return vehicle(group_id, nil, fullTag)
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
            end
            -- remove from VG_mapping
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

-- Tick function that will be executed every logic tick
function onTick(game_ticks)
    -- update each group
    for group_id, group in pairs(VEHICLE_GROUPS) do
        group:update()
    end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
    if command == "?cr" then
        if one == "ps" then
            server.announce("[Custom Radar]", "current vehicles:")
            for group_id, group in pairs(VEHICLE_GROUPS) do
                server.announce("[Custom Radar]", string.format("group_id: %d, main_vid: %d", group_id, group.main_vid))
                for vehicle_id, v in pairs(group.vehicles) do
                    server.announce("[Custom Radar]",
                        string.format("    id: %d, hasRadar: %s, targetId: %d, detached: %s",
                            vehicle_id,
                            tostring(v.hasRadar),
                            v.hasRadar and v.targetId or -999,
                            tostring(v.detached)))
                end
            end
        elseif one == "update" then
            onTick()
        end
    end
end
