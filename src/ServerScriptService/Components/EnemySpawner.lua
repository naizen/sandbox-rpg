local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Enemies = game:GetService("ServerStorage").Enemies

local EnemySpawner = Component.new({
    Tag = "EnemySpawner"
})

function EnemySpawner:Construct()
    self.trove = Trove.new()
    self.type = self.Instance:GetAttribute("Type")
    self.spawnRange = self.Instance:GetAttribute("SpawnRange")
    self.spawnLimit = self.Instance:GetAttribute("SpawnLimit")
    self.respawnTime = self.Instance:GetAttribute("RespawnTime")
    self.respawn = Signal.new()
end

function EnemySpawner:SpawnEnemy()
    local model = Enemies[self.type]:Clone()

    -- Spawn at a random location in range of this spawner
    local x = math.random(-self.spawnRange, self.spawnRange)
    local z = math.random(-self.spawnRange, self.spawnRange)
    local angle = math.rad(math.random(-180, 180))

    model:SetPrimaryPartCFrame(self.Instance.CFrame * CFrame.new(x, 0, z) * CFrame.Angles(0, angle, 0))

    -- Set enemy parts' network ownership to the server to reduce lag
    local function SetNetworkOwnerToServer()
        for k, v in pairs(model:GetDescendants()) do
            if v:IsA("BasePart") and v:CanSetNetworkOwnership() then
                v:SetNetworkOwner(nil)
            end
        end
    end

    model.Parent = workspace

    self.trove:Add(model:GetPropertyChangedSignal("Parent"):Connect(function()
        if not model.Parent then
            self.trove:Add(Promise.delay(self.respawnTime):andThen(function()
                self.respawn:Fire()
            end), "cancel")
        end
    end))

    SetNetworkOwnerToServer()
end

function EnemySpawner:Start()
    self.respawn:Connect(function()
        self:SpawnEnemy()
    end)

    for i = 1, self.spawnLimit do
        self:SpawnEnemy()
    end
end

function EnemySpawner:Destroy()
    self.trove:Destroy()
end

return EnemySpawner
