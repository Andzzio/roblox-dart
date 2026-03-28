local fnB

function fnB()

	print("B")
end


local Exports = {
    fnB = fnB,
}
return Exports
