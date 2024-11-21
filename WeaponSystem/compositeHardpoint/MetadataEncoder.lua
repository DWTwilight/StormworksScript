IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

P = property
PT = P.getText
PN = P.getNumber

function convertSecondMetadataNumber(status, ammoCount)
    return status << 12 | ammoCount
end

function onTick()
    local metaDatas = { { IN(1), IN(2) }, { IN(3), IN(4) } }

    if metaDatas[1][1] == 0 and metaDatas[2][1] == 0 then
        -- no weapon present
        ON(1, 0)
        ON(2, 0)
        ON(3, 0)
    else
        -- if weapon1's meta is 0, it has lauched
        local currentWeaponIndex = metaDatas[1][1] == 0 and 2 or 1
        -- set currentWeaponIndex
        ON(3, currentWeaponIndex)

        -- set the first meta num
        ON(1, metaDatas[currentWeaponIndex][1])

        local ammo, status =
            metaDatas[currentWeaponIndex][2] & 0xFFF,
            metaDatas[currentWeaponIndex][2] >> 12 & 3
        -- if currentIndex is 1, need to add the second
        if currentWeaponIndex == 1 then
            ammo = ammo + metaDatas[2][2] & 0xFFF
        end
        -- set the second meta num
        ON(2, convertSecondMetadataNumber(status, ammo))
    end
end
