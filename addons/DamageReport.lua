function onVehicleDamaged(vehicle_id, damage_amount, voxel_x, voxel_y, voxel_z, body_index)
    server.announce("[Damage Report]", string.format("HIT! target: %d, damage: %d", vehicle_id, damage_amount))
end
