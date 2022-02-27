local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RaycastHitbox = require(ReplicatedStorage.Packages.Hitbox)

local MeleeWeapon = Component.new({
    Tag = "MeleeWeapon"
})

function MeleeWeapon:Construct()
    self.trove = Trove.new()
end

function MeleeWeapon:Start()
    local hitboxTrove = Trove.new()
    self.trove:Add(hitboxTrove)

    local function OnHit(_, humanoid)
        humanoid:TakeDamage(self.damage)
    end

    local function OnAttack(player)
        local character = player.Character or player.CharacterAdded:Wait()
        self.raycastParams.FilterDescendantsInstances = {self.Instance, character}

        self.hitbox:HitStart()
        self.hitbox.OnHit:Connect(OnHit)
    end

    local function OnEquipped()
        -- Enhancement: Create hitbox attachments dynamically using a start and end point attachment only
        self.hitbox = RaycastHitbox.new(self.Instance)
        self.damage = 25
        self.raycastParams = RaycastParams.new()
        self.hitbox.Visualizer = true
        self.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        self.hitbox.RaycastParams = self.raycastParams

        hitboxTrove:Add(self.hitbox)
    end

    local function OnUnequipped()
        hitboxTrove:Clean()
    end

    local function OnDropped()
        hitboxTrove:Clean()
    end

    self.trove:Add(self.Instance.Equipped:Connect(OnEquipped))
    self.trove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
    self.trove:Add(self.Instance.Attack.OnServerEvent:Connect(OnAttack))
    self.trove:Add(self.Instance.Drop.OnServerEvent:Connect(OnDropped))
end

function MeleeWeapon:Destroy()
    self.trove:Destroy()
end

return MeleeWeapon
