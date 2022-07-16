local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local New = Fusion.New
local Children = Fusion.Children
local State = Fusion.State
local Computed = Fusion.Computed

local HUD_FONT = "GothamBold"

local HUDController = Knit.CreateController {
    Name = "HUDController",
    healthPercent = State(1),
    staminaPercent = State(1)
}

function HUDController:KnitInit()
    local PlayerController = Knit.GetController("PlayerController")

    PlayerController.StaminaChanged:Connect(function(staminaPercent)
        self.staminaPercent:set(staminaPercent)
    end)

    PlayerController.HealthChanged:Connect(function(healthPercent)
        self.healthPercent:set(healthPercent)
    end)
end

function HUDController:KnitStart()
    local healthBar = New "Frame" {
        Name = "HealthBarFrame",
        Position = UDim2.fromScale(0.06, 0.77),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 20, 0),
        BackgroundTransparency = 0.8,
        Size = UDim2.new(0.2, 0, 0, 30),
        [Children] = {New "Frame" {
            Name = "HealthBar",
            Position = UDim2.fromScale(0, 0),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.new(0, 1, 0),
            Size = Computed(function()
                return UDim2.fromScale(self.healthPercent:get(), 1)
            end)
        }, New "TextLabel" {
            Position = UDim2.new(0, 4, -1, 0),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundTransparency = 1,
            Size = UDim2.fromScale(1, 1),
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = HUD_FONT,
            Text = Knit.Player.DisplayName
        }}
    }

    local staminaBar = New "Frame" {
        Name = "StaminaBarFrame",
        Position = UDim2.new(0.06, 0, 0.77, 35),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundColor3 = Color3.fromRGB(0, 20, 34),
        BackgroundTransparency = 0.8,
        Size = Computed(function()
            return UDim2.new(0.2, 0, 0, 30)
        end),
        [Children] = {New "Frame" {
            Name = "StaminaBar",
            Position = UDim2.fromScale(0, 0),
            AnchorPoint = Vector2.new(0, 0),
            BackgroundColor3 = Color3.fromRGB(2, 219, 226),
            Size = Computed(function()
                return UDim2.fromScale(self.staminaPercent:get(), 1)
            end)
        }}
    }

    local hud = New "ScreenGui" {
        Parent = Knit.Player.PlayerGui,
        Name = "HUD",
        ResetOnSpawn = false,
        ZIndexBehavior = "Sibling",
        [Children] = {healthBar, staminaBar}
    }
end

return HUDController
