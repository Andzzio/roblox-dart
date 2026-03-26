local main

local Person = {}
Person.__index = Person

function Person.new(_name)
	local self = setmetatable({}, Person)

	self._name = _name


	return self
end

function Person:get_name()
	return self._name

end

function Person:set_name(value)
	self._name = value

end

function main()

	local p = Person.new("André")

	print(p.name)

	p.name = "André Fixed"

	print(p.name)

end

main()
