M = math
PI = M.pi
PI2 = 2 * PI
SIN = M.sin
COS = M.cos
AT = M.atan
AS = M.asin
ABS = M.abs

S = screen
DR = S.drawRect
DT = S.drawText
DL = S.drawLine
DC = S.drawCircle

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PN = P.getNumber
PT = P.getText

PR = pairs
IPR = ipairs
SF = string.format
TN = tonumber

function clamp(value, min, max)
    return M.min(max, M.max(value, min))
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
    return {{COS(qy) * COS(qz), COS(qx) * COS(qy) * SIN(qz) + SIN(qx) * SIN(qy),
             SIN(qx) * COS(qy) * SIN(qz) - COS(qx) * SIN(qy)}, {-SIN(qz), COS(qx) * COS(qz), SIN(qx) * COS(qz)},
            {SIN(qy) * COS(qz), COS(qx) * SIN(qy) * SIN(qz) - SIN(qx) * COS(qy),
             SIN(qx) * SIN(qy) * SIN(qz) + COS(qx) * COS(qy)}}
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
    local N = {{}, {}, {}}
    for i = 1, 3 do
        for j = 1, 3 do
            N[i][j] = M[j][i]
        end
    end
    return N
end

function ER(v, B)
    local PN = Mv(B, {v[1], v[3], v[2]})
    return {PN[1], PN[3], PN[2]}
end

function createCoordConvertMatrix(yawRad, pitchRad)
    return {{COS(yawRad), 0, -SIN(yawRad)}, {-SIN(yawRad) * SIN(pitchRad), COS(pitchRad), -COS(yawRad) * SIN(pitchRad)},
            {SIN(yawRad) * COS(pitchRad), SIN(pitchRad), COS(yawRad) * COS(pitchRad)}}
end

function MMul(v, M)
    local u = {0, 0, 0}
    for i = 1, 3 do
        for j = 1, 3 do
            u[i] = u[i] + M[i][j] * v[j]
        end
    end
    return u[1], u[2], u[3]
end

function RT(id, x, y, z, f, ttl)
    return {
        id = id,
        f = f,
        ttl = ttl,
        ttlF = ttl, -- for calculation
        pos = {x, y, z},
        lockF = 0,
        speedL = nil, -- local speed per tick, appose to player
        update = function(t, x, y, z, ttl, f)
            -- update speed
            t.speedL = {(x - t.pos[1]) / t.ttlF, (y - t.pos[2]) / t.ttlF, (z - t.pos[3]) / t.ttlF}
            t.pos = {x, y, z}
            t.ttl = ttl
            t.ttlF = ttl
            t.f = f
        end,
        curAbsPos = function(t)
            if t.speedL == nil then
                return t.pos[1] + OFFSET_X, t.pos[2] + OFFSET_Y, t.pos[3] + OFFSET_Z
            end
            local totalTickOffset = DELAY_C + t.ttlF - t.ttl
            return t.pos[1] + t.speedL[1] * totalTickOffset + OFFSET_X,
                t.pos[2] + t.speedL[2] * totalTickOffset + OFFSET_Y, t.pos[3] + t.speedL[3] * totalTickOffset + OFFSET_Z
        end,
        curAbsPivot = function(t)
            local x, y, z = t:curAbsPos()
            return AT(x, z), AT(y, (x ^ 2 + z ^ 2) ^ 0.5)
        end,
        curPos = function(t)
            local x, y, z = t:curAbsPos()
            return MMul({x, y, z}, CAMERA_COORD_MAT)
        end,
        draw = function(t)
            local x, y, z = t:curPos()
            -- check if in front
            if z > 0 then
                local sx, sy = SCR_W / 2 + SCR_W / FOV * AT(x, z) - HRTW - 1,
                    SCR_W / 2 - SCR_W / FOV * AT(y, (x ^ 2 + z ^ 2) ^ 0.5) - HRTW - 1
                if t.lockF == 0 then
                    -- not locked
                    SC(UC)
                elseif t.lockF == 1 then
                    -- locking
                    SC(LOCKB and UC2 or UC)
                else
                    -- locked
                    SC(UC2)
                end

                DR(sx, sy, RTW + 1, RTW + 1)
                if t.f then
                    DL(sx, sy, sx + RTW + 1, sy + RTW + 1)
                    DL(sx + RTW + 1, sy, sx, sy + RTW + 1)
                end
                -- draw distance
                local distanceText = SF("%.1f", (x ^ 2 + y ^ 2 + z ^ 2) ^ 0.5 / 1000)
                DT(sx - #distanceText * 2.5 + 4, sy + RTW + 3, distanceText)
            end
        end,
        canLock = function(t, la)
            local x, y, z = t:curPos()
            if z > 0 then
                local a = AT((x ^ 2 + y ^ 2) ^ 0.5, z)
                return a < t.lockF == 2 and la * 4 or la, a
            end
            return false, 0
        end
    }
end

UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))

YMAX = PN("Yaw Max") -- in radians
PMAX = PN("Pitch Max") -- in radians
PMIN = PN("Pitch Min") -- in radians
YBASE = PN("Yaw Base") -- in radians, output will be yaw / YAW_BASE
PBASE = PN("Pitch Base") -- in radians, output will be pitch / PITCH_BASE
SEN = PN("Sensitivity")
SCR_W = PN("Screen Width")
-- heading config
HG = PN("Heading Gap")
HI = PN("Heading Interval")
HM = PN("Heading Margin")
FOV_MIN = PN("FOV Min(rad)")
FOV_MAX = PN("FOV Max(rad)")
BASE_FOV = PN("Base FOV")
DELAY_C = PN("Delay Compensate(ticks)")
RTW = PN("Rardar Target Width")
HRTW = RTW // 2
LAP = PN("Lock Angle Percentage") -- opposed to FOV
OFFSET_X = PN("Camera Offset X")
OFFSET_Y = PN("Camera Offset Y")
OFFSET_Z = PN("Camera Offset Z")

TF = false -- touch flag
-- btns
IR_BTN = TBTN(1, SCR_W / 2 - 4, 17, 8, "IR", UC2, UC, false, 4, 2)
STA_BTN = TBTN(SCR_W - 19, SCR_W / 2 - 4, 17, 8, "STA", UC2, UC, false, 2, 2)
BTNS = {IR_BTN, STA_BTN}
-- options
IR = false
STA = false
-- camera orientation global
CORG = nil
-- camera orientation local
CP = {0, 0}
HANG = 0
-- camera FOV
FOV = 0
CAMERA_COORD_MAT = nil
RTS = {}
LOCK_T = nil
LOCKB = false

function onTick()
    -- get radar data
    local ttl = IN(5)
    for i = 1, 4 do
        local id, x, y, z, f = IN(i), IN(3 * i + 18), IN(3 * i + 19), IN(3 * i + 20), IB(i)
        -- add/update target to list
        if id ~= 0 then
            if RTS[id] ~= nil then
                -- do update
                RTS[id]:update(x, y, z, ttl, f)
            else
                -- insert new target
                RTS[id] = RT(id, x, y, z, f, ttl)
            end
        end
    end
    -- refresh radar data
    local toRM = {}
    for id, t in PR(RTS) do
        t.ttl = t.ttl - 1
        if t.ttl < 0 then
            table.insert(toRM, id)
        end
    end
    for _, id in IPR(toRM) do
        RTS[id] = nil
        if LOCK_T ~= nil and id == LOCK_T.id then
            LOCK_T = nil
        end
    end

    -- handle touchscreen input
    if IB(5) then
        local tx, ty = IN(7), IN(8)
        if not TF then
            -- handle touch
            for _, btn in IPR(BTNS) do
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

    -- calculate current FOV
    FOV = (FOV_MIN - FOV_MAX) * IN(6) + FOV_MAX
    -- rotation matrix
    local B = ERM({IN(9), IN(11), IN(10)})
    -- get current camera coord convert matrix
    CAMERA_COORD_MAT = createCoordConvertMatrix(CP[1], CP[2])

    if IN(12) == 3 then
        -- enable EOTS lock
        LOCK_PULSE, LOCKB = IB(6), IB(7)
        -- calculate lock angle
        local la = FOV * LAP

        -- update current lock status
        if LOCK_T ~= nil and LOCK_T.lockF == 2 then
            -- have a locked target
            local canLock, _ = LOCK_T:canLock(la)
            if LOCK_PULSE or not canLock then
                -- cancel lock
                LOCK_T.lockF = 0
                LOCK_T = nil
            end
        else
            -- update current lockable target
            local minA = la
            local lockableTarget = nil
            for _, t in PR(RTS) do
                local canLock, a = t:canLock(la)
                if canLock and a < minA then
                    lockableTarget = t
                    minA = a
                end
            end
            if lockableTarget ~= nil then
                -- replace lockT
                if LOCK_T ~= nil and LOCK_T.id ~= lockableTarget.id then
                    LOCK_T.lockF = 0
                end
                LOCK_T = lockableTarget
                LOCK_T.lockF = 1
            elseif LOCK_T ~= nil then
                -- cancel locking
                LOCK_T.lockF = 0
                LOCK_T = nil
            end

            -- handle lock pulse
            if LOCK_T ~= nil and LOCK_PULSE then
                LOCK_T.lockF = 2
            end
        end
    else
        if LOCK_T ~= nil then
            -- cancel locking
            LOCK_T.lockF = 0
            LOCK_T = nil
        end
    end

    if STA then
        -- stabilizer on
        if LOCK_T ~= nil and LOCK_T.lockF == 2 then
            -- has locked target
            local absYaw, absPitch = LOCK_T:curAbsPivot()
            CP[1] = absYaw
            CP[2] = absPitch
        else
            local cameraTargetVectorLocal = ER(CORG, B)
            CP[1] = AT(cameraTargetVectorLocal[1], cameraTargetVectorLocal[3]) -- yaw
            CP[2] = AS(cameraTargetVectorLocal[2]) -- pitch
        end
    end
    -- apply mannual control
    local mYaw, mPitch = IN(13), IN(14)
    CP[1] = clamp(CP[1] + mYaw * SEN * FOV, -YMAX, YMAX)
    CP[2] = clamp(CP[2] + mPitch * SEN * FOV, PMIN, PMAX)
    -- output camera pivot
    ON(1, CP[1] / YBASE)
    ON(2, CP[2] / PBASE)
    if LOCK_T == nil then
        ON(3, 0)
        ON(4, 0)
    else
        ON(3, LOCK_T.lockF == 2 and LOCK_T.id or 0)
        ON(4, LOCK_T.lockF)
    end

    -- update global camera orientation
    CORG = ER({COS(CP[2]) * SIN(CP[1]), SIN(CP[2]), COS(CP[2]) * COS(CP[1])}, tM(B))
    -- calculate headingAng(deg)
    HANG = (M.deg(AT(CORG[1], CORG[3])) + 360) % 360
end

function onDraw()
    -- draw crosshair
    SC(UC2)
    local w, h = SCR_W / 2, SCR_W / 2;
    DL(w - 2, h, w, h)
    DL(w + 1, h, w + 3, h)
    DL(w, h - 2, w, h)
    DL(w, h + 1, w, h + 3)

    -- draw targets 
    if LOCK_T ~= nil and LOCK_T.lockF == 2 then
        -- only draw locked target
        LOCK_T:draw()
    else
        -- draw radar targets
        for _, t in PR(RTS) do
            t:draw()
        end
    end

    -- draw btns
    for _, btn in IPR(BTNS) do
        btn:draw()
    end
    -- draw heading
    SC(UC)
    -- draw current heading
    local h = SF("%.0f", HANG)
    DT((SCR_W - #h * 5) / 2 + 1, 0, h)
    DR(SCR_W / 2 - 9, -2, 17, 8)
    -- draw scaleplate
    -- left
    for i = (HANG // 1) % HI, 180, HI do
        local x = (-i - HANG % 1) * HG / HI + SCR_W / 2
        if x < HM then
            break
        end
        local ch = (HANG - i + 360) % 360
        if (ch // 1) % (2 * HI) == 0 then
            DL(x, 7, x, 9)
            if SCR_W / 2 - x > 12 then
                local chs = SF("%d", ch // 10)
                DT(x - #chs * 2.5 + 1, 0, chs)
            end
        else
            DL(x, 8, x, 9)
        end
    end
    -- right
    for i = HI - (HANG // 1) % HI, 180, HI do
        local x = (i - HANG % 1) * HG / HI + SCR_W / 2
        if x > SCR_W - HM then
            break
        end
        local ch = (HANG + i) % 360
        if (ch // 1) % (2 * HI) == 0 then
            DL(x, 7, x, 9)
            if x - SCR_W / 2 > 12 then
                local chs = SF("%d", ch // 10)
                DT(x - #chs * 2.5 + 1, 0, chs)
            end
        else
            DL(x, 8, x, 9)
        end
    end

    -- draw zoom ratio
    DT(6, SCR_W - 6, SF("X%.1f", BASE_FOV / FOV))
end
