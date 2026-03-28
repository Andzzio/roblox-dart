local _RD = require((script.Parent.Parent :: any):WaitForChild("include"):WaitForChild("RuntimeLib"))
local main

local workspace = game:GetService("Workspace")
function main()

	workspace.Gravity = 0
	local pos = Vector3.new(1, 2, 3)

	local mag = pos.Magnitude

	local u = pos.Unit

	print(mag)
	print(u)
	local goal = Vector3.new(4, 5, 6)

	local lerped = pos:Lerp(goal,0.5)

	local d = pos:Dot(goal)

	print(lerped)
	print(d)
	local zero = Vector3.zero

	print(zero)
	local part = Instance.new("Part")

	part:Clone()
	part:Destroy()
	local child = part:FindFirstChild("Handle")

	print(child)
	part:Destroy()
end

main()
