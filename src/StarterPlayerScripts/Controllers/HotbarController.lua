local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Mouse = Input.Mouse
local Keyboard = Input.Keyboard
local Trove = require(ReplicatedStorage.Packages.Trove)

local slotKeybinds = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3
}

local INPUT_DEBOUNCE_TIME = 0.5

local HotbarController = Knit.CreateController {
    Name = "HotbarController",
    inputTrove = Trove.new(),
    slots = {},
    equippedSlotIndex = nil,
    activeItem = nil,
    playerController = nil,
    inputDebounce = false
}

HotbarController.ItemActivated = Signal.new()
HotbarController.ItemDropped = Signal.new()

function HotbarController:Setup()
    Knit.Player.CharacterAdded:Connect(function()
        self.playerController = Knit.GetController("PlayerController")
        local keyboard = Keyboard.new()
        local mouse = Mouse.new()

        self.inputTrove:Add(keyboard.KeyDown:Connect(function(keycode)
            if self.playerController.Humanoid and self.playerController.Humanoid:GetState() ==
                Enum.HumanoidStateType.Dead then
                return
            end

            self:OnKeyDown(keycode)
        end))

        self.inputTrove:Add(mouse.LeftDown:Connect(function()
            if self.playerController.Humanoid and self.playerController.Humanoid:GetState() ==
                Enum.HumanoidStateType.Dead then
                return
            end

            self:OnMouseLeftDown()
        end))
    end)

    Knit.Player.CharacterRemoving:Connect(function()
        self.inputTrove:Clean()
    end)

    Knit.Player.ChildAdded:Connect(function(child)
        if not CollectionService:HasTag(child, "Item") then
            return
        end

        local item = child

        if self:IsItemAdded(item) then
            return
        end

        if item ~= nil and item ~= self.activeItem then
            -- Adds item to a slot
            table.insert(self.slots, item)
        end
    end)
end

function HotbarController:OnKeyDown(keycode)
    -- if self.inputDebounce then
    --     return
    -- end

    -- Dropping item
    if keycode == Enum.KeyCode.Q and self:IsActiveItemEquipped() then
        self:DropActiveItem()
        return
    end

    local slotIndex = slotKeybinds[keycode]

    if slotIndex == nil then
        return
    end

    local item = self.slots[slotIndex]

    if not item then
        return
    end

    -- self.inputDebounce = true

    -- If switching items, unequip the previous active item
    if self.activeItem ~= nil and self.activeItem ~= item then
        self.activeItem:SetAttribute("IsEquipped", false)
    end

    local equipped = false

    self.activeItem = item

    if self.equippedSlotIndex == slotIndex then
        -- Unequip if the slot already equipped
        self.equippedSlotIndex = nil
        equipped = false
    else
        self.equippedSlotIndex = slotIndex
        equipped = true
    end

    self.playerController:Equip(item, equipped, true)
    self.activeItem:SetAttribute("IsEquipped", equipped)

    -- task.wait(INPUT_DEBOUNCE_TIME)
    -- self.inputDebounce = false
end

function HotbarController:OnMouseLeftDown()
    if self:IsActiveItemEquipped() then
        self.ItemActivated:Fire()
    end
end

function HotbarController:IsActiveItemEquipped()
    return self.equippedSlotIndex and self.activeItem
end

function HotbarController:DropActiveItem()
    self.slots[self.equippedSlotIndex] = nil
    self.equippedSlotIndex = nil
    self.ItemDropped:Fire(self.activeItem)
    self.playerController:Equip(self.activeItem, false, false)
    self.activeItem = nil
end

function HotbarController:PrintSlots()
    print("slots len: ", table.getn(self.slots))

    -- for i, tool in ipairs(self.slots) do
    --     print("tool: ", tool)
    --     print("at slot index: ", i)
    -- end
end

function HotbarController:IsItemAdded(item)
    local isAdded = false

    for _, slotItem in ipairs(self.slots) do
        if slotItem == item then
            isAdded = true
            break
        end
    end

    return isAdded
end

function HotbarController:KnitInit()
    self:Setup()
end

function HotbarController:KnitStart()
end

return HotbarController

