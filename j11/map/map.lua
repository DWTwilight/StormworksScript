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

function dash(a, b)
    DL(a, b + 2, a + 3, b + 2)
end

function plus(a, b)
    DL(a, b + 2, a + 3, b + 2)
    DL(a + 1, b + 1, a + 1, b + 2)
    DL(a + 1, b + 3, a + 1, b + 4)
end

function RR(a, b)
    DC(a + 1, b + 1, 1)
    DL(a, b, a, b + 5)
    DL(a + 2, b + 3, a + 2, b + 5)
end

function CST(a, b, s)
    if s == "-" then
        dash(a, b)
    elseif s == "+" then
        plus(a, b)
    elseif s == "R" then
        RR(a, b)
    end
end

function STLen(s)
    local len = 0
    for d = 1, string.len(s) do
        local sin = s:sub(d, d)
        if len ~= 0 then
            len = len + 1
        end
        if sin == "." or sin == " " then
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
        if sin == "." or sin == " " then
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

function PushButton(x, y, w, h, text, color, pressColor, visible)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        tlen = STLen(text),
        c = color,
        pc = pressColor,
        pressed = false,
        onPress = false,
        v = visible,
        press = function(btn, tx, ty)
            if btn.v then
                local pressed = PIR(tx, ty, btn.x, btn.y, btn.w, btn.h)
                btn.onPress = pressed and not btn.pressed
                btn.pressed = pressed
            else
                btn.onPress = false
                btn.pressed = false
            end
        end,
        clearPress = function(btn)
            btn.onPress = false
            btn.pressed = false
        end,
        draw = function(btn)
            if btn.v then
                local c1, c2
                if btn.pressed then
                    c1, c2 = btn.pc, btn.c
                else
                    c1, c2 = btn.c, btn.pc
                end
                SC(c1)
                DRF(btn.x, btn.y, btn.w, btn.h)
                SC(c2)
                DST(btn.x + btn.w // 2 - btn.tlen // 2, btn.y + (btn.h - 5) / 2, btn.text)
            end
        end
    }
end

X, Y, YAW = 0, 0, 0                   -- posX, posY, yaw
MX, MY, MZ = 0, 0, PN("Initial Zoom") -- mapPosX, mapPosY, mapZoom
MTX, MTY = 0, 0                       --mapTargetPosX, mapTargetPosY
FM = true                             -- auto follow mode, mapPos will follow vehicle pos
TOUCH_FLAG = false
UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
SCR_W, SCR_H = PN("Screen Width"), PN("Screen Height")
ZOOM_F = PN("Zoom Sensitivity")
SMOOTH_F = PN("Smooth Factor")

-- buttons
ZOOM_IN_BTN = PushButton(SCR_W - 11, SCR_H - 5, 5, 5, "+", UC, UC2, true)
ZOOM_OUT_BTN = PushButton(SCR_W - 5, SCR_H - 5, 5, 5, "-", UC, UC2, true)
RESET_BTN = PushButton(SCR_W - 7, 0, 7, 7, "R", UC, UC2, false)
BTNS = { ZOOM_IN_BTN, ZOOM_OUT_BTN, RESET_BTN }

function clamp(value, min, max)
    return MIN(max, MAX(value, min))
end

function lerp(target, value, gain)
    return value + (target - value) * gain
end

function calZoom(z)
    return 49.9 * (z - 1) ^ 2 + 0.1
end

function onTick()
    -- handle touch input
    if IB(1) then
        local tx, ty = IN(4), IN(5)

        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        -- zoom buttons
        if ZOOM_IN_BTN.pressed then
            MZ = clamp(MZ + ZOOM_F, 0, 1)
        elseif ZOOM_OUT_BTN.pressed then
            MZ = clamp(MZ - ZOOM_F, 0, 1)
        elseif RESET_BTN.pressed then
            if RESET_BTN.onPress then
                FM = true
                RESET_BTN.v = false
            end
        else
            -- map touch
            if not TOUCH_FLAG then
                FM = false
                MTX, MTY = map.screenToMap(MX, MY, calZoom(MZ), SCR_W, SCR_H, tx, ty)
                RESET_BTN.v = true
            end
        end
        TOUCH_FLAG = true
    else
        TOUCH_FLAG = false
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end
    end

    --handle keyboard coord
    if IB(2) then
        FM = false
        MTX, MTY = IN(6), IN(7)
        RESET_BTN.v = true
    end

    -- get current vehicle pos and heading
    X, Y, YAW = IN(1), IN(2), IN(3)
    if FM then
        MTX = X
        MTY = Y
    end

    MX = lerp(MTX, MX, SMOOTH_F)
    MY = lerp(MTY, MY, SMOOTH_F)
    ON(1, MX)
    ON(2, MY)
    ON(3, calZoom(MZ))
end

function onDraw()
    DM(MX, MY, calZoom(MZ))
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
end
