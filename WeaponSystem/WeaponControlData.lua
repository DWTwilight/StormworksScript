IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber
PT = property.getText

S = screen
DT = S.drawText
DRF = S.drawRectF
DL = S.drawLine

function H2RGB(e)
    e = e:gsub("#", "")
    return {
        r = tonumber("0x" .. e:sub(1, 2)),
        g = tonumber("0x" .. e:sub(3, 4)),
        b = tonumber("0x" .. e:sub(5, 6)),
        t = tonumber("0x" .. e:sub(7, 8))
    }
end

function SC(c)
    S.setColor(c.r, c.g, c.b, c.t)
end

function target(id, x, y, z, ttl, f)
    return {
        id = id,
        pos = { x, y, z },
        v = nil,
        ttlF = ttl,
        ttl = ttl,
        f = f,
        update = function(t, pos, ttl, f)
            if pos == nil then
                t.ttl = t.ttl - 1
            else
                -- update speed
                t.v = {
                    (pos[1] - t.pos[1]) / t.ttlF,
                    (pos[2] - t.pos[2]) / t.ttlF,
                    (pos[3] - t.pos[3]) / t.ttlF
                }
                t.pos = pos
                t.ttl = ttl
                t.ttlF = ttl
                t.f = f
            end
        end,
        curStatus = function(t)
            if t.v == nil then
                return t.pos[1], t.pos[2], t.pos[3], 0, 0, 0
            else
                return
                    t.pos[1] + t.v[1] * (t.ttlF - t.ttl),
                    t.pos[2] + t.v[1] * (t.ttlF - t.ttl),
                    t.pos[3] + t.v[1] * (t.ttlF - t.ttl),
                    t.v[1] * TICK_PER_SEC,
                    t.v[2] * TICK_PER_SEC,
                    t.v[3] * TICK_PER_SEC
            end
        end
    }
end

MAP_GUIDE = 2
TICK_PER_SEC = PN("Tick per Sec")
RTAR = nil
VID = 0
GUIDE_METHOD = -1

TARGET_FLAG = false
TARGET_INFO = {
    id = 0,
    speed = 0,
    distance = 0,
    pos = { 0, 0, 0 },
    friendly = false
}

UC2 = H2RGB(PT("UI Secondary Color"))
DC = H2RGB(PT("Danger Color"))

function onTick()
    GUIDE_METHOD = IN(19)
    VID = IN(18)

    ON(1, VID) -- weapon vid
    ON(2, GUIDE_METHOD)
    local targetId = IN(20)
    ON(3, targetId)

    if RTAR ~= nil and RTAR.id ~= targetId then
        RTAR = nil
    end
    if targetId ~= 0 then
        local ri = nil
        for i = 1, 4 do
            if IN(i) == targetId then
                ri = i
                break
            end
        end

        if ri ~= nil then
            -- update or create target info
            if RTAR == nil then
                RTAR = target(targetId, IN(3 * ri + 3), IN(3 * ri + 4), IN(3 * ri + 5), IN(5), IB(ri))
            else
                RTAR:update({ IN(3 * ri + 3), IN(3 * ri + 4), IN(3 * ri + 5) }, IN(5), IB(ri))
            end
        end

        -- update ttl
        if RTAR ~= nil then
            RTAR:update()
            if RTAR.ttl < 0 then
                RTAR = nil
            end
        end
    end

    -- set default target info
    -- target pos
    ON(4, 0)
    ON(5, 0)
    ON(6, 0)
    -- target speed
    ON(7, 0)
    ON(8, 0)
    ON(9, 0)
    -- target friendly
    OB(1, false)
    if targetId == 0 and GUIDE_METHOD == MAP_GUIDE then
        -- target pos
        local mapX, mapZ = IN(21), IN(22)
        ON(4, mapX)
        ON(6, mapZ)
        if mapX ~= 0 or mapZ ~= 0 then
            TARGET_FLAG = true
            TARGET_INFO = {
                id = 0,
                speed = 0,
                distance = ((mapX - IN(23)) ^ 2 + (mapZ - IN(25)) ^ 2) ^ 0.5,
                pos = { mapX, 0, mapZ },
                friendly = false
            }
        else
            TARGET_FLAG = false
        end
    elseif RTAR ~= nil then
        local tx, ty, tz, tvx, tvy, tvz = RTAR:curStatus()
        -- target pos
        ON(4, tx)
        ON(5, ty)
        ON(6, tz)
        -- target speed
        ON(7, tvx)
        ON(8, tvy)
        ON(9, tvz)
        -- target friendly
        OB(1, RTAR.f)

        TARGET_FLAG = true
        TARGET_INFO = {
            id = RTAR.id,
            speed = (tvx ^ 2 + tvy ^ 2 + tvz ^ 2) ^ 0.5,
            distance = ((tx - IN(23)) ^ 2 + (ty - IN(24)) + (tz - IN(25)) ^ 2) ^ 0.5,
            pos = { tx, ty, tz },
            friendly = RTAR.f
        }
    else
        TARGET_FLAG = false
    end

    -- trigger
    OB(2, IB(5))
end

function onDraw()
    if VID > 0 and GUIDE_METHOD >= 0 then
        -- selected weapon and has guide method, draw target info
        SC(UC2)
        DT(2, 39, "Target Info:")
        if TARGET_FLAG then
            -- has target
            DT(4, 46, string.format("Id:#%04d", TARGET_INFO.id))
            SC(TARGET_INFO.friendly and UC2 or DC)
            DT(59, 46, TARGET_INFO.friendly and "friendly" or "enemy")
            SC(UC2)
            DT(4, 53, string.format("Range: %.1f km", TARGET_INFO.distance / 1000))
            DT(4, 60, string.format("Speed: %.0f m/s", TARGET_INFO.speed))
            DT(4, 67, "Coord:")
            DT(39, 67, string.format("x %.1f", TARGET_INFO.pos[1]))
            DT(39, 74, string.format("y %.1f", TARGET_INFO.pos[2]))
            DT(39, 81, string.format("z %.1f", TARGET_INFO.pos[3]))
        else
            SC(DC)
            DT(4, 60, "No Target Selected")
        end
    end
end
