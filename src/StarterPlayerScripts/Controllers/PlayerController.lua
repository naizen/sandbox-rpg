local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterPlayer = game:GetService("StarterPlayer")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)
local Input = require(ReplicatedStorage.Packages.Input)
local Signal = require(ReplicatedStorage.Packages.Signal)

local DOUBLE_JUMP_POWER_MULTIPLIER = 1.2
local TIME_BETWEEN_JUMPS = 0.1

local PlayerController = Knit.CreateController {
    Name = "PlayerController",
    Sprinting = false,
    SprintSpeed = PlayerConfig.SprintSpeed,
    CanDoubleJump = false,
    HasDoubleJumped = false,
    MaxStamina = PlayerConfig.MaxStamina,
    Stamina = PlayerConfig.MaxStamina,
    StaminaChanged = Signal.new(),
    HealthChanged = Signal.new(),
    Animations = {}
}

function PlayerController:SetupInput()
    local keyboard = Input.Keyboard.new()

    -- NOTE: May have to disable shift lock camera if possible or another keybind for sprinting
    -- or else this will not trigger
    keyboard.KeyDown:Connect(function(keycode)
        if keycode == Enum.KeyCode.LeftShift then
            self.Sprinting = true
        end
    end)

    keyboard.KeyUp:Connect(function(keycode)
        if keycode == Enum.KeyCode.LeftShift then
            self.Sprinting = false
        end
    end)
end

function PlayerController:InitAnimations(animator)
    -- Recursively set all player animation instances to make them available for other client components to play
    local function SetAnimations(k)
        if type(k) == "table" then
            for _, v in pairs(k) do
                SetAnimations(v)
            end
        elseif type(k) == "number" then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://" .. k
            local loadedAnim = animator:LoadAnimation(anim)

            self.Animations[k] = loadedAnim
        end
    end

    SetAnimations(PlayerConfig.Animations)
end

function PlayerController:SetupHealth(character, humanoid)
    -- Destroy the default health regen script. We'll create health regen later.
    character:WaitForChild("Health"):Destroy()

    local function OnHealthChanged(health)
        local healthPercent = health / humanoid.MaxHealth
        self.HealthChanged:Fire(healthPercent)
    end

    OnHealthChanged(humanoid.Health)
    humanoid.HealthChanged:Connect(OnHealthChanged)
end

function PlayerController:SetupStamina(humanoid)
    local function OnStaminaChanged()
        local staminaPercent = (self.Stamina / self.MaxStamina)
        self.StaminaChanged:Fire(staminaPercent)
    end

    RunService.RenderStepped:Connect(function()
        if self.Stamina > 0 and self.Sprinting and humanoid.MoveDirection.Magnitude > 0 then
            humanoid.WalkSpeed = self.SprintSpeed
            self.Stamina = self.Stamina - PlayerConfig.StaminaDecrease

            OnStaminaChanged()
        else
            humanoid.WalkSpeed = PlayerConfig.RunSpeed
        end

        if self.Stamina < self.MaxStamina and not self.Sprinting then
            self.Stamina = self.Stamina + (PlayerConfig.StaminaDecrease * 2)

            OnStaminaChanged()
        end
    end)
end

function PlayerController:SetupDoubleJump(humanoid)
    local power = humanoid.JumpPower

    local function onJumpRequest()
        if humanoid:GetState() == Enum.HumanoidStateType.Dead then
            return
        end

        if self.CanDoubleJump and not self.HasDoubleJumped then
            self.HasDoubleJumped = true
            humanoid.JumpPower = power * DOUBLE_JUMP_POWER_MULTIPLIER
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    humanoid.StateChanged:Connect(function(old, state)
        if state == Enum.HumanoidStateType.Landed then
            self.CanDoubleJump = false
            self.HasDoubleJumped = false
            humanoid.JumpPower = power
        elseif state == Enum.HumanoidStateType.Freefall then
            task.wait(TIME_BETWEEN_JUMPS)
            self.CanDoubleJump = true
        end
    end)

    UserInputService.JumpRequest:Connect(onJumpRequest)
end

function PlayerController:KnitInit()
    Knit.Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:WaitForChild("Animator")

        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

        self:InitAnimations(animator)
        self:SetupInput()
        self:SetupHealth(character, humanoid)
        self:SetupStamina(humanoid)
        self:SetupDoubleJump(humanoid)
    end)
end

function PlayerController:KnitStart()
end

return PlayerController
