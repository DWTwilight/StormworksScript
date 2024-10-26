IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

PN = property.getNumber

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
    for i = 1, 25 do
        ON(i, 0)
    end
    for i = 1, 6 do
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
        for i = 1, 6 do
            local id = IN(4 * i - 1)
            if id > 0 then
                ON(4 * i - 3, id)
                ON(4 * i - 2, IN(4 * i))
                ON(4 * i - 1, IN(4 * i + 1))
                ON(4 * i, IN(4 * i + 2))
                OB(i, IFF_MAPPING[id] ~= nil)
            end
        end
        ON(25, IN(25))
    end
end
