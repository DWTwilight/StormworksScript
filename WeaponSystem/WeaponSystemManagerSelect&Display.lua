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

function Weapon(vid, ammo, status)
    return {
        vid = vid,
        ammo = ammo,
        status = status,
        update = function(w, ammo, status)
            w.ammo = ammo
            w.status = status
        end
    }
end

function WeaponGroup(wid, type, guideMethods, defaultGuideMethod)
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
                wg.ws[vid] = Weapon(vid, ammo, status)
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
GMT = { "HUD", "RAD", "MAP", "EOTS" }
-- types
TT = { "Utility", "Cannon", "Auto Cannon", "Unguided Bomb", "Guided Bomb", "AA Misslie", "AS Misslie", "Rocket" }
STT = { "Require Target", "Ready", "LAUCHING", "LAUCH" }

WEAPON_COUNT = PN("Weapon Count")
INIT_DURATION = PN("Init Duration")
UC = H2RGB(PT("UI Primary Color"))
UC2 = H2RGB(PT("UI Secondary Color"))
DC = H2RGB(PT("Danger Color"))
DC2 = H2RGB(PT("Danger Secondary Color"))

WEAPON_GROUPS = {}        -- array, store in vid order
WEAPON_GROUP_MAPPING = {} -- index mapping, wid -> index
WEAPON_MAPPING = {}       -- vid -> wid
INDEX = 0                 -- current weapon index, 0 for overview
GUIDE = 0                 -- current select guide method
SYS_S = false             -- system switch

-- btns
RELEASE_BTN = PBTN(60, 1, 36, 7, "RELEASE", DC, DC2, 1, 1)
-- guide method tab group
GUIDE_BTN_GROUP = {
    x = 6,
    y = 31,
    w = 17,
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
            DT(bg.x + (i - 1) * bg.w + 1, bg.y + 1, GMT[g + 1])
        end
    end
}

function parseGuideMethods(guideMethodNum)
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

function releaseAll()
    for i = 1, WEAPON_COUNT do
        OB(i, true)
    end
end

function onTick()
    SYS_S = IB(5)

    if INIT_DURATION > 0 then
        -- init weapon group info
        for i = 1, WEAPON_COUNT do
            local num = IN(2 * i - 1)
            if num ~= 0 then
                local wid, type, guideMethodNum, defaultGuideMethod =
                    num & 0xFF,
                    num >> 8 & 0xF,
                    num >> 12 & 0xFF,
                    num >> 20
                if WEAPON_GROUP_MAPPING[wid] == nil then
                    -- new weapon
                    table.insert(WEAPON_GROUPS,
                        WeaponGroup(wid, type, parseGuideMethods(guideMethodNum), defaultGuideMethod))
                    -- update weapon group index mapping
                    WEAPON_GROUP_MAPPING[wid] = #WEAPON_GROUPS
                end
                -- update weapon mapping
                WEAPON_MAPPING[i] = wid
            end
        end
        INIT_DURATION = INIT_DURATION - 1
    end

    -- after init
    if INIT_DURATION <= 0 then
        -- upsert weapon info
        for i = 1, WEAPON_COUNT do
            local num, wid = IN(2 * i), WEAPON_MAPPING[i]
            if wid ~= nil then
                -- weapon group has initialized
                local ammo, status = num & 0xFFF, num >> 12 & 3
                WEAPON_GROUPS[WEAPON_GROUP_MAPPING[wid]]:upsertW(i, ammo, status)

                -- lauch detach control
                OB(i, status == 3)
            else
                OB(i, false)
            end
        end

        -- weapon switch control
        local sf = false
        if SYS_S then
            -- system on
            if IB(1) and IB(4) then
                -- next weapon pulse
                INDEX = clamp(INDEX + 1, 0, #WEAPON_GROUPS)
                sf = true
            elseif IB(2) and IB(4) then
                -- previous weapon pulse
                INDEX = clamp(INDEX - 1, 0, #WEAPON_GROUPS)
                sf = true
            end
        else
            -- system off
            INDEX = 0
        end

        -- get current weapon, may be nil!
        local _, currentWeapon
        if INDEX > 0 then
            local wg = WEAPON_GROUPS[INDEX]
            _, currentWeapon = wg:info()

            if sf then
                -- update guide method btn group
                GUIDE_BTN_GROUP.gm = wg.gm
                GUIDE_BTN_GROUP.sgm = wg.dgm
            end
        else
            GUIDE_BTN_GROUP.gm = {}
            GUIDE_BTN_GROUP.sgm = -1
        end


        -- touch control
        if IB(3) then
            local tx, ty = IN(WEAPON_COUNT * 2 + 1), IN(WEAPON_COUNT * 2 + 2)
            RELEASE_BTN:press(tx, ty)

            if RELEASE_BTN.op then
                -- release selected
                if INDEX == 0 then
                    -- release all
                    releaseAll()
                elseif currentWeapon ~= nil then
                    -- release current weapon
                    OB(currentWeapon.vid, true)
                end
            elseif INDEX > 0 then
                -- check guide group press
                GUIDE_BTN_GROUP:press(tx, ty)
            end
        else
            RELEASE_BTN:clearPress()
        end

        -- set outputs
        -- current selected weapon (vid)
        ON(1, currentWeapon ~= nil and currentWeapon.vid or 0)
        -- selected guide method
        ON(2, GUIDE_BTN_GROUP.sgm)
    end
end

function onDraw()
    if SYS_S then
        RELEASE_BTN:draw()
        if INDEX > 0 then
            local wg = WEAPON_GROUPS[INDEX]
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
            GUIDE_BTN_GROUP:draw()
        end
    else
        SC(DC)
        DT(32, 43, "OFFLINE")
    end
end
