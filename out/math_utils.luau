local add

function add(a: number, b: number): number

	return a + b

end

local Calculator = {}
Calculator.__index = Calculator

function Calculator.new()
	local self = setmetatable({}, Calculator)


	return self
end

function Calculator.multiply(a, b)
	return a * b

end


local Exports = {
    add = add,
    Calculator = Calculator,
}
return Exports
