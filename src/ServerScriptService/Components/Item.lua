local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local DropEvent = ReplicatedStorage.Events.Drop
local EquipEvent = ReplicatedStorage.Events.Equip

-- An item is a tool for now
-- TODO: Add despawn functionality if its not owned by a player
local Item = Component.new({
    Tag = "Item"
})

function Item:Construct()
    self.trove = Trove.new()
end

function Item:Start()
    -- An item's ancestry will change if it gets picked up by a player or dropped
    local function OnAncestryChanged(_, parent)
        local player = Players:GetPlayerFromCharacter(parent)

        if parent and parent:IsA("Player") then
           player = parent
        end

        if player then
            self.Instance:SetAttribute("PlayerId", player.UserId)
        else
            self.Instance:SetAttribute("PlayerId", 0)
        end
    end

    local function IsSamePlayer(player)
        return self.Instance:GetAttribute("PlayerId") == player.UserId
    end

    local function OnEquip(player, equipped)
        if not IsSamePlayer(player) then return end

        print("Item equip")

        if equipped then
            local character = player.Character

            if character then
                self.Instance:SetPrimaryPartCFrame(character.RightHand.CFrame * CFrame.new(0, 0, 0))
                self.Instance.Parent = character

                local weld = Instance.new("WeldConstraint")
                weld.Name = "HandWeld"
                weld.Part0 = self.Instance.PrimaryPart
                weld.Part1 = character.RightHand
                weld.Parent = weld.Part0
            end
        else
            local handWeld = self.Instance.PrimaryPart:FindFirstChild("HandWeld")

            if handWeld then
                handWeld:Destroy()
            end

            self.Instance.Parent = player
        end
    end

    local function OnDrop(player)
        if not IsSamePlayer(player) then return end

        self.Instance.Parent = game.Workspace
    end

    local function OnTouched(part)
        local playerId = self.Instance:GetAttribute("PlayerId")

        if playerId and playerId ~= 0 then
			return
		end

        local player = Players:GetPlayerFromCharacter(part.parent)

        if player and player.Character then
			local humanoid = player.Character:FindFirstChildWhichIsA("Humanoid")

            if humanoid.Health > 0 then
                self.Instance.Parent = player
            end
        end
    end

    self.trove:Add(DropEvent.OnServerEvent:Connect(OnDrop))
    self.trove:Add(EquipEvent.OnServerEvent:Connect(OnEquip))
    self.trove:Add(self.Instance.AncestryChanged:Connect(OnAncestryChanged))
    self.trove:Add(self.Instance.Handle.Touched:Connect(OnTouched))
end

function Item:Destroy()
    self.trove:Destroy()
end

return Item
