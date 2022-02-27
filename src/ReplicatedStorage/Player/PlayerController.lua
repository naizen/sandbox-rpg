local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerConfig = require(script.Parent.PlayerConfig)

-- PlayerController handles the local player's state, movement inputs
-- and holds all possible player animations for movement, combat, etc.
local PlayerController = Knit.CreateController {
    Name = "PlayerController"
}

function PlayerController:KnitInit()
    Knit.Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:WaitForChild("Animator")

        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

        -- Loaded player animation instances
        self.LoadedAnimations = {}

        -- Recursively loop through animations and load them
        local function LoadAnimations(e)
            if type(e) == "table" then
                for _, v in pairs(e) do
                    LoadAnimations(v)
                end
            elseif type(e) == "number" then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. e
                local loadedAnim = animator:LoadAnimation(anim)

                self.LoadedAnimations[e] = loadedAnim
            end
        end

        LoadAnimations(PlayerConfig.Animations)
    end)
end

function PlayerController:KnitStart()
end

return PlayerController
