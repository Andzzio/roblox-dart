local main

local Person = {}
Person.__index = function(self, key)
	local getter = Person["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Person[key]
end

Person.__newindex = function(self, key, value)
	local setter = Person["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Person.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Person"
end

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
