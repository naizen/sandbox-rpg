local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local function Lerp(min, max, alpha)
    return (min + ((max - min) * alpha))
end

local ClientBow = Component.new({
    Tag = "Bow",
    Extensions = {}
})

function ClientBow:Construct()
    self.trove = Trove.new()
    self.chargingTrove = self.trove:Extend()
end

function ClientBow:Start()
    local debounce = false
    local isCharging = false
    local chargeTime = 0

    local velocityMax = self.Instance:GetAttribute("VelocityMax")
    local velocityMin = self.Instance:GetAttribute("VelocityMin")
    local debounceTime = self.Instance:GetAttribute("DebounceTime")

    local function ResetCharge()
        isCharging = false
        chargeTime = 0
        self.Instance.ResetCharge:FireServer()
    end

    local function FireCharging()
        isCharging = true
        chargeTime = time()
        self.Instance.Charging:FireServer()
    end

    local function OnActivated()
        if not debounce then
            debounce = true

            if isCharging then
                ResetCharge()
            else
                FireCharging()
            end

            task.wait(debounceTime)

            debounce = false
        end
    end

    local function FireCharge()
        local chargeDuration = (time() - chargeTime)
        local velocityAlpha = math.min(1, chargeDuration) / 1
        local velocity = Lerp(velocityMin, velocityMax, velocityAlpha)
        chargeTime = 0

        local position = Knit.Player:GetMouse().Hit.Position

        self.Instance.Fire:FireServer(position, velocity)

        isCharging = false
    end

    local function OnDeactivated()
        if isCharging then
            FireCharge()
        end
    end

    local function OnEquipped()
        self.Instance.Equip:FireServer()
    end

    local function OnUnequipped()
        ResetCharge()
    end

    self.trove:Add(self.Instance.Activated:Connect(OnActivated))
    self.trove:Add(self.Instance.Deactivated:Connect(OnDeactivated))
    self.trove:Add(self.Instance.Equipped:Connect(OnEquipped))
    self.trove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
end

function ClientBow:Destroy()
    self.trove:Destroy()
end

return ClientBow
