local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local properties = require(_RD.import(script, "Parent", "properties"))
local score = properties.score

function main()

	print(score)
	score = 200
end

main()
