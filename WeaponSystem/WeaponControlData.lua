IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool
PN = property.getNumber

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
TARGET = nil
VID = 0
GUIDE_METHOD = -1

function onTick()
    GUIDE_METHOD = IN(19)
    VID = IN(18)

    ON(1, VID) -- weapon vid
    ON(2, GUIDE_METHOD)
    local targetId = IN(20)
    ON(3, targetId)

    if TARGET ~= nil and TARGET.id ~= targetId then
        TARGET = nil
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
            if TARGET == nil then
                TARGET = target(targetId, IN(3 * ri + 3), IN(3 * ri + 4), IN(3 * ri + 5), IN(5), IB(ri))
            else
                TARGET:update({ IN(3 * ri + 3), IN(3 * ri + 4), IN(3 * ri + 5) }, IN(5), IB(ri))
            end
        end

        -- update ttl
        if TARGET ~= nil then
            TARGET:update()
            if TARGET.ttl < 0 then
                TARGET = nil
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
        ON(4, IN(21))
        ON(6, IN(22))
    elseif TARGET ~= nil then
        local tx, ty, tz, tvx, tvy, tvz = TARGET:curStatus()
        -- target pos
        ON(4, tx)
        ON(5, ty)
        ON(6, tz)
        -- target speed
        ON(7, tvx)
        ON(8, tvy)
        ON(9, tvz)
        -- target friendly
        OB(1, TARGET.f)
    end

    -- trigger
    OB(2, IB(5))
end

function onDraw()
    if VID > 0 and GUIDE_METHOD >= 0 then
        -- selected weapon and has guide method
    end
end
