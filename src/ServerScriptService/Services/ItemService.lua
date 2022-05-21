local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- Handles client to server interactions related to player items
local ItemService = Knit.CreateService {
    Name = "ItemService",
    Client = {
        ListenForTouch = Knit.CreateSignal(),
        Equip = Knit.CreateSignal(),
        Unequip = Knit.CreateSignal(),
        Drop = Knit.CreateSignal(),
        Consume = Knit.CreateSignal()
    }
}

function ItemService:KnitInit()
    local function DestroyWeld(item)
        local weld = item.Handle:FindFirstChildWhichIsA("WeldConstraint")

        if weld then
            weld:Destroy()
        end
    end

    self.Client.Equip:Connect(function(player, item, equipped)
        if player.UserId ~= item:GetAttribute("PlayerId") then
            return
        end

        -- Attach/detach item from player's hand
        if equipped then
            local newCFrame = player.Character.RightHand.CFrame * CFrame.new(0, 0, 0)

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = item.Handle
            weld.Part1 = player.Character.RightHand
            weld.Parent = weld.Part0

            item:SetPrimaryPartCFrame(newCFrame)
            item.Parent = player.Character
        else
            DestroyWeld(item)

            item.Parent = player
        end
    end)

    self.Client.Drop:Connect(function(player, item)
        DestroyWeld(item)
        item:SetAttribute("PlayerId", 0)
        item:SetAttribute("IsEquipped", false)
        item.Parent = game.Workspace
    end)

    self.Client.Consume:Connect(function(player, item)
        print("Player consume item")
    end)
end

function ItemService:KnitStart()
end

return ItemService
