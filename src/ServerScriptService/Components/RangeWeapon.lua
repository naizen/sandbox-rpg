local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Debris = game:GetService("Debris")
local Prefabs = game:GetService("ServerStorage").Prefabs

local ARROW_FORCE_MIN = 80
local ARROW_FORCE_MAX = 100
local ARROW_FORCE_TIME = 1
local ARROW_DMG = 25
local ARROW_DEBRIS_TIME = 4

local function Lerp(min, max, alpha)
    return (min + ((max - min) * alpha))
end

local RangeWeapon = Component.new({
    Tag = "RangeWeapon"
})

function RangeWeapon:Construct()
    self.trove = Trove.new()
end

function RangeWeapon:Start()
    local StatsService = Knit.GetService("StatsService")
    local arrow
    local arrowWeld
    local holdTime = 0

    local function DisableArrowCollisionsOnPlayer(player)
        for _, part in pairs(player.Character:GetChildren()) do
            if part:isA("BasePart") then
                local constraint = Instance.new("NoCollisionConstraint", arrow)
                constraint.Part0 = part
                constraint.Part1 = arrow
                constraint.Enabled = true
            end
        end
    end

    local function SpawnArrow(player)
        local placeholderArrow = self.Instance.PlaceholderArrow

        arrow = Prefabs.Arrow:Clone()
        arrow.Parent = self.Instance

        arrowWeld = Instance.new("WeldConstraint", arrow)
        arrow.CFrame = (placeholderArrow.CFrame * CFrame.Angles(math.rad(-20), 0, 0)) * CFrame.new(0, 0.5, 0.5)

        arrowWeld.Part0 = arrow
        arrowWeld.Part1 = placeholderArrow

        local effect = arrow:GetAttribute("Effect")

        if effect == "Fire" then
            local fire = Instance.new("Fire", arrow.Head)
            fire.Heat = 3
            fire.Size = 2
        end

        DisableArrowCollisionsOnPlayer(player)
    end

    -- Attach bow string to player
    local function AttachBeams(player)
        local beamGripAttachment = player.Character.LeftHand.LeftGripAttachment
        self.Instance.Handle.BottomBeam.Attachment0 = beamGripAttachment
        self.Instance.Handle.TopBeam.Attachment0 = beamGripAttachment
    end

    local function OnShooting(player)
        holdTime = time()

        AttachBeams(player)

        self.Instance.Handle.PullSound:Play()

        SpawnArrow(player)
    end

    local function ResetBeams()
        if not self.Instance:FindFirstChild("Handle") then
            return
        end

        local middleAttachment = self.Instance.Handle.Middle
        self.Instance.Handle.BottomBeam.Attachment0 = middleAttachment
        self.Instance.Handle.TopBeam.Attachment0 = middleAttachment
    end

    local function OnRelease(player, mouseHit)
        local direction = mouseHit.LookVector

        self.Instance.Handle.ReleaseSound:Play()

        arrowWeld:Destroy()

        -- Shoot arrow with force based on how long it was held
        local holdDuration = time() - holdTime

        local arrowForceAlpha = math.min(ARROW_FORCE_TIME, holdDuration) / ARROW_FORCE_TIME
        local arrowForceMult = Lerp(ARROW_FORCE_MIN, ARROW_FORCE_MAX, arrowForceAlpha)
        local arrowForce = arrow.AssemblyMass * arrowForceMult

        local impulse = (direction * arrowForce) + Vector3.new(0, arrowForce / 3, 0)

        arrow:ApplyImpulse(impulse)

        local touchedConnection

        -- TODO: Replace with FastCast later since this is kind of buggy
        local function OnArrowTouched(hit)
            arrow.CanCollide = false
            arrow.Massless = true

            if not hit:IsDescendantOf(player.Character) then
                local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
                local damagedEvent = hit.Parent:FindFirstChild("DamagedEvent")

                -- local weld = Instance.new("WeldConstraint", arrow)
                -- weld.Part0 = arrow
                -- weld.Part1 = hit
                -- arrow.Parent = hit.Parent

                if humanoid and humanoid.Health > 0 then
                    humanoid:TakeDamage(ARROW_DMG)

                    StatsService:UpdateStat(player, 'range', 'xp', 10)

                    if damagedEvent then
                        damagedEvent:Fire(player)
                    end
                end

                touchedConnection:Disconnect()
            end
        end

        touchedConnection = arrow.Touched:Connect(OnArrowTouched)

        Debris:AddItem(arrow, ARROW_DEBRIS_TIME)
    end

    local function OnDeactivated()
        ResetBeams()
    end

    local function OnUnequipped()
        ResetBeams()
    end

    self.trove:Add(self.Instance.Shooting.OnServerEvent:Connect(OnShooting))
    self.trove:Add(self.Instance.Release.OnServerEvent:Connect(OnRelease))
    self.trove:Add(self.Instance.Deactivated:Connect(OnDeactivated))
    self.trove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
end

function RangeWeapon:Destroy()
    self.trove:Destroy()
end

return RangeWeapon
