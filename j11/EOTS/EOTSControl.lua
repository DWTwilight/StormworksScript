m = math
pi = m.pi
pi2 = 2 * pi
sin = m.sin
cos = m.cos
at = m.atan
as = m.asin

S = screen
DR = S.drawRect
DT = S.drawText
DL = S.drawLine

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber
PT = P.getText

SF = string.format
TN = tonumber

function clamp(value, min, max)
    return m.min(max, m.max(value, min))
end

function H2RGB(e)
    e = e:gsub("#", "")
    return {
        r = TN("0x" .. e:sub(1, 2)),
        g = TN("0x" .. e:sub(3, 4)),
        b = TN("0x" .. e:sub(5, 6)),
        t = TN("0x" .. e:sub(7, 8))
    }
end

function SC(c)
    S.setColor(c.r, c.g, c.b, c.t)
end

function PIR(x, y, rectX, rectY, rectW, rectH)
    return x >= rectX and y >= rectY and x < rectX + rectW and y < rectY + rectH
end

function TBTN(x, y, w, h, text, color, toggleColor, toggled, tx, ty)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text,
        c = color,
        tc = toggleColor,
        toggled = toggled,
        tx = tx,
        ty = ty,
        toggle = function(btn, tx, ty)
            if PIR(tx, ty, btn.x, btn.y, btn.w, btn.h) then
                btn.toggled = not btn.toggled
            end
        end,
        draw = function(btn)
            SC(btn.toggled and btn.tc or btn.c)
            DR(btn.x, btn.y, btn.w, btn.h)
            DT(btn.x + tx, btn.y + ty, btn.text)
        end
    }
end

function ERM(E)
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

function tM(M)
    local N = { {}, {}, {} }
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function ER(v, B)
    local PN = Mv(B, { v[1], v[3], v[2] })
    return { PN[1], PN[3], PN[2] }
end

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
YMAX = PN("Yaw Max")     -- in radians
PMAX = PN("Pitch Max")   -- in radians
PMIN = PN("Pitch Min")   -- in radians
YBASE = PN("Yaw Base")   -- in radians, output will be yaw / YAW_BASE
PBASE = PN("Pitch Base") -- in radians, output will be pitch / PITCH_BASE
SEN = PN("Sensitivity")
SCR_W = PN("Screen Width")
-- heading config
HG = PN("Heading Gap")
HI = PN("Heading Interval")
HM = PN("Heading Margin")

TF = false
-- btns
IR_BTN = TBTN(1, SCR_W / 2 - 4, 17, 8, "IR", UC2, UC, false, 4, 2)
STA_BTN = TBTN(SCR_W - 19, SCR_W / 2 - 4, 17, 8, "STA", UC2, UC, false, 2, 2)
BTNS = {
    IR_BTN,
    STA_BTN
}
-- options
IR = false
STA = false
-- camera orientation global
CORG = nil
-- camera orientation local
CP = { 0, 0 }
ZOOM = 0
HANG = 0

function onTick()
    -- handle touchscreen input
    if IB(1) then
        local tx, ty = IN(1), IN(2)
        if not TF then
            -- handle touch
            for _, btn in ipairs(BTNS) do
                btn:toggle(tx, ty)
            end
            IR = IR_BTN.toggled
            STA = STA_BTN.toggled
        end
        TF = true
    else
        TF = false
    end
    -- set IR out
    OB(1, IR)
    local B = ERM({ IN(4), IN(6), IN(5) })
    if STA then
        -- stabilizer on
        local cameraTargetVectorLocal = ER(CORG, B)
        CP[1] = at(cameraTargetVectorLocal[1], cameraTargetVectorLocal[3]) -- yaw
        CP[2] = as(cameraTargetVectorLocal[2])                             -- pitch
    end
    -- apply mannual control
    ZOOM = IN(3)
    local zoomF = (1 - 0.98 * ZOOM * ZOOM)
    local mYaw, mPitch = IN(7), IN(8)
    CP[1] = clamp(CP[1] + mYaw * SEN * zoomF, -YMAX, YMAX)
    CP[2] = clamp(CP[2] + mPitch * SEN * zoomF, PMIN, PMAX)
    -- output camera pivot
    ON(1, CP[1] / YBASE)
    ON(2, CP[2] / PBASE)

    -- update global camera orientation
    CORG = ER({
        cos(CP[2]) * sin(CP[1]),
        sin(CP[2]),
        cos(CP[2]) * cos(CP[1]) }, tM(B))
    -- calculate headingAng(deg)
    HANG = (m.deg(at(CORG[1], CORG[3])) + 360) % 360
end

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

function dash(a, b)
    DL(a, b + 2, a + 3, b + 2)
end

function CST(a, b, s)
    if s == "0" then
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
    elseif s == "-" then
        dash(a, b)
    end
end

function DST(a, b, c)
    local l = #c
    for d = 1, l do
        local s = c:sub(d, d)
        CST(a, b, s)
        a = a + 4
    end
end

function onDraw()
    -- draw btns
    for _, btn in ipairs(BTNS) do
        btn:draw()
    end
    -- draw heading
    SC(UC)
    -- draw current heading
    local h = SF("%.0f", HANG)
    DST((SCR_W - #h * 4) / 2 + 1, 0, h)
    DR(SCR_W / 2 - 7, -2, 14, 8)
    -- draw scaleplate
    -- left
    for i = (HANG // 1) % HI, 180, HI do
        local x = (-i * HG / HI + SCR_W / 2)
        if x < HM then
            break
        end
        local ch = (HANG - i + 360) % 360
        if (ch // 1) % (2 * HI) == 0 then
            DL(x, 7, x, 9)
            if SCR_W / 2 - x > 10 then
                local chs = SF("%d", ch // 10)
                DST(x - #chs * 2 + 1, 0, chs)
            end
        else
            DL(x, 8, x, 9)
        end
    end
    -- right
    for i = HI - (HANG // 1) % HI, 180, HI do
        local x = (i * HG / HI + SCR_W / 2)
        if x > SCR_W - HM then
            break
        end
        local ch = (HANG + i) % 360
        if (ch // 1) % (2 * HI) == 0 then
            DL(x, 7, x, 9)
            if x - SCR_W / 2 > 10 then
                local chs = SF("%d", ch // 10)
                DST(x - #chs * 2 + 1, 0, chs)
            end
        else
            DL(x, 8, x, 9)
        end
    end
end
