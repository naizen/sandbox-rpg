local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- An item is a tool for now
local Item = Component.new({
    Tag = "Item"
})

function Item:Construct()
    self.trove = Trove.new()
end

function Item:Start()
    -- A tool's ancestry will change if it gets picked up by a player or dropped
    -- TODO: Make a custom tool/item inventory system
    local function OnAncestryChanged(_, parent)
        local player = Players:GetPlayerFromCharacter(parent)

        if player then
            self.Instance:SetAttribute("PlayerId", player.UserId)
        else
            self.Instance:SetAttribute("PlayerId", 0)
        end
    end

    local function OnDrop(player)
        if self.Instance:GetAttribute("PlayerId") ~= player.UserId then
            return
        end

        self.Instance.Parent = game.Workspace
    end

    self.trove:Add(self.Instance.Drop.OnServerEvent:Connect(OnDrop))
    self.trove:Add(self.Instance.AncestryChanged:Connect(OnAncestryChanged))
end

function Item:Destroy()
    self.trove:Destroy()
end

return Item
