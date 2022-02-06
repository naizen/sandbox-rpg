local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local HitboxController = Knit.CreateController { Name = "HitboxController" }

function HitboxController:KnitStart()
end

function HitboxController:KnitInit()
end

return HitboxController
