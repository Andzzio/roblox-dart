local Human = {}
Human.__index = function(self, key)
	local getter = Human["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Human[key]
end

Human.__newindex = function(self, key, value)
	local setter = Human["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Human.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Human"
end

function Human.new(name, age)
	local self = setmetatable({}, Human)

	self.name = name
	self.age = age

	return self
end


local Exports = {
    Human = Human,
}
return Exports
