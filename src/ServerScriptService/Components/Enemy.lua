local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ServerStorage = game:GetService("ServerStorage")
local PathfindingService = game:GetService("PathfindingService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Items = game:GetService("ServerStorage").Items
local LootTable = require(ServerStorage.Source.LootTable)

local DEBRIS_TIME = 5
local ITEM_TOUCH_DEBOUNCE_TIME = 1
local SHOW_VISUAL_WAYPOINTS = false
local PATROL_DISTANCE = 10
local PATROL_INTERVAL = 2
local DETECT_TARGET_INTERVAL = 0.2
local CHASE_TARGET_INTERVAL = 0.2

-- Managing aggro
local MAX_CHASE_DISTANCE = 80
local AGGRO_DEBOUNCE_COOLDOWN = 3

local Enemy = Component.new({
    Tag = "Enemy"
})

function Enemy:Construct()
    self.trove = Trove.new()
    self.animations = {}
    self.currentAnimTrack = nil
    self.dead = false
    self.walkSpeed = self.Instance:GetAttribute("WalkSpeed")
    self.runSpeed = self.Instance:GetAttribute("RunSpeed")
    self.attackDamage = self.Instance:GetAttribute("AttackDamage")
    self.attackDistance = self.Instance:GetAttribute("AttackDistance")
    self.detectDistance = self.Instance:GetAttribute("DetectDistance")

    -- This should take into account the length of the attack animation
    self.attackInterval = self.Instance:GetAttribute("AttackInterval")

    self.damagedEvent = Instance.new("BindableEvent")
    self.damagedEvent.Name = "Damaged"
    self.damagedEvent.Archivable = false
    self.damagedEvent.Parent = self.Instance

    -- Pathfinding
    self.path = nil
    self.spawnPosition = self.Instance.PrimaryPart.Position

    -- Patrolling
    self.patrolDebounce = false
    self.lastPatrolTime = 0
    self.currentWaypoint = nil

    -- Detecting target
    self.target = nil
    self.bodyGyro = nil
    self.detectDebounce = false
    self.lastDetectTime = 0

    -- Chasing target
    self.chaseDebounce = false
    self.lastChaseTime = 0

    -- For de-aggroing
    self.aggroDebounce = false
    self.aggroDebounceTime = 0

    -- Attacking target
    self.lastAttackTime = 0
    self.attackComboCount = 0
    self.attackDebounce = false

    self.Instance.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

    local function LoadAnimations()
        local animator = self.Instance.Humanoid.Animator

        -- TODO: Could define these animations in code instead of from folders so its easier to change
        for _, anim in pairs(self.Instance.Animations:GetChildren()) do
            local animName = anim.Name

            self.animations[animName] = animator:LoadAnimation(anim)
        end
    end

    LoadAnimations()
end

function Enemy:PlayAnim(animName, freezeMarker)
    if self.currentAnimTrack ~= nil then
        self.currentAnimTrack:Stop()
    end

    self.currentAnimTrack = self.animations[animName]

    if not self.currentAnimTrack.IsPlaying then
        self.currentAnimTrack:Play()
    end

    -- Freeze the animation at a specified marker. Is used to freeze death animation.
    if freezeMarker ~= nil then
        self.currentAnimTrack:GetMarkerReachedSignal(freezeMarker):Connect(function()
            self.currentAnimTrack:AdjustSpeed(0)
        end)
    end
end

function Enemy:StopAnim(animName)
    local animTrack = self.animations[animName]

    if animTrack.IsPlaying then
        animTrack:Stop()
    end
end

function Enemy:GetRandomDestination()
    local x = math.random(-PATROL_DISTANCE, PATROL_DISTANCE)
    local z = math.random(-PATROL_DISTANCE, PATROL_DISTANCE)
    local dest = self.spawnPosition + Vector3.new(x, 0, z)

    return dest
end

function Enemy:OnDeath()
    self.dead = true

    self:ResetTarget()

    -- TODO: May need to loop through all parts of the enemy to disable collisions. Player still gets stuck on dead body.
    self.Instance.PrimaryPart.Anchored = true
    self.Instance.PrimaryPart.CanCollide = false

    self:PlayAnim("Death", "End")

    local lootTable = LootTable[self.Instance.Name]

    local lootName = self:GetRandomLoot(lootTable)
    local item = Items:FindFirstChild(lootName)

    if item then
        local lootItem = item:Clone()

        -- TODO: Once we reconstruct the bow without a union only use handle
        local lootItemPart = lootItem:FindFirstChild("Union") or lootItem:FindFirstChild("Handle")
        lootItemPart.CFrame = self.Instance.PrimaryPart.CFrame
        lootItemPart.CanTouch = false
        lootItem.Handle.CanTouch = false
        lootItemPart.CanCollide = true
        lootItemPart.Anchored = false
        lootItem.Parent = workspace

        task.wait(ITEM_TOUCH_DEBOUNCE_TIME)
        lootItemPart.CanTouch = true
        lootItem.Handle.CanTouch = true
    end

    -- Remove enemy
    Debris:AddItem(self.Instance, DEBRIS_TIME)
end

function Enemy:Patrol()
    if not self.patrolDebounce and tick() - self.lastPatrolTime >= PATROL_INTERVAL then
        self.patrolDebounce = true

        local dest = self:GetRandomDestination()

        self.path = PathfindingService:CreatePath()

        local success = pcall(function()
            self.path:ComputeAsync(self.Instance.HumanoidRootPart.Position, dest)
        end)

        local blockedWaypointIndex = 0
        local blockedConn
        local moveToFinished

        if success and self.path.Status == Enum.PathStatus.Success then
            local waypoints = self.path:GetWaypoints()

            blockedConn = self.path.Blocked:Connect(function(index)
                blockedWaypointIndex = index
            end)

            self:PlayAnim("Walk")
            self.Instance.Humanoid.WalkSpeed = self.walkSpeed

            for i, waypoint in ipairs(waypoints) do
                if SHOW_VISUAL_WAYPOINTS then
                    self:CreateVisualWaypoint(waypoint.Position)
                end

                self.currentWaypoint = waypoint.Position

                self.Instance.Humanoid:MoveTo(waypoint.Position)

                moveToFinished = self.Instance.Humanoid.MoveToFinished:Wait()

                local isBlocked = blockedWaypointIndex >= i and blockedWaypointIndex - i <= 2

                if not moveToFinished or isBlocked or self.dead or self.target then
                    break
                end
            end
        end

        blockedConn:Disconnect()
        self.path:Destroy()
        self:StopAnim("Walk")
        self.patrolDebounce = false
        self.lastPatrolTime = tick()
    end
end

function Enemy:DetectTarget()
    if not self.detectDebounce and tick() - self.lastDetectTime >= DETECT_TARGET_INTERVAL then
        self.detectDebounce = true

        for _, player in pairs(Players:GetPlayers()) do
            local character = player.Character
            local distance = player:DistanceFromCharacter(self.Instance.HumanoidRootPart.Position)

            if character and character.Humanoid.Health ~= 0 and distance <= self.detectDistance then
                self:SetTarget(player)
                break
            end
        end

        self.detectDebounce = false
        self.lastDetectTime = tick()
    end
end

function Enemy:SetTarget(target)
    if not self.target and target.Character then
        self.target = target
        local targetPosition = target.Character.HumanoidRootPart.Position

        -- TODO: May need to adjust turn speed based on enemy. Enemies like ghosts get stuck on eachother so they can't turn towards player.
        -- Look into switching to alternative way of turning without body gyro.
        local h = math.huge
        local bodyGyro = Instance.new("BodyGyro", self.Instance.HumanoidRootPart)
        bodyGyro.D = 100
        bodyGyro.P = 1000
        bodyGyro.MaxTorque = Vector3.new(h, 500, h)
        bodyGyro.CFrame = CFrame.lookAt(self.Instance.HumanoidRootPart.Position, targetPosition)

        self.bodyGyro = bodyGyro
    end
end

function Enemy:ResetTarget()
    self.target = nil

    if self.bodyGyro then
        self.bodyGyro:Destroy()
        self.bodyGyro = nil
    end
end

function Enemy:Attack()
    if not self.attackDebounce and tick() - self.lastAttackTime > self.attackInterval then
        self.attackDebounce = true

        self.attackComboCount = self.attackComboCount + 1

        if self.attackComboCount < 2 then
            self:PlayAnim("Attack1")
        else
            self:PlayAnim("Attack2")
            self.attackComboCount = 0
        end

        local hitbox = Instance.new("Part", self.Instance)
        hitbox.Anchored = true
        hitbox.CanCollide = false
        hitbox.Massless = true
        hitbox.Size = Vector3.new(5, 5, 6)
        hitbox.Transparency = 1
        hitbox.CFrame = self.Instance.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
        Debris:AddItem(hitbox, self.attackInterval)

        local playersHit = {}

        hitbox.Touched:Connect(function(hit)
            local player = Players:GetPlayerFromCharacter(hit.parent)
            local hum

            if player and player.Character then
                hum = player.Character:FindFirstChildWhichIsA("Humanoid")
            end

            if hum and hum.Health ~= 0 and not playersHit[player.UserId] then
                hum:TakeDamage(self.attackDamage)

                playersHit[player.UserId] = true
            end
        end)

        self.lastAttackTime = tick()
        self.attackDebounce = false
    end
end

function Enemy:ChaseTarget()
    if not self.chaseDebounce and tick() - self.lastChaseTime > CHASE_TARGET_INTERVAL and self.target.Character then
        self.chaseDebounce = true

        local targetPosition = self.target.Character.HumanoidRootPart.Position

        local distance =
            (self.Instance.HumanoidRootPart.Position - self.target.Character.HumanoidRootPart.Position).Magnitude

        local inAttackRange = distance <= self.attackDistance
        local maxAggroDistance = self.attackDistance * 2
        local distanceFromSpawn = (self.Instance.HumanoidRootPart.Position - self.spawnPosition).Magnitude
        local targetIsDead = self.target.Character.Humanoid.Health == 0

        if self.bodyGyro then
            self.bodyGyro.CFrame = CFrame.lookAt(self.Instance.HumanoidRootPart.Position, targetPosition)
        end

        if inAttackRange and not targetIsDead then
            self:Attack()
        else
            if (distanceFromSpawn > MAX_CHASE_DISTANCE and distance > maxAggroDistance) or targetIsDead then
                -- Deaggro if too far from spawn and out of player aggro range or player dead
                targetPosition = self.spawnPosition

                if self.currentWaypoint ~= nil then
                    targetPosition = self.currentWaypoint
                end

                self:ResetTarget()

                if not targetIsDead then
                    self.aggroDebounce = true
                    self.aggroDebounceTime = tick()
                end
            end

            if not self.animations.Run.IsPlaying then
                self:PlayAnim("Run")
                self.Instance.Humanoid.WalkSpeed = self.runSpeed
            end

            self.Instance.Humanoid:MoveTo(targetPosition)
        end

        self.lastChaseTime = tick()
        self.chaseDebounce = false
    end
end

function Enemy:GetRandomLoot(lootTable)
    local sum = 0
    for _, chance in pairs(lootTable) do
        sum = sum + chance
    end
    local randNum = math.random(sum)
    for itemName, chance in pairs(lootTable) do
        if randNum <= chance then
            return itemName
        else
            randNum = randNum - chance
        end
    end
end

function Enemy:Start()
    self.animations.Idle:Play()

    self.Instance.Humanoid.Died:Connect(function()
        self:OnDeath()
    end)

    -- This can fire when player uses ranged attacks to aggro the enemy
    self.Instance.Damaged.Event:Connect(function(player)
        self:SetTarget(player)
    end)
end

function Enemy:HeartbeatUpdate()
    if self.dead then
        return
    end

    if self.target then
        self:ChaseTarget()
    else
        if not self.aggroDebounce then
            self:Patrol()
            self:DetectTarget()
        elseif tick() - self.aggroDebounceTime >= AGGRO_DEBOUNCE_COOLDOWN then
            self.aggroDebounce = false
            self.aggroDebounceTime = 0
        end
    end
end

function Enemy:Destroy()
    self.trove:Destroy()
end

-- Visual debugging stuff
function Enemy:CreateVisualWaypoint(position)
    local part = Instance.new("Part")
    part.Shape = "Ball"
    part.Material = "Neon"
    part.Size = Vector3.new(0.6, 0.6, 0.6)
    part.Position = position
    part.Anchored = true
    part.CanCollide = false
    part.Parent = game.Workspace
end

return Enemy
