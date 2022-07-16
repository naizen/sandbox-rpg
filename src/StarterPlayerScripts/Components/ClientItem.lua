local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Input = require(ReplicatedStorage.Packages.Input)

local ClientItem = Component.new({
    Tag = "Item",
    Extensions = {}
})

function ClientItem:Construct()
    self.trove = Trove.new()
    self.inputTrove = self.trove:Extend()
end

function ClientItem:Start()
    local keyboard = Input.Keyboard.new()

    local function OnKeyDown(keycode)
        if keycode == Enum.KeyCode.E then
            self.Instance.Drop:FireServer()
        end
    end

    local function OnEquipped()
        self.inputTrove:Add(keyboard.KeyDown:Connect(OnKeyDown))
    end

    local function OnUnequipped()
        self.inputTrove:Clean()
    end

    self.trove:Add(self.Instance.Equipped:Connect(OnEquipped))
    self.trove:Add(self.Instance.Unequipped:Connect(OnUnequipped))
end

function ClientItem:Destroy()
    self.trove:Destroy()
end

return ClientItem
