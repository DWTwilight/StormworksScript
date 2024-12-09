S = screen
DRF = S.drawRectF
DL = S.drawLine
DT = S.drawText

IN = input.getNumber
IB = input.getBool

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

-- stores ammo ratio for each vid, vid -> ratio
AMMO_STATUS = {}

UC2 = H2RGB(PT("UI Secondary Color"))
DC = H2RGB(PT("Danger Color"))
WCNT = PN("Weapon Count")
IDX = 0
ONLINE = false

function SC(c)
    S.setColor(c.r, c.g, c.b, c.t)
end

function onTick()
    ONLINE = IB(32)
    IDX = IN(3)
    for vid = 1, WCNT do
        AMMO_STATUS[vid] = IN(33 - vid)
    end
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
    if ONLINE and IDX == 0 then
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
        DAS(46, 69, 12)
    end
end
