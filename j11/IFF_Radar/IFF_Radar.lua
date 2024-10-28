m = math
sin = m.sin
cos = m.cos

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

PN = property.getNumber

function Eular2RotMat(E)
    local qx, qy, qz = E[1], E[2], E[3]
    return { { cos(qy) * cos(qz), cos(qx) * cos(qy) * sin(qz) + sin(qx) * sin(qy),
        sin(qx) * cos(qy) * sin(qz) - cos(qx) * sin(qy) }, { -sin(qz), cos(qx) * cos(qz), sin(qx) * cos(qz) },
        { sin(qy) * cos(qz), cos(qx) * sin(qy) * sin(qz) - sin(qx) * cos(qy),
            sin(qx) * sin(qy) * sin(qz) + cos(qx) * cos(qy) } }
end

function Mv(M, v)
    local u = {}
    for i = 1, 3 do
        local _ = 0
        for j = 1, 3 do
            _ = _ + M[j][i] * v[j]
        end
        u[i] = _
    end
    return u
end

function G2L(v, B)
    local p = Mv(B, { v[1], v[3], v[2] })
    return p[1], p[3], p[2]
end

CHANNEL_COUNT = PN("IFF Channel Count")

function IFFTarget(id, channel)
    return {
        id = id,
        channel = channel,
        ttl = CHANNEL_COUNT
    }
end

IFF_MAPPING = {}

function setDefaultIFFChannels()
    for i = 1, CHANNEL_COUNT do
        OB(33 - i, false)
    end
end

function setDefaultRadarData()
    for i = 1, 17 do
        -- id, ttl, global pos
        ON(i, 0)
    end
    for i = 21, 32 do
        -- local pos
        ON(i, 0)
    end
    for i = 1, 4 do
        -- is friendly
        OB(i, false)
    end
end

function onTick()
    setDefaultIFFChannels()
    -- IFF
    if IB(2) then
        -- IFF On
        -- read current IFF Data
        local id, channel = IN(1), IN(2)
        if id ~= 0 then
            IFF_MAPPING[id] = IFFTarget(id, channel)
        end
        -- refresh IFF_MAPPING
        local toRemove = {}
        for id, t in pairs(IFF_MAPPING) do
            t.ttl = t.ttl - 1
            if t.ttl < 0 then
                table.insert(toRemove, id)
            end
        end
        for _, id in ipairs(toRemove) do
            IFF_MAPPING[id] = nil
        end
        -- set IFF occupied channels
        for _, t in pairs(IFF_MAPPING) do
            OB(33 - t.channel, true)
        end
    else
        -- IFF Off
        IFF_MAPPING = {}
    end

    setDefaultRadarData()
    if IB(1) then
        local ttl, x, y, z, B = IN(19), IN(20), IN(21), IN(22), nil
        for i = 1, 4 do
            local id, tx, ty, tz = IN(4 * i - 1), IN(4 * i), IN(4 * i + 1), IN(4 * i + 2)
            if id > 0 then
                -- set id
                ON(i, id)
                -- set global pos
                ON(3 * i + 3, tx)
                ON(3 * i + 4, ty)
                ON(3 * i + 5, tz)
                -- set local pos
                if B == nil then
                    B = Eular2RotMat({ IN(23), IN(24), IN(25) })
                end
                local lx, ly, lz = G2L({ tx - x, ty - y, tz - z }, B)
                ON(3 * i + 18, lx)
                ON(3 * i + 19, ly)
                ON(3 * i + 20, lz)
                -- set friendly
                OB(i, IFF_MAPPING[id] ~= nil)
            end
        end
        ON(5, ttl)
    end
end
