local main

local Logger = {}
Logger.__index = function(self, key)
	local getter = Logger["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Logger[key]
end

Logger.__newindex = function(self, key, value)
	local setter = Logger["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Logger.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Logger"
end

function Logger:log(message)
	print(`[LOG]: {message}`)
end

local SecurityException = {}
SecurityException.__index = function(self, key)
	local getter = SecurityException["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return SecurityException[key]
end

SecurityException.__newindex = function(self, key, value)
	local setter = SecurityException["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

SecurityException.__tostring = function(self)
	if self.toString then return self:toString() end
	return "SecurityException"
end

function SecurityException.new(cause)
	local self = setmetatable({}, SecurityException)

	self.cause = cause

	return self
end

function SecurityException:toString()
	return `SecurityException: {self.cause}`

end

local Vault = {}
Vault.__index = function(self, key)
	local getter = Vault["get_" .. tostring(key)]
	if getter then
		return getter(self)
	end
	return Vault[key]
end

Vault.__newindex = function(self, key, value)
	local setter = Vault["set_" .. tostring(key)]
	if setter then
		setter(self, value)
	else
		rawset(self, key, value)
	end
end

Vault.__tostring = function(self)
	if self.toString then return self:toString() end
	return "Vault"
end

function Vault.new()
	if Vault._instance == nil then Vault._instance = Vault._internal() end
	return Vault._instance

end

function Vault._internal()
	local self = setmetatable({}, Vault)

	self._balance = 1000

	self._isLocked = true

	self:log("Vault system initialized.")

	return self
end

function Vault:unlock(password)
	if password ~= "dart2luau" then

		error(SecurityException.new("Invalid password attempt."))
	end

	self._isLocked = false
	self:log("Vault unlocked successfully.")
end

function Vault:withdraw(amount)
	if self._isLocked then

		error(SecurityException.new("Cannot withdraw, vault is locked."))
	end

	if amount > self._balance then

		error(SecurityException.new("Insufficient funds."))
	end

	self._balance -= amount
	self:log(`Withdrew {amount}. Remaining: {self._balance}`)
end

Vault._instance = nil
for k, v in pairs(Logger) do
	if k ~= "new" and k ~= "__index" then
		Vault[k] = v
	end
end
function main()

	print("=== VAULT SECURITY TEST ===\n")
	local myVault = Vault.new()

	print("--- Attempt 1: Hacker ---")
	do
		local _hasReturned = false
		local _returnValue = nil
		local _hasBroken = false
		local _hasContinued = false

		local _ok, _luau_err = pcall(function()
			myVault:unlock("1234")
			myVault:withdraw(500)
		end)

		if not _ok then
			local e = _luau_err
			print(`Caught an error -> {e}`)
		end

		print("Hacker attempt finished.\n")

		if _hasReturned then return _returnValue end
	end
	print("--- Attempt 2: Owner ---")
	do
		local _hasReturned = false
		local _returnValue = nil
		local _hasBroken = false
		local _hasContinued = false

		local _ok, _luau_err = pcall(function()
			local sameVault = Vault.new()

			sameVault:unlock("dart2luau")
			sameVault:withdraw(1500)
		end)

		if not _ok then
			local e = _luau_err
			print(`Caught an error -> {e}`)
		end

		print("Owner attempt finished.")

		if _hasReturned then return _returnValue end
	end
	return
end

main()
