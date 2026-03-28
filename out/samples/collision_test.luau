local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local utils = require(_RD.import(script, "Parent", "A", "utils"))
local fnA = utils.fnA
local utils2 = require(_RD.import(script, "Parent", "B", "utils"))
local fnB = utils2.fnB

function main()

	fnA()
	fnB()
end

main()
