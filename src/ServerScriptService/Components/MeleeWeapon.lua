local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RaycastHitbox = require(ReplicatedStorage.Packages.Hitbox)

local MeleeWeapon = Component.new({
    Tag = "MeleeWeapon"
})

function MeleeWeapon:Construct()
    self.trove = Trove.new()
    self.hitboxTrove = self.trove:Extend()

end

function MeleeWeapon:Start()
    local StatsService = Knit.GetService('StatsService')

    local function OnHit(player, humanoid)
        humanoid:TakeDamage(self.damage)
        StatsService:UpdateStat(player, 'strength', 'xp', 10)
    end

    local function OnAttack(player)
        self.raycastParams.FilterDescendantsInstances = {self.Instance, player.Character}

        self.hitbox:HitStart()

        self.hitbox.OnHit:Connect(function(_, humanoid)
            OnHit(player, humanoid)
        end)
    end

    local function OnEquipped()
        -- Enhancement: Create hitbox attachments dynamically using a start and end point attachment only
        self.hitbox = RaycastHitbox.new(self.Instance)
        self.damage = 25
        self.raycastParams = RaycastParams.new()
        self.hitbox.Visualizer = true
        self.raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        self.hitbox.RaycastParams = self.raycastParams
    end

    local function OnUnequipped()
        self.hitbox:HitStop()
    end

    local function OnDropped()
        self.hitbox:HitStop()
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
