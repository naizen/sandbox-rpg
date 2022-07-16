local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local Promise = require(ReplicatedStorage.Packages.Promise)

FastCast.VisualizeCasts = false

local ARROW_DEBRIS_TIME = 5

-- Can make special bows like fire bow with different attributes by tag or name
local ATTRIBUTES = {
    FireAngle = 10,
    ProjectileName = "Arrow",
    VelocityMin = 50,
    VelocityMax = 300,
    DebounceTime = 0.25,
    AnimId = '10240716659',
    Damage = 100
}

local Bow = Component.new({
    Tag = "Bow"
})

function Bow:SetAttributes()
    for attrKey, attrVal in pairs(ATTRIBUTES) do
        self.Instance:SetAttribute(attrKey, attrVal)
    end
end

function Bow:LoadAnimation(animator)
    local animId = self.Instance:GetAttribute("AnimId")
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. animId

    self.anim = animator:LoadAnimation(anim)
end

function Bow:InitRemoteEvents()
    self.equipEvent = Instance.new("RemoteEvent")
    self.equipEvent.Name = "Equip"
    self.equipEvent.Archivable = false
    self.equipEvent.Parent = self.Instance

    self.chargingEvent = Instance.new("RemoteEvent")
    self.chargingEvent.Name = "Charging"
    self.chargingEvent.Archivable = false
    self.chargingEvent.Parent = self.Instance

    self.resetChargeEvent = Instance.new("RemoteEvent")
    self.resetChargeEvent.Name = "ResetCharge"
    self.resetChargeEvent.Archivable = false
    self.resetChargeEvent.Parent = self.Instance

    self.fireEvent = Instance.new("RemoteEvent")
    self.fireEvent.Name = "Fire"
    self.fireEvent.Archivable = false
    self.fireEvent.Parent = self.Instance
end

function Bow:Construct()
    self.trove = Trove.new()
    self.casterTrove = self.trove:Extend()
    self.hitTrove = self.casterTrove:Extend()
    self.chargingTrove = self.trove:Extend()

    self:InitRemoteEvents()
    self:SetAttributes()
end

function Bow:Start()
    local damage = self.Instance:GetAttribute("Damage")
    local caster = FastCast.new()
    local castBehavior = FastCast.newBehavior()
    local castParams = RaycastParams.new()

    castParams.FilterType = Enum.RaycastFilterType.Blacklist

    local arrowFolder = workspace:FindFirstChild("Projectiles") or Instance.new("Folder", workspace)
    arrowFolder.Name = "Projectiles"

    local projectileName = self.Instance:GetAttribute("ProjectileName")
    local projectile = self.Instance:FindFirstChild(projectileName) or ServerStorage.Items[projectileName]

    local projectileTemplate = projectile:Clone()
    projectileTemplate.Transparency = 0
    projectileTemplate.CanCollide = false
    projectileTemplate.Anchored = true

    castBehavior.RaycastParams = castParams
    castBehavior.Acceleration = Vector3.new(0, -workspace.Gravity, 0);
    castBehavior.AutoIgnoreContainer = false
    castBehavior.CosmeticBulletContainer = arrowFolder
    castBehavior.CosmeticBulletTemplate = projectileTemplate

    local function OnFire(player, position, arrowVelocity)
        self.chargingTrove:Clean()

        projectile.Transparency = 1

        if self.anim and self.anim.IsPlaying then
            self.anim:AdjustSpeed(1)
        end

        local origin = self.Instance.Handle.ProjectileAttachment.WorldPosition
        local direction = (position - origin).Unit

        caster:Fire(origin, direction, arrowVelocity, castBehavior)

        self.hitTrove:Connect(caster.RayHit, function(cast, result, velocity, arrow)
            local hit = result.Instance

            local character = hit:FindFirstAncestorWhichIsA("Model")
            local humanoidHit = character:FindFirstChild("Humanoid")
            local damagedEvent = character:FindFirstChild("Damaged")

            if character and humanoidHit then
                humanoidHit:TakeDamage(damage)

                if damagedEvent then
                    damagedEvent:Fire(player)
                end
            end

            Debris:AddItem(arrow, ARROW_DEBRIS_TIME)

            self.hitTrove:Clean()
        end)
    end

    local function OnLengthChanged(cast, lastPoint, direction, length, velocity, arrow)
        if arrow then
            local arrowLength = arrow.Size.Z / 2
            local offset = CFrame.new(0, 0, -(length - arrowLength))
            arrow.CFrame = CFrame.lookAt(lastPoint, lastPoint + direction):ToWorldSpace(offset)
        end
    end

    local function OnCharging()
        self.anim:Play()

        -- Make arrow appear when charging bow. Canceled when arrow is fired.
        self.chargingTrove:Add(Promise.delay(0.1):andThen(function()
            projectile.Transparency = 0
        end), "cancel")

        self.chargingTrove:Add(self.anim:GetMarkerReachedSignal("Charged"):Connect(function()
            self.anim:AdjustSpeed(0)
        end))
    end

    local function OnResetCharge()
        self.chargingTrove:Clean()

        if self.anim.IsPlaying then
            self.anim:Stop()
        end

        projectile.Transparency = 1
    end

    local function OnEquip(player)
        local character = player.Character
        local humanoid = character.Humanoid
        local animator = humanoid.Animator

        self:LoadAnimation(animator)

        castParams.FilterDescendantsInstances = {self.Instance.Parent, arrowFolder}

        self.casterTrove:Connect(caster.LengthChanged, OnLengthChanged)
    end

    local function OnUnequipped()
        self.casterTrove:Clean()
    end

    self.trove:Add(self.Instance.Equip.OnServerEvent:Connect(OnEquip))
    self.trove:Add(self.Instance.Fire.OnServerEvent:Connect(OnFire))
    self.trove:Add(self.Instance.ResetCharge.OnServerEvent:Connect(OnResetCharge))
    self.trove:Add(self.Instance.Charging.OnServerEvent:Connect(OnCharging))
    self.trove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
end

function Bow:Destroy()
    self.trove:Destroy()
end

return Bow
