local main

local Color
do
	local _mt = {
		__tostring = function(self) return self._name end
	}
	local function _create(cname, index)
		local obj = { index = index, _name = "Color." .. cname }
		setmetatable(obj, _mt)
		table.freeze(obj)
		return obj
	end

	Color = {}
	Color.red = _create("red", 0)
	Color[0] = Color.red
	Color.green = _create("green", 1)
	Color[1] = Color.green
	Color.blue = _create("blue", 2)
	Color[2] = Color.blue

	table.freeze(Color)
end

function main()

	print(Color.red)

end

main()
