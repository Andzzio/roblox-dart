local add

function add(a: number, b: number): number

	return a + b

end

local Calculator = {}
Calculator.__index = function(self, key)
	local getter = Calculator["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Calculator[key]
end

Calculator.__newindex = function(self, key, value)
	local setter = Calculator["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Calculator.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Calculator"
end

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
