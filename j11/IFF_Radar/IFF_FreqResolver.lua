IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

PN = property.getNumber

CHANNEL_COUNT = PN("IFF Channel Count")
INIT_DURATION = PN("Init Duration") + CHANNEL_COUNT

CURRENT_RECV_CHANNEL = 1 -- 1 to CHANNEL_COUNT
SELF_CHANNEL = -1

function shiftRecvChannel()
    CURRENT_RECV_CHANNEL = CURRENT_RECV_CHANNEL + 1
    if CURRENT_RECV_CHANNEL > CHANNEL_COUNT then
        CURRENT_RECV_CHANNEL = 1
    end
    if CURRENT_RECV_CHANNEL == SELF_CHANNEL then
        shiftRecvChannel()
    end
end

function getChannelFreq(time, key, channel)
    return math.ceil(3000 + 100 * math.sin((time + key / 10000) * math.pi * 2)) + channel * 20
end

function onTick()
    local IFFKey = IN(2)
    if IB(1) then
        -- IFF On
        local time = IN(1)
        if INIT_DURATION > 0 or SELF_CHANNEL == -1 then
            -- initialize phase
            -- set recv channel
            ON(1, getChannelFreq(time, IFFKey, CURRENT_RECV_CHANNEL))
            -- shiftCurrentChannel
            shiftRecvChannel()

            -- set transmit freq
            ON(2, -1)
            -- set current chanel
            ON(3, SELF_CHANNEL)
            -- set transmit mode
            OB(1, false)

            INIT_DURATION = INIT_DURATION - 1
            if INIT_DURATION <= 0 then
                -- initialize self channel
                for i = 1, CHANNEL_COUNT do
                    if not IB(33 - i) then
                        SELF_CHANNEL = i
                        break
                    end
                end
            end
        else
            -- set recv channel
            ON(1, getChannelFreq(time, IFFKey, CURRENT_RECV_CHANNEL))
            -- shiftCurrentChannel
            shiftRecvChannel()
            -- set transmit freq
            ON(2, getChannelFreq(time, IFFKey, SELF_CHANNEL))
            -- set current chanel
            ON(3, SELF_CHANNEL)
            -- set transmit mode
            OB(1, true)
        end
    else
        -- IFF OFF
        INIT_DURATION = PN("Init Duration") + CHANNEL_COUNT
        CURRENT_RECV_CHANNEL = 0
        SELF_CHANNEL = -1
        CHANNEL_MAPPING = {}

        -- set recv channel
        ON(1, -1)
        -- set transmit freq
        ON(2, -1)
        -- set current chanel
        ON(3, SELF_CHANNEL)
        -- set transmit mode
        OB(1, false)
    end
end
