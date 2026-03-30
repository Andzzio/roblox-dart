local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local utils = _RD.import(script, "A", "utils")
local fnA = utils.fnA
local utils2 = _RD.import(script, "B", "utils")
local fnB = utils2.fnB

function main()

	fnA()
	fnB()
end

main()
