local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _,v in ipairs(ReplicatedStorage.Source:GetDescendants()) do
   if v:IsA("ModuleScript") and v.Name:match("Controller$") then
      require(v)
   end
end

Knit.Start({ ServicePromises = false }):andThen(function()
   print("Knit started")
end):catch(warn)