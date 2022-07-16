local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local inventoryDS = DataStoreService:GetDataStore("Inventory")
local itemsFolder = ServerStorage.Items

local InventoryService = Knit.CreateService {
    Name = "InventoryService",
    Client = {}
}

function InventoryService:HandlePlayerInventory()
    local function LoadInventory(player)
        local success, inventory = pcall(function()
            return inventoryDS:GetAsync(player.UserId) or {}
        end)

        if success then
            print("Loaded # of items", table.getn(inventory))
            print("For player: ", player.UserId)
        end

        player.CharacterAdded:Connect(function(char)
            -- NOTE: Sometimes adding to backpack doesn't work if you keep reloading the game. Might not be an issue in production.
            -- May need to refactor how inventory is saved and loaded. 
            local backpack = player:WaitForChild("Backpack")

            -- task.wait() helps a little but not consistent
            task.wait(1)

            -- Add item from inventory data to backpack
            for _, itemName in ipairs(inventory) do
                local item = itemsFolder[itemName]:Clone()

                item.Parent = backpack
            end
        end)

        player.CharacterRemoving:Connect(function(char)
            char.Humanoid:UnequipTools()
        end)
    end

    local function SaveInventory(player)
        local items = {}
        local backpack = player:WaitForChild("Backpack")

        for _, item in ipairs(backpack:GetChildren()) do
            table.insert(items, item.Name)
        end

        local success, errormsg = pcall(function()
            inventoryDS:SetAsync(player.UserId, items)
        end)

        if success then
            print("Saved # of items: ", table.getn(items))
            print("For player: ", player.UserId)
        end

        if errormsg then
            warn(errormsg)
        end
    end

    Players.PlayerAdded:Connect(function(player)
        -- LoadInventory(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        -- SaveInventory(player)
    end)
end

function InventoryService:KnitInit()
    self:HandlePlayerInventory()
end

function InventoryService:KnitStart()
end

return InventoryService
