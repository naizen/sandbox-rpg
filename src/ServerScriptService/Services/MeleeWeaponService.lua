-- MeleeWeaponService handles
-- Creating weapon trails
-- Creating hitbox to deal damage
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MeleeWeaponService = Knit.CreateService {
    Name = "MeleeWeaponService"
}

function MeleeWeaponService:KnitInit()
end

function MeleeWeaponService:KnitStart()
end

return MeleeWeaponService
