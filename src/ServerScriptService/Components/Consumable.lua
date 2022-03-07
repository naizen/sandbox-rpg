local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Consumable = Component.new({
    Tag = "Consumable"
})

function Consumable:Construct()
    self.trove = Trove.new()
end

function Consumable:Start()
    local function OnHeal(player, healAmount)
        if self.Instance:GetAttribute("PlayerId") ~= player.UserId then
            return
        end

        local playerHealth = player.Character.Humanoid.Health
        local maxHealth = player.Character.Humanoid.MaxHealth

        if playerHealth < maxHealth then
            player.Character.Humanoid.Health = playerHealth + healAmount
        end

        Debris:AddItem(self.Instance, 0.5)
    end

    self.trove:Add(self.Instance.Heal.OnServerEvent:Connect(OnHeal))
end

function Consumable:Destroy()
    self.trove:Destroy()
end

return Consumable
