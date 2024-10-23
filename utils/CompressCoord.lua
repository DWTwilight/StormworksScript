M = math
ABS = M.abs

function round(num)
    return M.floor(num + 0.5)
end

-- sign-x: 1-bit, x: 20-bit, sign-y: 1-bit, y: 20-bit, sign-z: 1-bit, z: 20-bit
function compress(x, y, z)
    local absX, absY, absZ = ABS(round(x * 4)), ABS(round(y * 4)), ABS(round(z * 4))
    local compressed = (x < 0 and 1 or 0) << 62 | (absX << 42)
        | (y < 0 and 1 or 0) << 41 | absY << 21
        | (z < 0 and 1 or 0) << 20 | absZ

    local packed = string.pack("I8", compressed)
    -- Unpack the binary string as a double (64-bit float)
    local floatValue = string.unpack("d", packed)
    return floatValue
end

function decompress(value)
    local packed = string.pack("d", value)
    local compressed = string.unpack("I8", packed)
    local signX, absX = compressed >> 62 & 1, compressed >> 42 & 0xFFFFF
    local signY, absY = compressed >> 41 & 1, compressed >> 21 & 0xFFFFF
    local signZ, absZ = compressed >> 20 & 1, compressed & 0xFFFFF
    return (signX == 0 and 1 or -1) * absX / 4,
        (signY == 0 and 1 or -1) * absY / 4,
        (signZ == 0 and 1 or -1) * absZ / 4
end

local x, y, z = 0x3FFFF, 0x3FFFF, 0x3FFFF
local compressed_value = compress(x, y, z)
print("Compressed:", compressed_value)

local x_decompressed, y_decompressed, z_decompressed = decompress(compressed_value)
print("Decompressed:", x_decompressed, y_decompressed, z_decompressed)
