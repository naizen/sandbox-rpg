local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)

local TIME_BETWEEN_ATTACKS = 0.35

local ClientMeleeWeapon = Component.new({
    Tag = "MeleeWeapon",
    Extensions = {}
})

function ClientMeleeWeapon:Construct()
    self.trove = Trove.new()
end

function ClientMeleeWeapon:Start()
    local PlayerController = Knit.GetController("PlayerController")
    local debounce = false
    local attackCount = 0
    local attackAnims = PlayerConfig.Animations[self.Tag].Attack

    local function OnActivated()
        -- local character = Knit.Player.Character
        -- local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        -- local animator = humanoid.Animator

        if not debounce then
            debounce = true
            attackCount = attackCount + 1

            local attackAnim = PlayerController.Animations[attackAnims[attackCount]]
            -- local anim = animator:LoadAnimation(attackAnim)

            attackAnim:Play()

            if attackCount >= table.getn(attackAnims) then
                attackCount = 0
            end

            self.Instance.Attack:FireServer()

            task.wait(TIME_BETWEEN_ATTACKS)
            debounce = false
        end
    end

    self.trove:Add(self.Instance.Activated:Connect(OnActivated))
end

function ClientMeleeWeapon:Destroy()
    self.trove:Destroy()
end

return ClientMeleeWeapon
