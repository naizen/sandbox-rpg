local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
-- local TaskQueue = require(ReplicatedStorage.Packages.TaskQueue)

local InventoryDataStore = DataStoreService:GetDataStore("Inventory")
local Prefabs = game:GetService("ServerStorage").Prefabs

local InventoryService = Knit.CreateService {
    Name = "InventoryService",
    Client = {}
}

local INIT_ITEMS = {}

function InventoryService:KnitInit()
    local function LoadInventory(player)
        local success, inventory = pcall(function()
            return InventoryDataStore:GetAsync(player.UserId)
        end)

        local playerInventory = INIT_ITEMS

        if success and inventory and table.getn(inventory) > 0 then
            playerInventory = inventory
        end

        for _, itemName in pairs(playerInventory) do
            local item = Prefabs:FindFirstChild(itemName)

            if item then
                item:Clone().Parent = player
            end
        end

        player.CharacterRemoving:Connect(function(character)
            character:WaitForChild("Humanoid"):UnequipTools()
        end)
    end

    local function SaveInventory(player)
        local playerTools = {}

        -- Get current tools in backpack to save
        -- for _, tool in pairs(player.Backpack:GetChildren()) do
        --     table.insert(playerTools, tool.Name)
        -- end

        local success = pcall(function()
            InventoryDataStore:setAsync(player.UserId, playerTools)
        end)

        if success then
            print("Saved inventory")
        else
            print("Failed saving inventory")
        end
    end

    Players.PlayerAdded:Connect(LoadInventory)
    Players.PlayerRemoving:Connect(SaveInventory)
end

function InventoryService:KnitStart()
end

return InventoryService
