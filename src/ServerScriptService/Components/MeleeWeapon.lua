local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local RaycastHitbox = require(ReplicatedStorage.Packages.Hitbox)
local FX = ServerStorage.FX
local Sounds = ServerStorage.Sounds

-- TODO: Replace with a service instead. Manually created remote events on items are not going to scale. Any changes you will have to copy and paste for each item 

local MeleeWeapon = Component.new({
    Tag = "MeleeWeapon"
})

function MeleeWeapon:Construct()
    self.trove = Trove.new()
    self.hitboxTrove = self.trove:Extend()
end

function MeleeWeapon:Start()
    -- local clientWeapon = self:GetComponent(ClientMeleeWeapon)

    -- print("Client weapon: ", clientWeapon)

    -- self.trove:Add(AttackEvent.OnServerEvent:Connect(function()
    --     print("MeleeWeapon Attack from Server")
    -- end))
    -- local StatsService = Knit.GetService("StatsService")
    -- local hitbox
    -- local damage = 25

    -- local function IsSamePlayer(player)
    --     return self.Instance:GetAttribute("PlayerId") == player.UserId
    -- end

    -- local function AddWeaponTrail()
    --     local trail = FX.SwordTrail:Clone()
    --     trail.Parent = self.Instance.Blade
    --     trail.Attachment0 = self.Instance.Blade.Attachment0
    --     trail.Attachment1 = self.Instance.Blade.Attachment1
    --     Debris:AddItem(trail, 0.3)
    -- end

    -- local function PlaySlashSound()
    --     local slashSound = Sounds.Slash:Clone()
    --     slashSound.Parent = self.Instance
    --     slashSound.PlaybackSpeed = math.random(85, 110) / 100
    --     slashSound:Play()

    --     Debris:AddItem(slashSound, 0.4)
    -- end

    -- local function OnAttack(player)
    --     if not IsSamePlayer(player) then
    --         return
    --     end

    --     AddWeaponTrail()
    --     PlaySlashSound()

    --     hitbox:HitStart()
    --     hitbox.OnHit:Connect(function(hit, humanoid)
    --         humanoid:TakeDamage(damage)
    --         StatsService:UpdateStat(player, 'strength', 'xp', 10)
    --     end)
    -- end

    -- local function SetupHitbox(player)
    --     hitbox = RaycastHitbox.new(self.Instance)
    --     local raycastParams = RaycastParams.new()
    --     hitbox.Visualizer = true
    --     raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    --     raycastParams.FilterDescendantsInstances = {self.Instance, player.Character}
    --     hitbox.RaycastParams = self.raycastParams
    --     self.hitboxTrove:Add(hitbox)

    --     local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

    --     self.hitboxTrove:Add(humanoid.Died:Connect(function()
    --         self.hitboxTrove:Clean()
    --     end))

    --     self.hitboxTrove:Add(Players.PlayerRemoving:Connect(function(playerRemoved)
    --         if playerRemoved == player then
    --             self.hitboxTrove:Clean()
    --         end
    --     end))
    -- end

    -- local function OnEquip(player, equipped)
    --     if not IsSamePlayer(player) then
    --         return
    --     end

    --     if equipped then
    --         SetupHitbox(player)
    --     else
    --         self.hitboxTrove:Clean()
    --     end
    -- end

    -- local function OnDrop(player)
    --     if not IsSamePlayer(player) then
    --         return
    --     end

    --     self.hitboxTrove:Clean()
    -- end

    -- self.trove:Add(AttackEvent.OnServerEvent:Connect(OnAttack))
    -- self.trove:Add(EquipEvent.OnServerEvent:Connect(OnEquip))
    -- self.trove:Add(DropEvent.OnServerEvent:Connect(OnDrop))
end

function MeleeWeapon:Destroy()
    self.trove:Destroy()
end

return MeleeWeapon
