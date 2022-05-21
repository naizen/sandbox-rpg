local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)
-- local ForLocalPlayer = require(ReplicatedStorage.Source.ComponentExtensions.ForLocalPlayer)

local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)

local ClientConsumable = Component.new({
    Tag = "Consumable"
    -- Extensions = {ForLocalPlayer}
})

function ClientConsumable:Construct()
    self.trove = Trove.new()
    self.playerTrove = self.trove:Extend()
    self.healAmount = self.Instance:GetAttribute("HealAmount")
end

function ClientConsumable:SetupForLocalPlayer()
    local PlayerController = Knit.GetController("PlayerController")
    local canHeal = true

    local function OnActivated()
        if canHeal and PlayerController.Humanoid and PlayerController.Humanoid.Health <
            PlayerController.Humanoid.MaxHealth then
            canHeal = false

            local anim = PlayerController.LoadedAnimations[PlayerConfig.Animations.Eat]

            anim:Play()

            self.Instance.Heal:FireServer(self.healAmount)
        end
    end

    self.playerTrove:Add(self.Instance.Activated:Connect(OnActivated))
end

function ClientConsumable:CleanupForLocalPlayer()
    self.playerTrove:Clean()
end

function ClientConsumable:Start()
end

function ClientConsumable:Destroy()
    self.trove:Destroy()
end

return ClientConsumable
