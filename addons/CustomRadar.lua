-- g_savedata table that persists between game sessions
g_savedata = {}

TARGET_DIAL_NAME = "[CR] targetId"

EXCLUDE_TAGS = { "trade", "resource", "storage" }

function vehicle(groupId, hasRadar, targetId, tag)
    return {
        groupId = groupId,
        matrix = nil,
        hasRadar = hasRadar,
        targetId = targetId,
        tag = tag
    }
end

-- vehicle_id -> vehicle mapping
VEHICLES = {}

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, group_cost, group_id)
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
            VEHICLES[vehicle_id] = vehicle(group_id, false, nil, fullTag)
        end
    end
end

function onVehicleDespawn(vehicle_id, peer_id)
    VEHICLES[vehicle_id] = nil
end

function onVehicleLoad(vehicle_id)
    if VEHICLES[vehicle_id] ~= nil then
        -- update if hasRadar
        DATA, is_success = server.getVehicleDial(vehicle_id, TARGET_DIAL_NAME)
        if DATA ~= nil then
            local v = VEHICLES[vehicle_id]
            v.hasRadar = true
            v.targetId = DATA["value"]
        end
    end
end

-- Tick function that will be executed every logic tick
function onTick(game_ticks)

end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, one, two, three, four, five)
    if command == "?cr" then
        if one == "ps" then
            server.announce("[Custom Radar]", "current vehicles:")
            for vehicle_id, v in pairs(VEHICLES) do
                server.announce("[Custom Radar]",
                    string.format("id: %d, groupId: %d, hasRadar: %s, targetId: %d, tag: %s",
                        vehicle_id, v.groupId,
                        tostring(v.hasRadar),
                        v.hasRadar and v.targetId or -999,
                        v.tag))
            end
        end
    end
end
