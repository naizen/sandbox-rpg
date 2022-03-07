local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Change default cursor
local mouse = player:GetMouse()
mouse.Icon = "rbxassetid://8259335784"

-- Disable default health bar
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
