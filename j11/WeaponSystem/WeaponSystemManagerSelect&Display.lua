M = math

S = screen
DT = S.drawText
DRF = S.drawRectF
DL = S.drawLine

IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PT = P.getText
PN = P.getNumber

TN = tonumber

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
    return x >= rectX and y > rectY and x < rectX + rectW and y <= rectY + rectH
end

function PBTN(x, y, w, h, text, color, pressColor, tx, ty)
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
        cp = function(btn)
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

function Weap(vid, ammo, status)
    return {
        vid = vid,
        ammo = ammo,
        ta = ammo, -- total ammoCount
        status = status,
        update = function(w, ammo, status)
            w.ammo = ammo
            w.status = status
        end
    }
end

function WeapG(wid, type, guideMethods, defaultGuideMethod)
    return {
        wid = wid,
        wt = PT(string.format("WN_%d", wid)),
        type = type,
        gm = guideMethods,
        dgm = #guideMethods == 0 and -1 or defaultGuideMethod,
        ammo = 0, -- total value, will not change after init
        ws = {},
        upsertW = function(wg, vid, ammo, status)
            -- init stage, update ammo
            if wg.ws[vid] == nil then
                wg.ammo = wg.ammo + ammo
                wg.ws[vid] = Weap(vid, ammo, status)
            else
                wg.ws[vid]:update(ammo, status)
            end
        end,
        info = function(wg)
            -- return ammo count and current vid
            local a = 0
            local vid = 999
            for id, w in pairs(wg.ws) do
                a = a + w.ammo
                -- return min vid
                if w.ammo > 0 and id < vid then
                    vid = id
                end
            end
            return a, wg.ws[vid]
        end
    }
end

-- constants
-- guide method text
GMT = {"HUD", "RAD", "MAP", "EOTS"}
-- types
TT = {"Utility", "Cannon", "Auto Cannon", "Unguided Bomb", "Guided Bomb", "AA Misslie", "AS Misslie", "Rocket"}
STT = {"No Target", "Ready", "LAUCHING", "LAUCH"}

WCNT = PN("Weapon Count")
INITD = PN("Init Duration")
UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
DC = H2RGB(PT("Danger Color"))
DC2 = H2RGB(PT("Danger Secondary Color"))

WG = {} -- array, store in vid order
WGM = {} -- index mapping, wid -> index
WM = {} -- vid -> wid
IDX = 0 -- current weapon index, 0 for overview
GM = 0 -- current select guide method
SYS_S = false -- system switch
-- stores ammo ratio for each vid, vid -> ratio
AMMO_STATUS = {}

-- btns
DBTN = PBTN(75, 1, 21, 7, "DROP", DC, DC2, 1, 1)
-- guide method tab group
GBG = {
    x = 6,
    y = 31,
    w = 21,
    h = 7,
    gm = {},
    sgm = -1, -- selected guide method
    press = function(bg, tx, ty)
        for i, g in ipairs(bg.gm) do
            if PIR(tx, ty, bg.x + (i - 1) * bg.w, bg.y, bg.w, bg.h) then
                bg.sgm = g
                break
            end
        end
    end,
    draw = function(bg)
        for i, g in ipairs(bg.gm) do
            local c1, c2
            if bg.sgm == g then
                c1, c2 = UC2, UC
            else
                c1, c2 = UC, UC2
            end
            SC(c1)
            DRF(bg.x + (i - 1) * bg.w, bg.y, bg.w, bg.h)
            SC(c2)
            DT(bg.x + (i - 1) * bg.w + 1 + (4 - #GMT[g + 1]) * 2.5, bg.y + 1, GMT[g + 1])
        end
    end
}

function parseGM(guideMethodNum)
    local guideMethods = {}
    for i = 7, 0, -1 do
        if guideMethodNum & 1 == 1 then
            table.insert(guideMethods, 1, i)
        end
        guideMethodNum = guideMethodNum >> 1
    end
    return guideMethods
end

function clamp(val, min, max)
    return M.min(max, M.max(min, val))
end

function dropAll(v)
    for i = 1, WCNT do
        OB(i + WCNT, v)
    end
end

function onTick()
    SYS_S = IB(5)

    if INITD > 0 then
        -- init weapon group info
        for i = 1, WCNT do
            local num = IN(2 * i - 1)
            if num ~= 0 then
                local wid, type, guideMethodNum, defaultGuideMethod = num & 0xFF, num >> 8 & 0xF, num >> 12 & 0xFF,
                    num >> 20
                if WGM[wid] == nil then
                    -- new weapon
                    table.insert(WG, WeapG(wid, type, parseGM(guideMethodNum), defaultGuideMethod))
                    -- update weapon group index mapping
                    WGM[wid] = #WG
                end
                -- update weapon mapping
                WM[i] = wid
            end
        end
        INITD = INITD - 1
    end

    -- after init
    if INITD <= 0 then
        -- upsert weapon info
        local lauchFlag = false
        for i = 1, WCNT do
            local num, wid = IN(2 * i), WM[i]
            if wid ~= nil then
                -- weapon group has initialized
                local ammo, status = num & 0xFFF, num >> 12 & 3
                WG[WGM[wid]]:upsertW(i, ammo, status)

                -- lauch detach control
                local lauch = i > 1 and status == 3
                OB(i, lauch)
                lauchFlag = lauchFlag or lauch
            else
                OB(i, false)
            end
        end

        -- lauch buzzer
        OB(31, lauchFlag)

        -- weapon switch control
        local sf = false
        if SYS_S then
            -- system on
            if IB(1) and IB(4) then
                -- next weapon pulse
                IDX = clamp(IDX + 1, 0, #WG)
                sf = true
            elseif IB(2) and IB(4) then
                -- previous weapon pulse
                IDX = clamp(IDX - 1, 0, #WG)
                sf = true
            end
        else
            -- system off
            IDX = 0
        end

        -- get current weapon, may be nil!
        local _, currentWeapon
        if IDX > 0 then
            local wg = WG[IDX]
            _, currentWeapon = wg:info()

            if sf then
                -- update guide method btn group
                GBG.gm = wg.gm
                local resetFlag = true
                for _, gm in ipairs(GBG.gm) do
                    if gm == GBG.sgm then
                        resetFlag = false
                    end
                end
                if resetFlag then
                    GBG.sgm = wg.dgm
                end
            end
        else
            GBG.gm = {}
            GBG.sgm = -1
        end

        dropAll(false)
        -- touch control
        if IB(3) then
            local tx, ty = IN(WCNT * 2 + 1), IN(WCNT * 2 + 2)
            DBTN:press(tx, ty)

            if DBTN.op then
                -- release selected
                if IDX == 0 then
                    -- release all
                    dropAll(true)
                elseif currentWeapon ~= nil then
                    -- release current weapon
                    OB(currentWeapon.vid + WCNT, true)
                end
            elseif IDX > 0 then
                -- check guide group press
                GBG:press(tx, ty)
            end
        else
            DBTN:cp()
        end

        -- set outputs
        -- current selected weapon (vid)
        ON(1, currentWeapon ~= nil and currentWeapon.vid or 0)
        -- selected guide method
        ON(2, GBG.sgm)
        ON(3, IDX)

        -- update each weapon's ammo status
        for vid = 1, WCNT do
            AMMO_STATUS[vid] = 0
            local wid = WM[vid]
            if wid ~= nil then
                local weap = WG[WGM[wid]].ws[vid]
                if weap ~= nil and weap.ta ~= 0 then
                    AMMO_STATUS[vid] = weap.ammo / weap.ta
                end
            end
        end
    end
    OB(32, SYS_S)
end

function DML(x1, y1, x2, y2)
    DL(x1, y1, x2, y2)
    DL(95 - x1, y1, 95 - x2, y2)
end

function DAS(x, y, vid)
    SC(DC)
    DRF(x, y, 4, 15)
    local ammoRatio = AMMO_STATUS[vid]
    if ammoRatio == nil then
        ammoRatio = 0
    end
    local ammoHeight = (15 * ammoRatio) // 1
    SC(UC2)
    DRF(x, y + 15 - ammoHeight, 4, ammoHeight)
end

function onDraw()
    if SYS_S then
        DBTN:draw()
        if IDX > 0 then
            local wg = WG[IDX]
            SC(UC2)
            DT(2, 2, wg.wt)
            DT(2, 9, TT[wg.type + 1])
            DL(0, 15, 96, 15)
            DT(2, 17, "STAT:")
            DT(2, 24, "Guide:")

            -- draw ammo
            local ammo, w = wg:info()
            -- ammo text
            local at = string.format("%d/%d", ammo, wg.ammo)
            SC(ammo == 0 and DC or UC2)
            DT(4, 89, at)

            -- draw status
            SC((ammo == 0 or w == nil or w.status == 0) and DC or UC2)
            if ammo == 0 or w == nil then
                DT(30, 17, "EMPTY")
            else
                DT(30, 17, STT[w.status + 1])
            end

            -- draw guide btn group
            GBG:draw()
        else
            -- draw overview
            -- overview page
            SC(UC2)
            -- title
            DT(2, 2, "WEAPON")
            DT(2, 8, "STATUS")
            -- J11 overview image
            DML(43, 0, 36, 34)
            DML(36, 34, 3, 63)
            DML(3, 63, 3, 78)
            DML(3, 78, 34, 67)
            DML(34, 67, 34, 76)
            DML(34, 76, 19, 95)
            -- ammo status
            -- #1 gun
            DAS(50, 10, 1)
            -- #2
            DAS(2, 63, 2)
            -- #3
            DAS(90, 63, 3)
            -- #4
            DAS(11, 58, 4)
            -- #5
            DAS(81, 58, 5)
            -- #6
            DAS(19, 53, 6)
            -- #7
            DAS(73, 53, 7)
            -- #8
            DAS(27, 46, 8)
            -- #9
            DAS(65, 46, 9)
            -- #10
            DAS(39, 41, 10)
            -- #11
            DAS(53, 41, 11)
            -- #13
            DAS(46, 36, 13)
            -- #12
            DAS(46, 60, 12)
        end
    else
        SC(DC)
        DT(32, 43, "OFFLINE")
    end
end
