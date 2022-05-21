local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- local ForLocalPlayer = require(ReplicatedStorage.Source.ComponentExtensions.ForLocalPlayer)
local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)
local PlayerController = Knit.GetController("PlayerController")

local ClientRangeWeapon = Component.new({
    Tag = "RangeWeapon"
    -- Extensions = {ForLocalPlayer}
})

function ClientRangeWeapon:Construct()
    self.trove = Trove.new()
    self.playerTrove = self.trove:Extend()
    self.shootingTrove = self.trove:Extend()
    self.weaponType = self.Instance:GetAttribute("WeaponType")
end

function ClientRangeWeapon:SetupForLocalPlayer()
    local debounce = false
    local shootAnim
    local anims = PlayerConfig["Animations"][self.weaponType]
    local cooldown = 0.6
    local canRelease = false

    local function OnActivated()
        local attackAnims = anims["Attack"]

        if not debounce then
            debounce = true

            shootAnim = PlayerController.LoadedAnimations[attackAnims[1]]

            shootAnim:Play()

            self.shootingTrove:Add(shootAnim:GetMarkerReachedSignal("Hold"):Connect(function()
                shootAnim:AdjustSpeed(0)
            end))

            self.Instance.Shooting:FireServer()

            canRelease = true

            task.wait(cooldown)

            debounce = false
        end
    end

    local function OnDeactivated()
        self.shootingTrove:Clean()

        shootAnim:AdjustSpeed(1)

        if canRelease then
            self.Instance.Release:FireServer(Knit.Player:GetMouse().Hit)
            canRelease = false
        end
    end

    local function OnUnequipped()
        self.shootingTrove:Clean()

        if shootAnim and shootAnim.IsPlaying then
            shootAnim:Stop()
        end
    end

    self.playerTrove:Add(self.Instance.Activated:Connect(OnActivated))
    self.playerTrove:Add(self.Instance.Deactivated:Connect(OnDeactivated))
    self.playerTrove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
end

function ClientRangeWeapon:CleanupForLocalPlayer()
    self.playerTrove:Clean()
end

function ClientRangeWeapon:Start()
end

function ClientRangeWeapon:Destroy()
    self.trove:Destroy()
end

return ClientRangeWeapon
