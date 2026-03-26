local main

local math_utils = require(script.Parent.math_utils)

function main()

	local result = add(10, 20)

	print(`Sum: {result}`)

	local product = Calculator.multiply(5, 5)

	print(`Product: {product}`)

end

main()
