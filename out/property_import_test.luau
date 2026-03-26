local _RD = require((script.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local properties = require(_RD.import(script, "Parent", "properties"))

function main()

	print(score)

	score = 200

end

main()
