-- g_savedata table that persists between game sessions
g_savedata = {}

TARGET_DIAL_NAME = "[CR] targetId"

function vehicle(groupId, hasRadar, targetId)
    return {
        groupId = groupId,
        matrix = nil,
        hasRadar = hasRadar,
        targetId = targetId
    }
end

-- vehicle_id -> vehicle mapping
VEHICLES = {}

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, group_cost, group_id)
    VEHICLE_DATA, is_success = server.getVehicleData(vehicle_id)
    if VEHICLE_DATA ~= nil then
        if not VEHICLE_DATA["static"] then
            VEHICLES[vehicle_id] = vehicle(group_id, false, nil)
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
                    string.format("id: %d, groupId: %d, hasRadar: %s, targetId: %d",
                        vehicle_id, v.groupId,
                        tostring(v.hasRadar),
                        v.hasRadar and v.targetId or -999))
            end
        end
    end
end
