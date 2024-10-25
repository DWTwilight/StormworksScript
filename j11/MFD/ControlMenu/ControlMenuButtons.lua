M = math
MAX = M.max
MIN = M.min

S = screen
DM = S.drawMap
DR = S.drawRect
DRF = S.drawRectF
DL = S.drawLine
DC = S.drawCircle

IN = input.getNumber
IB = input.getBool
ON = output.setNumber

P = property
PN = P.getNumber
PT = P.getText

function D0(a, b)
    DR(a, b, 2, 4)
end

function D1(a, b)
    DL(a + 1, b, a + 1, b + 4)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b + 1, a + 1, b + 1)
end

function D2(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a + 2, b, a + 2, b + 2)
    DL(a, b + 2, a, b + 4)
end

function D3(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a + 2, b, a + 2, b + 4)
end

function D4(a, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a + 2, b, a + 2, b + 5)
    DL(a, b, a, b + 2)
end

function D5(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 2)
    DL(a + 2, b + 2, a + 2, b + 4)
end

function D6(a, b)
    DR(a, b + 2, 2, 2)
    DL(a, b, a + 3, b)
    DL(a, b, a, b + 2)
end

function D7(a, b)
    DL(a, b, a + 3, b)
    DL(a + 2, b, a + 2, b + 5)
end

function D8(a, b)
    DR(a, b, 2, 4)
    DL(a, b + 2, a + 3, b + 2)
end

function D9(a, b)
    DR(a, b, 2, 2)
    DL(a + 2, b, a + 2, b + 5)
    DL(a, b + 4, a + 3, b + 4)
end

function AA(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b + 1, a, b + 5)
    DL(a + 2, b + 1, a + 2, b + 5)
end

function BB(a, b)
    DC(a + 1, b + 1, 1)
    DC(a + 1, b + 3, 1)
    DL(a, b, a, b + 5)
end

function EE(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 2, b + 2)
    DL(a, b + 4, a + 3, b + 4)
    DL(a, b, a, b + 5)
end

function FF(a, b)
    DL(a, b, a + 3, b)
    DL(a, b + 2, a + 2, b + 2)
    DL(a, b, a, b + 5)
end

function PP(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b, a, b + 5)
end

function SS(a, b)
    DL(a + 1, b, a + 3, b)
    DL(a, b + 4, a + 2, b + 4)
    DL(a, b + 1, a + 3, b + 4)
end

function TT(a, b)
    DL(a, b, a + 3, b)
    DL(a + 1, b, a + 1, b + 5)
end

function WW(a, b)
    DL(a, b + 3, a + 3, b + 3)
    DL(a, b, a, b + 5)
    DL(a + 2, b, a + 2, b + 5)
end

function CST(a, b, s)
    if s == "A" then
        AA(a, b)
    elseif s == "B" then
        BB(a, b)
    elseif s == "E" then
        EE(a, b)
    elseif s == "F" then
        FF(a, b)
    elseif s == "P" then
        PP(a, b)
    elseif s == "S" then
        SS(a, b)
    elseif s == "T" then
        TT(a, b)
    elseif s == "W" then
        WW(a, b)
    elseif s == "0" then
        D0(a, b)
    elseif s == "1" then
        D1(a, b)
    elseif s == "2" then
        D2(a, b)
    elseif s == "3" then
        D3(a, b)
    elseif s == "4" then
        D4(a, b)
    elseif s == "5" then
        D5(a, b)
    elseif s == "6" then
        D6(a, b)
    elseif s == "7" then
        D7(a, b)
    elseif s == "8" then
        D8(a, b)
    elseif s == "9" then
        D9(a, b)
    end
end

function STLen(s)
    local len = 0
    for d = 1, string.len(s) do
        local sin = s:sub(d, d)
        if len ~= 0 then
            len = len + 1
        end
        if sin == "." or sin == " " or sin == ":" then
            len = len + 1
        else
            len = len + 3
        end
    end
    return len
end

function DST(a, b, c)
    a = math.floor(a)
    b = math.floor(b)
    for d = 1, string.len(c) do
        local sin = c:sub(d, d)
        CST(a, b, sin)
        if sin == "." or sin == " " or sin == ":" then
            a = a + 2
        else
            a = a + 4
        end
    end
end

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

function PIR(x, y, rectX, rectY, rectW, rectH)
    return x >= rectX and y > rectY and x < rectX + rectW and y <= rectY + rectH
end

function PushButton(x, y, w, h, text, color, pressColor)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        t = text,
        tlen = STLen(text),
        c = color,
        pc = pressColor,
        p = false,
        op = false,
        press = function(btn, tx, ty)
            local pressed = PIR(tx, ty, btn.x, btn.y, btn.w, btn.h)
            btn.op = pressed and not btn.p
            btn.p = pressed
        end,
        clearPress = function(btn)
            btn.op = false
            btn.p = false
        end,
        draw = function(btn)
            local c1, c2
            if btn.p then
                c1, c2 = btn.pc, btn.c
            else
                c1, c2 = btn.c, btn.pc
            end
            SC(c1)
            DRF(btn.x, btn.y, btn.w, btn.h)
            SC(c2)
            DST(btn.x + btn.w // 2 - btn.tlen // 2, btn.y + (btn.h - 5) / 2, btn.t)
        end
    }
end

function clamp(value, min, max)
    return MIN(max, MAX(value, min))
end

-- configs
APA, APS, APH = nil, nil, nil

-- status
FTWP = false

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))

-- btns
APASB = PushButton(45, 7, 13, 7, "SET", UC, UC2)
APSSB = PushButton(45, 14, 13, 7, "SET", UC, UC2)
APHSB = PushButton(45, 21, 13, 7, "SET", UC, UC2)
BTNS = { APASB, APSSB, APHSB }

function onTick()
    if IB(1) then
        local tx, ty = IN(1), IN(2)

        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        if APASB.op then
            APA = clamp(IN(3), 50, 19000) // 1
        elseif APSSB.op then
            APS = clamp(IN(3), 500, 1500) // 1
        elseif APHSB.op then
            APH = clamp(IN(3), 0, 359) // 1
        end
    else
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end
    end

    -- AP enabled:
    if IB(3) then
        APA = clamp(IN(4), 50, 19000) // 1
        APS = clamp(IN(5) * 3.6, 500, 1500) // 1
        APH = ((IN(6) / M.pi * 180 + 360) // 1) % 360
    end

    -- Fly to waypoint
    FTWP = IB(4)

    ON(1, APA or 0)
    ON(2, APS or 0)
    ON(3, APH or 0)
end

function TBAO(v)
    return v == nil and "TBA" or string.format("%.0f", v)
end

function onDraw()
    SC(UC2)
    DST(20, 7, TBAO(APA))
    DST(20, 14, TBAO(APS))
    DST(20, 21, FTWP and "FTWP" or TBAO(APH))

    -- btns
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
