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

function InventoryService:KnitInit()
    local function LoadInventory(player)
        local success, playerInventory = pcall(function()
            return InventoryDataStore:GetAsync(player.UserId)
        end)

        if success and playerInventory then
            -- print("Loaded player inventory")

            for _, toolName in pairs(playerInventory) do
                -- print("Adding item: ", toolName)

                local tool = Prefabs:FindFirstChild(toolName)

                if tool then
                    tool:Clone().Parent = player.Backpack
                    tool:Clone().Parent = player.StarterGear
                end
            end
        else
            -- print("Could not load player inventory")
            -- We can initialize some starting items here
            playerInventory = {}
        end

        player.CharacterRemoving:Connect(function(character)
            character:WaitForChild("Humanoid"):UnequipTools()
        end)
    end

    local function SaveInventory(player)
        local playerTools = {}

        -- Get current tools in backpack to save
        for _, tool in pairs(player.Backpack:GetChildren()) do
            table.insert(playerTools, tool.Name)
        end

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
