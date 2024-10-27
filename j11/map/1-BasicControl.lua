M = math
MAX = M.max
MIN = M.min
COS = M.cos
SIN = M.sin

M2S = map.mapToScreen

S = screen
DRF = S.drawRectF
DTAF = S.drawTriangleF
DT = S.drawText
DL = S.drawLine

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber
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
    return x >= rectX and y > rectY and x < rectX + rectW and y <= rectY + rectH
end

function PushButton(x, y, w, h, text, color, pressColor, visible, tox, toy, df)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        c = color,
        pc = pressColor,
        pressed = false,
        onPress = false,
        v = visible,
        tox = tox,
        toy = toy,
        df = df,
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
                if df then
                    df(btn.x + btn.tox, btn.y + btn.toy)
                else
                    DT(btn.x + btn.tox, btn.y + btn.toy, btn.text)
                end
            end
        end
    }
end

X, Y, YAW = 0, 0, 0                            -- posX, posY, yaw
MX, MY, MZ, ZOOM = 0, 0, PN("Initial Zoom"), 0 -- mapPosX, mapPosY, mapZoom, zoom value
MTX, MTY = 0, 0                                --mapTargetPosX, mapTargetPosY
FM = true                                      -- auto follow mode, mapPos will follow vehicle pos
TOUCH_FLAG = false
UC = H2RGB(PT("Basic Primary Color"))
UC2 = H2RGB(PT("Basic Secondary Color"))
SIC = H2RGB(PT("Self Icon Color"))
SCR_W, SCR_H = PN("Screen Width"), PN("Screen Height")
DW, DH = PN("Display Width"), PN("Display Height")
ZOOM_F = PN("Zoom Sensitivity")
SMOOTH_F = PN("Smooth Factor")

-- button custom draw
function DZoomIn(x, y)
    DL(x, y + 2, x + 5, y + 2)
    DL(x + 2, y, x + 2, y + 2)
    DL(x + 2, y + 3, x + 2, y + 5)
end

function DZoomOut(x, y)
    DL(x, y + 2, x + 5, y + 2)
end

-- buttons
ZOOM_IN_BTN = PushButton(SCR_W - 17, SCR_H - 9, 7, 7, "+", UC, UC2, true, 1, 1, DZoomIn)
ZOOM_OUT_BTN = PushButton(SCR_W - 9, SCR_H - 9, 7, 7, "-", UC, UC2, true, 1, 1, DZoomOut)
RESET_BTN = PushButton(SCR_W - 10, 2, 8, 9, "R", UC, UC2, false, 2, 2)
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

function transformTouchInput(tx, ty)
    return tx * SCR_W / DW + (SCR_W / DW) // 3, ty * SCR_H / DH + (SCR_H / DH) // 3
end

function onTick()
    -- wether to clear focus, default false
    OB(3, false)

    -- handle touch input
    if IB(1) then
        local tx, ty = transformTouchInput(IN(4), IN(5))

        for _, btn in ipairs(BTNS) do
            btn:press(tx, ty)
        end

        local pressFlag = true

        if ZOOM_IN_BTN.pressed then
            -- zoom in btn
            MZ = clamp(MZ + ZOOM_F, 0, 1)
        elseif ZOOM_OUT_BTN.pressed then
            -- zoom out btn
            MZ = clamp(MZ - ZOOM_F, 0, 1)
        elseif RESET_BTN.pressed and RESET_BTN.onPress then
            FM = true
            RESET_BTN.v = false
            OB(3, true)
        else
            pressFlag = false
        end

        -- output touch data
        if pressFlag then
            -- touch intercepted
            OB(1, false) -- touch
            OB(2, false) -- onTouch
            ON(1, 0)     -- tx
            ON(2, 0)     -- ty
        else
            -- touch will forward to next script
            OB(1, true)           -- touch
            OB(2, not TOUCH_FLAG) -- onTouch
            ON(1, tx)             -- tx
            ON(2, ty)             -- ty
        end

        TOUCH_FLAG = true
    else
        TOUCH_FLAG = false
        for _, btn in ipairs(BTNS) do
            btn:clearPress()
        end

        -- output touch data
        OB(1, false) -- touch
        OB(2, false) -- onTouch
        ON(1, 0)     -- tx
        ON(2, 0)     -- ty
    end

    -- handle keyboard coord
    if IB(2) then
        FM = false
        MTX, MTY = IN(6), IN(7)
        RESET_BTN.v = true
        OB(3, true)
    end

    -- handle map touch
    if IB(3) then
        FM = false
        MTX, MTY = IN(8), IN(9)
        RESET_BTN.v = true
        OB(3, true)
    end

    -- focus on target
    if IB(4) and not RESET_BTN.onPress and not IB(2) and not IB(3) then
        FM = false
        MTX, MTY = IN(10), IN(11)
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
    ZOOM = calZoom(MZ)
    ON(3, MX)
    ON(4, MY)
    ON(5, ZOOM)
    ON(6, X)
    ON(7, Y)
end

function rotate(x, y, r)
    return -x * COS(r) - y * SIN(r), y * COS(r) - x * SIN(r)
end

function onDraw()
    -- drawControl Buttons
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
    -- drawSelf Icon
    SC(SIC)
    local sx, sy = M2S(MX, MY, ZOOM, SCR_W, SCR_H, X, Y)
    local x1, y1 = rotate(0, -5, YAW)
    local x2, y2 = rotate(3, 3, YAW)
    local x3, y3 = rotate(-3, 3, YAW)
    DTAF(sx + x1, sy + y1, sx + x2, sy + y2, sx + x3, sy + y3)
end
