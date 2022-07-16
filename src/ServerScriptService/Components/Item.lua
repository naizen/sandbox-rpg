local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Promise = require(ReplicatedStorage.Packages.Promise)

local PICKUP_DEBOUNCE_TIME = 2

-- Handles items spawned in the world to be picked up by players
local Item = Component.new({
    Tag = "Item"
})

function Item:Construct()
    self.trove = Trove.new()
    self.touchTrove = self.trove:Extend()

    self.dropEvent = Instance.new("RemoteEvent")
    self.dropEvent.Name = "Drop"
    self.dropEvent.Archivable = false
    self.dropEvent.Parent = self.Instance
end

function Item:Start()
    local function OnDrop()
        self.Instance.Handle.CanTouch = false
        self.Instance.Parent = game.Workspace

        task.wait(PICKUP_DEBOUNCE_TIME)
        self.Instance.Handle.CanTouch = true
    end

    self.trove:Add(self.dropEvent.OnServerEvent:Connect(OnDrop))
end

function Item:Destroy()
    self.trove:Destroy()
end

return Item
