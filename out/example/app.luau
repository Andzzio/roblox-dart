local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local math_utils = _RD.import(script, "modulos", "math_utils")
local add = math_utils.add
local Calculator = math_utils.Calculator

function main()

	local result = add(10, 20)

	print(`Sum: {result}`)
	local product = Calculator.multiply(5, 5)

	print(`Product: {product}`)
end

main()
