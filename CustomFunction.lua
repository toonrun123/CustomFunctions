--[=[
	Custom Functions 1.0
	
	What this for:
		This Module Created Custom Functions For Specific Class,
		Like You trying to Call function not exist in class,
		You can created own custom function Or Get from Share Custom Functions,
		You can customize with own metatables in CustomFunction ClassName.
		^^(For More information please look Questions title.)^^
		Like:
			Custom_PlayerClass:Ban()
			Custom_PlayerClass:Explode()

	Title List:
		DIR
		How this work (Must Read)
		How to Create Own Functions
		How to use Own Functions
		Questions (Must Read)
		Priority List (Must Read)
		License
		
	DIR:
		This_Module
		└─────────Instance
			 ├───────────new(ClassName,Parent) 
			 │			  Return: Customable_Instance
			 └───────────Inject(Object)
			 			  Return: Customable_Instance

	How this work:
		When you Create Part in this Module so it gonna return userdata.
		Customable_Instance can be called function same like real instance
			Example:
				[
				 Custom.Color = Color.FromRGB(10,10,10)
				 Custom:Destroy()
				]
		Customable_Instance.__instance will return real instance
			useful for add children to instance
			Example:
				[
				 Attachment.Parent = Custom --> Wrong
				 Attachment.Parent = Custom.__instance --> Correct
				]
	
	How to Create Own Functions:
	
		**NOTE**:
			Self //Return customable_instance
	
		Create ModuleScript in 'CustomFunctions' Folder then
		Set ModuleScript Name to Any ClassName like ('Part' or 'BasePart' etc.)
			(Module Name will affect Custom function.)
		Go Module Script Editor And Write custom function
			EXAMPLE:
				```
					local module = {}
					
					function module:DelayDestroy(time,...)
						print(typeof(self)) --> userdata
						print(typeof(self.__instance)) --> Instance
						task.wait(time)
						if self:Check() then
							self:Destroy()
						end
					end
					
					function module:Check()
						return true
					end
					
					--[[Override metatable (More information please look Questions title.)]]
					function module:__tostring(custom_instance)
						print(custom_instance:Check())
						return "not a part yes"
					end
					
					return module
				```
	
	How to use Own Functions:
		Create Script then Require This Module
		Then Create Some Variable set Module.Instance
			EXAMPLE:
				```
					local customfunction = require(PATH_TO_MODULE)
					local Instance = customfunction.Instance
					
					local Customable_Instance = Instance.new("Part") --Reference From Roblox's Instance.new
					Customable_Instance.Parent = workspace
					print("Real Instance is ",Customable_Instance.__instance)
					Customable_Instance:DelayDestroy(5) --Called Custom Function.
				```

	Questions:
		Can I Override Roblox's Functions:
			Yes, you can just write name function like roblox's function.
			
		What if part name "__instance" and i'll call Custom.__instance:
			So, it gonna return Custom_instance.__instance NOT part because Priority list.
		
		Can i custom this Custom_instance Metatable:
			Yes, you can override almost anything in metatable .
			**Except __metatable, __index and __newindex**
		
		How do i make Custom Functions only server Like :Ban():
			You can manualy add Function in ClassName Module with Script.
			Examples:
				Secret Function Script (ServerSide):
					```
						local customfunction = PATH_TO_MODULE
						local CustomFolder = customfunction.CustomFunctions
						local Instance = req.Instance
					
						local Custom_Partmodule = require(CustomFolder.Part)
						
						function Custom_Partmodule:Magic()
							print("Sprinkle!")
						end
					```
				Spawn Secret Script (ServerSide):
					```
						local customfunction = PATH_TO_MODULE
						local CustomFolder = customfunction.CustomFunctions
						local Instance = req.Instance
						
						local part = Instance.new("Part")
						part:Magic() --> Sprinkle!
					```
				
	Priority List (lower meaning highest):
		1.__instance
		2.Custom Functions
		3.Roblox's Functions
		4.Instance's Childrens
	
	toonrun123V2,
	1/2/2023 (MM/DD/YYYY)
	7:14 PM
	
	Copyright (c) 2023 toonrun123V2

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:

	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
	LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
	OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
	WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]=]

local module = {
	["Instance"] = {}
}
module.VERSION = 1.0

local Suggestion = require(script:WaitForChild("Suggestion"))
local format = string.format
local CustomFunctions = script:WaitForChild("CustomFunctions")

local cacheuseable = {}

--Pre Start Custom functions
for _,modcus in ipairs(CustomFunctions:GetChildren()) do
	if modcus:IsA("ModuleScript") then
		require(modcus)
	end
end

local disallow_override = {
	["__metatable"] = true, ["__index"] = true, ["__newindex"] = true
}

--Inject object and return userdata.
local function Inject(thing:Instance) : Instance
	local proxy = newproxy(true)
	local proxy_meta = getmetatable(proxy)
	local th = {}

	proxy_meta.__metatable = "The metatable is locked"
	proxy_meta.__tostring = function()
		return thing.ClassName
	end
	
	proxy_meta.__index = function(t,v)
		--[[Return __instance]]
		if v == "__instance" then
			return thing
		end

		local thingcalled = nil
		local c,e = pcall(function()
			thingcalled = thing[v]
		end)

		--[[Called Custom Function detected.]]
		if not c or typeof(thingcalled) == "function" then
			local useablemodule = {}
			for _,module in ipairs(CustomFunctions:GetChildren()) do
				if thing:IsA(module.Name) then
					table.insert(useablemodule,module)
				end
			end
			
			local useablefunctions = {}
			for _,mod in ipairs(useablemodule) do
				local list = require(mod)
				for name,func in pairs(list) do
					useablefunctions[name] = func
					useablefunctions[func] = mod.Name
				end
			end
			
			local func = useablefunctions[v]
			if func then
				return function(...)
					local x = {...}
					if x[1] == nil then
						error("Call Custom functions using ':'only")
					end
					x[1] = proxy
					local c,e = pcall(func,unpack(x))
					if not c then
						error(format("Failure Execute Custom Functions in CustomFunctions.%s.%s\n [[ %s ]] ",
							useablefunctions[func],
							v,
							e
							))
					end
					return e
				end
			end
		end
		
		--[[Spoof that thing is not a vaild]]
		local typecalled = typeof(thingcalled)
		if typecalled == "nil" then
			return error(format('%s is not a vaild member of %s "%s"',
				v,
				thing.ClassName,
				thing.Name
				))
		end
		
		if thingcalled and typecalled ~= "function" and typecalled ~= "Instance" then
			return thingcalled --Return var
		elseif typecalled == "function" then --[[Return roblox's function]]
			if th[v] then
				return th[v]
			end
			local function this(...)
				local x = {...}
				x[1] = thing
				local c,e = pcall(thing[v],unpack(x))
				if not c then
					error(e)
				end
				return e
			end

			th[v] = this

			return th[v]
		else
			if thingcalled == "Instance" then
				return thingcalled
			end
		end
	end

	proxy_meta.__newindex = function(t,i,v)
		local c,e = pcall(function()
			local tested = thing[i]
		end)
		local tt = typeof(thing[i])
		if c then
			thing[i] = v
			return
		end
		return error(format('%s is not a vaild member of %s "%s"',
			i,
			thing.ClassName,
			thing.Name
			))
	end
	
	--[[Override metatable function time]]
	local ClassName = thing.ClassName
	if not ClassName then
		for i,v in ipairs(CustomFunctions) do
			if thing:IsA(v.Name) then
				ClassName = v.Name
				break
			end
		end
	end
		
	for i,v in pairs(require(CustomFunctions[ClassName])) do
		if typeof(i) == "string" then
			if i:find("__") then
				if not disallow_override[i] then
					proxy_meta[i] = v
				else
					error("Unable to Override "..i.." In "..ClassName)
				end
			end
		end
	end
		
	return proxy
end

module.Instance.Inject = Inject

module.Instance.new = function(Class:Suggestion.AllClass,Parent:any)
	local thing = Instance.new(Class,Parent)
	local newthing = Inject(thing)

	return newthing
end

return module
