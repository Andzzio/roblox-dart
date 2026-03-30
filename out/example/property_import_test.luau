local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local properties = _RD.import(script, "properties")
local score = properties.score

function main()

	print(score)
	score = 200
end

main()
