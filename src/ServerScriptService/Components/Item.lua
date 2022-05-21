local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Prefabs = game:GetService("ServerStorage").Prefabs

-- Handles items spawned in the world to be picked up by players
local Item = Component.new({
    Tag = "Item"
})

function Item:Construct()
    self.trove = Trove.new()
    self.playerTrove = self.trove:Extend()
    self.touchedConnection = nil
end

function Item:Start()
    local function AttachToPlayer(player)
        -- print("AttachToPlayer: ", player.UserId)

        local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

        if humanoid.Health <= 0 then
            return
        end

        if self.touchedConnection then
            self.touchedConnection:Disconnect()
        end

        self.Instance.Parent = player
        self.Instance:SetAttribute("PlayerId", player.UserId)
    end

    local function OnTouched(part)
        local player = Players:GetPlayerFromCharacter(part.parent)

        if player and player.Character then
            AttachToPlayer(player)
        end
    end

    local function ListenForTouch()
        -- print("Item ListenForTouch")
        self.touchedConnection = self.Instance.Handle.Touched:Connect(OnTouched)
    end

    ListenForTouch()

    local function OnPlayerChanged()
        local playerId = self.Instance:GetAttribute("PlayerId")

        if playerId == 0 then
            task.wait(1)

            ListenForTouch()
        end
    end

    self.trove:Add(self.Instance:GetAttributeChangedSignal("PlayerId"):Connect(OnPlayerChanged))
end

function Item:Destroy()
    self.trove:Destroy()
end

return Item
