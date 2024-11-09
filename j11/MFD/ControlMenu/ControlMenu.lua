M = math
MAX = M.max
MIN = M.min

S = screen
DT = S.drawText
DRF = S.drawRectF

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PT = P.getText

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
    return x >= rectX and y >= rectY and x < rectX + rectW and y < rectY + rectH
end

function PushButton(x, y, w, h, text, color, pressColor, tx, ty)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        t = text,
        c = color,
        pc = pressColor,
        p = false,
        op = false,
        tx = tx,
        ty = ty,
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
            DT(btn.x + btn.tx, btn.y + btn.ty, btn.t)
        end
    }
end

function clamp(value, min, max)
    return MIN(max, MAX(value, min))
end

-- configs
APA, APS, APH = nil, nil, nil
IFFK = nil

-- status
AP = false
IFF = false
FTWP = false

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
OFFC = H2RGB(PT("Off Color"))

-- btns
APASB = PushButton(80, 6, 15, 7, "SET", UC, UC2, 1, 1)
APSSB = PushButton(80, 13, 15, 7, "SET", UC, UC2, 1, 1)
APHSB = PushButton(80, 20, 15, 7, "SET", UC, UC2, 1, 1)
IFFSB = PushButton(80, 34, 15, 7, "SET", UC, UC2, 1, 1)
BTNS = { APASB, APSSB, APHSB, IFFSB }

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
        elseif IFFSB.op then
            IFFK = clamp(IN(3), 0, 9999) // 1
        end
    else
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end
    end

    -- AP enabled(pulse):
    if IB(3) then
        APA = clamp(IN(4), 50, 19000) // 1
        APS = clamp(IN(5) * 3.6, 400, 1500) // 1
        APH = ((IN(6) / M.pi * 180 + 360) // 1) % 360
    end

    -- when AP mannual throttle control, change speed target
    AP = IB(7)
    IFF = IB(8)
    if AP and (IB(5) or IB(6)) then
        APS = clamp(IN(5) * 3.6, 400, 1500) // 1
    end

    -- Fly to waypoint
    FTWP = IB(4)
    if FTWP and (IN(7) ~= 0 or IN(8) ~= 0) then
        -- override yawtarget
        APH = ((IN(6) / M.pi * 180 + 360) // 1) % 360
    end

    ON(1, APA or 0)
    ON(2, APS or 0)
    ON(3, APH or 0)
    ON(4, IFFK or 0)
end

function TBAO(v, f)
    return v == nil and "TBA" or string.format(f or "%.0f", v)
end

function onDraw()
    -- AP
    SC(UC2)
    DT(2, 1, "Auto Pilot")
    if not AP then
        SC(OFFC)
        DT(65, 1, "OFF")
        SC(UC2)
    else
        DT(65, 1, "ON")
    end
    DT(6, 7, "Altitude:")
    DT(50, 7, TBAO(APA))
    DT(6, 14, "Speed:")
    DT(50, 14, TBAO(APS))
    DT(6, 21, "Heading:")
    DT(50, 21, FTWP and "FTWP" or TBAO(APH))
    -- IFF
    DT(2, 29, "IFF")
    if not IFF then
        SC(OFFC)
        DT(65, 29, "OFF")
        SC(UC2)
    else
        DT(65, 29, "ON")
    end
    DT(6, 35, "IFFKEY:")
    DT(50, 35, TBAO(IFFK, "%04d"))

    -- btns
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
