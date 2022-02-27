local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ForLocalPlayer = require(ReplicatedStorage.Source.ComponentExtensions.ForLocalPlayer)

local PlayerConfig = require(ReplicatedStorage.Source.Player.PlayerConfig)
local PlayerController = Knit.GetController("PlayerController")

local ClientMeleeWeapon = Component.new({
    Tag = "MeleeWeapon",
    Extensions = {ForLocalPlayer}
})

function ClientMeleeWeapon:Construct()
    self.trove = Trove.new()
    self.playerTrove = Trove.new()
    self.trove:Add(self.playerTrove)
    self.weaponType = self.Instance:GetAttribute("WeaponType")
end

function ClientMeleeWeapon:SetupForLocalPlayer()
    local attackCount = 0
    local debounce = false
    local timeBetweenAttacks = 0.3
    local anims = PlayerConfig["Animations"][self.weaponType]

    local function OnActivated()
        local attackAnims = anims["Attack"]

        if debounce == false then
            debounce = true

            attackCount = attackCount + 1

            local attackAnim = PlayerController.LoadedAnimations[attackAnims[attackCount]]

            attackAnim:Play()

            if attackCount >= 2 then
                attackCount = 0
            end

            self.Instance.Attack:FireServer()

            task.wait(timeBetweenAttacks)

            debounce = false
        end
    end

    self.playerTrove:Add(self.Instance.Activated:Connect(OnActivated))
end

function ClientMeleeWeapon:CleanupForLocalPlayer()
    self.playerTrove:Clean()
end

function ClientMeleeWeapon:Start()
end

function ClientMeleeWeapon:Destroy()
    self.trove:Destroy()
end

return ClientMeleeWeapon
