IN = input.getNumber
IB = input.getBool
ON = output.setNumber
OB = output.setBool

function onTick()
    local curAlert = IN(1)
    for rank = 1, 6 do
        OB(rank, curAlert == rank)
    end
end
