local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ForLocalPlayer = require(ReplicatedStorage.Source.ComponentExtensions.ForLocalPlayer)
local Input = require(ReplicatedStorage.Packages.Input)
local DropEvent = ReplicatedStorage.Events.Drop
local EquipEvent = ReplicatedStorage.Events.Equip

local Keyboard = Input.Keyboard

local ClientItem = Component.new({
    Tag = "Item",
    Extensions = {ForLocalPlayer}
})

function ClientItem:Construct()
    self.trove = Trove.new()
    self.playerTrove = self.trove:Extend()
end

function ClientItem:SetupForLocalPlayer()
    local keyboard = Keyboard.new()
    local equipped = false

    local function OnKeyDown(keycode)
        -- TODO: Replace with hotbar keybinds
        if keycode == Enum.KeyCode.Q then
            equipped = not equipped

            print("ClientItem equip: ", equipped)

            EquipEvent:FireServer(equipped)
        elseif keycode == Enum.KeyCode.E then
            DropEvent:FireServer()
        end
    end

    self.playerTrove:Add(keyboard.KeyDown:Connect(OnKeyDown))
end

function ClientItem:CleanupForLocalPlayer()
    self.playerTrove:Clean()
end

function ClientItem:Start()
end

function ClientItem:Destroy()
    self.trove:Destroy()
end

return ClientItem
