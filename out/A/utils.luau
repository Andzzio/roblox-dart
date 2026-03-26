local fnA

function fnA()

	print("A")

end


local Exports = {
    fnA = fnA,
}
return Exports
