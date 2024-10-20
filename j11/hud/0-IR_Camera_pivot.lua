IN = input.getNumber
ON = output.setNumber
PN = property.getNumber

LOF = PN("Look Offset Factor")
COF = -LOF / 200
CPO = 0.0605

function onTick()
    -- camera pivots
    ON(1, IN(7) * COF / 2)
    ON(2, IN(8) * COF - CPO)
end
