local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)

local ClientConsumable = Component.new({
    Tag = "Consumable"
})

function ClientConsumable:Construct()
    self.trove = Trove.new()
    self.healAmount = self.Instance:GetAttribute("HealAmount")
end

function ClientConsumable:Start()
    local PlayerController = Knit.GetController("PlayerController")

    local function OnActivated()
        local anim = PlayerController.Animations[PlayerConfig.Animations.Eat]

        anim:Play()

        self.Instance.Heal:FireServer(self.healAmount)
    end

    self.trove:Add(self.Instance.Activated:Connect(OnActivated))
end

function ClientConsumable:Destroy()
    self.trove:Destroy()
end

return ClientConsumable
