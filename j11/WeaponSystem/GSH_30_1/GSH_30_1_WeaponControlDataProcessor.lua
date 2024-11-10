IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

PN = property.getNumber

-- id on vehicle
VID = PN("Id on Vehicle")

function onTick()
    local active = IN(1) == VID
    if active then
        OB(1, IB(1))
    else
        OB(1, false)
    end
end
