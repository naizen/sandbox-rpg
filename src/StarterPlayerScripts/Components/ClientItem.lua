local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ForLocalPlayer = require(StarterPlayer.StarterPlayerScripts.Source.ComponentExtensions.ForLocalPlayer)

local ClientItem = Component.new({
    Tag = "Item",
    Extensions = {ForLocalPlayer}
})

function ClientItem:Construct()
    self.trove = Trove.new()
    self.playerTrove = self.trove:Extend()
    self.activateTrove = self.trove:Extend()
    self.Activate = Signal.new()
    self.Equip = Signal.new()
end

function ClientItem:SetupForLocalPlayer()
    local ItemService = Knit.GetService("ItemService")
    local HotbarController = Knit.GetController("HotbarController")

    local function OnEquippedChanged()
        local isEquipped = self.Instance:GetAttribute("IsEquipped")

        -- print("ClientItem equip changed: ", self.Instance.Name)
        -- print("Equipped? ", isEquipped)

        ItemService.Equip:Fire(self.Instance, isEquipped)

        if isEquipped then
            self.activateTrove:Add(HotbarController.ItemActivated:Connect(function()
                self.Activate:Fire()
            end))
        else
            self.activateTrove:Clean()
        end
    end

    local function OnItemDrop(droppedItem)
        if droppedItem ~= self.Instance then
            return
        end

        ItemService.Drop:Fire(self.Instance)
    end

    self.playerTrove:Add(self.Instance:GetAttributeChangedSignal("IsEquipped"):Connect(OnEquippedChanged))
    self.playerTrove:Add(HotbarController.ItemDropped:Connect(OnItemDrop))
end

function ClientItem:CleanupForLocalPlayer()
    self.playerTrove:Clean()
end

function ClientItem:Start()
    -- print("Client Item started: ", self.Instance.Name)
end

function ClientItem:Destroy()
    self.trove:Destroy()
end

return ClientItem
