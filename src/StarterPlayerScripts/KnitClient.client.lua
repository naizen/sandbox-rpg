local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Loader = require(ReplicatedStorage.Packages.Loader)

-- Why client code in replicated storage?
-- for _, v in ipairs(ReplicatedStorage.Source:GetDescendants()) do
--     if v:IsA("ModuleScript") and v.Name:match("Controller$") then
--         require(v)
--     end
-- end

for _, v in ipairs(StarterPlayer.StarterPlayerScripts.Source:GetDescendants()) do
    if v:IsA("ModuleScript") and v.Name:match("Controller$") then
        require(v)
    end
end

Knit.Start({
    ServicePromises = false
}):andThen(function()
    Loader.LoadChildren(script.Parent.Components)
end):catch(warn)
