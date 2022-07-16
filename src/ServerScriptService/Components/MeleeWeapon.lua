local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RaycastHitbox = require(ReplicatedStorage.Packages.Hitbox)
local FX = ServerStorage.FX
local Sounds = ServerStorage.Sounds

local VISUALIZE_HITBOX = true
local HITBOX_POINTS_INCREMENT = 0.25
local DEFAULT_DAMAGE = 25

local MeleeWeapon = Component.new({
    Tag = "MeleeWeapon"
})

function MeleeWeapon:Construct()
    self.trove = Trove.new()

    self.attackEvent = Instance.new("RemoteEvent")
    self.attackEvent.Name = "Attack"
    self.attackEvent.Archivable = false
    self.attackEvent.Parent = self.Instance

    self.hitboxTrove = self.trove:Extend()
    self.hitbox = nil
end

function MeleeWeapon:Start()
    -- TODO: Get damage from weapon attributes
    local damage = DEFAULT_DAMAGE

    local function AddWeaponTrail()
        local trail = FX.SwordTrail:Clone()
        trail.Parent = self.Instance.Handle
        trail.Attachment0 = self.Instance.Handle.Start
        trail.Attachment1 = self.Instance.Handle.End
        Debris:AddItem(trail, 0.3)
    end

    local function PlaySlashSound()
        local slashSound = Sounds.Slash:Clone()
        slashSound.Parent = self.Instance
        slashSound.PlaybackSpeed = math.random(85, 110) / 100
        slashSound:Play()
        Debris:AddItem(slashSound, 0.4)
    end

    local function DestroyHitbox()
        self.hitboxTrove:Clean()

        if self.hitbox ~= nil then
            self.hitbox:Destroy()
        end

        self.hitbox = nil
    end

    local function CreateHitbox(player)
        self.hitbox = RaycastHitbox.new(self.Instance)

        -- Dynamically generate hitbox points based on attachments at the start and end of blade handle
        local startZ = self.Instance.Handle.Start.Position.Z
        local endZ = self.Instance.Handle.End.Position.Z

        local points = {}

        for i = startZ, endZ, HITBOX_POINTS_INCREMENT do
            local point = Vector3.new(0, 0, i)
            table.insert(points, point)
        end

        self.hitbox:SetPoints(self.Instance.Handle, points)

        self.hitbox.Visualizer = VISUALIZE_HITBOX

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {player.Character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        self.hitbox.RaycastParams = raycastParams
        self.hitbox:HitStart()

        local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

        self.hitboxTrove:Add(humanoid.Died:Connect(function()
            DestroyHitbox()
        end))

        self.hitboxTrove:Add(Players.PlayerRemoving:Connect(function(playerRemoved)
            if playerRemoved == player then
                DestroyHitbox()
            end
        end))

        local function OnHit(hit, target)
            target:TakeDamage(damage)
        end

        self.hitbox.OnHit:Connect(OnHit)
    end

    local function OnAttack(player)
        if not self.hitbox then
            return
        end

        self.hitbox:HitStart()

        AddWeaponTrail()
        PlaySlashSound()
    end

    local function OnEquipped()
        local player = Players:GetPlayerFromCharacter(self.Instance.Parent)

        CreateHitbox(player)
    end

    local function OnUnequipped()
        DestroyHitbox()
    end

    self.trove:Add(self.Instance.Equipped:Connect(OnEquipped))
    self.trove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
    self.trove:Add(self.Instance.Attack.OnServerEvent:Connect(OnAttack))
end

function MeleeWeapon:Destroy()
    self.trove:Destroy()
end

return MeleeWeapon
