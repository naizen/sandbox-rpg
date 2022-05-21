local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)
local Input = require(ReplicatedStorage.Packages.Input)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Keyboard = Input.Keyboard

local TIME_BETWEEN_JUMPS = 0.1
local DOUBLE_JUMP_POWER_MULTIPLIER = 1.2

-- PlayerController handles the local player's state, movement inputs
-- and holds all possible player animations for movement, combat, etc.
local PlayerController = Knit.CreateController {
    Name = "PlayerController",
    Sprinting = false,
    CanDoubleJump = false,
    HasDoubleJumped = false,
    StaminaChanged = Signal.new(),
    XpChanged = Signal.new(),
    Humanoid = nil,
    EquippedItem = nil,
    CurrentMovementAnim = nil,
    CurrentSpeed = 0
}

function PlayerController:KnitInit()
    self.MaxStamina = 500
    self.Stamina = self.MaxStamina

    Knit.Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local animator = humanoid:WaitForChild("Animator")

        -- Destroy the default health regen script
        character:WaitForChild("Health"):Destroy()

        humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)

        -- Maps animation ids to an animation instance
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

        local keyboard = Keyboard.new()

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

        local function FireStaminaChanged()
            local staminaPercent = (self.Stamina / self.MaxStamina)
            self.StaminaChanged:Fire(staminaPercent)
        end

        RunService.RenderStepped:Connect(function()
            if self.Stamina > 0 and self.Sprinting and humanoid.MoveDirection.Magnitude > 0 then
                humanoid.WalkSpeed = PlayerConfig.SprintSpeed
                self.Stamina = self.Stamina - PlayerConfig.StaminaDecrease
                FireStaminaChanged()
            else
                humanoid.WalkSpeed = PlayerConfig.RunSpeed
            end

            if self.Stamina < self.MaxStamina and not self.Sprinting then
                self.Stamina = self.Stamina + (PlayerConfig.StaminaDecrease * 2)
                FireStaminaChanged()
            end
        end)

        self:EnableDoubleJump(humanoid)

        humanoid.Running:Connect(function(speed)
            self.CurrentSpeed = speed
            self:UpdateMovementAnim()
        end)

        humanoid.Jumping:Connect(function()
            self:SetCurrentMovementAnim(nil)
        end)

        self.Humanoid = humanoid
    end)
end

function PlayerController:EnableDoubleJump(humanoid)
    local oldPower = humanoid.JumpPower

    local function onJumpRequest()
        if humanoid:GetState() == Enum.HumanoidStateType.Dead then
            return
        end

        if self.CanDoubleJump and not self.HasDoubleJumped then
            self.HasDoubleJumped = true
            humanoid.JumpPower = oldPower * DOUBLE_JUMP_POWER_MULTIPLIER
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

            -- Special double jump animation
            -- local animTrack = self.LoadedAnimations[PlayerConfig.Animations.FrontFlip]
            -- animTrack:Play()
            -- animTrack:AdjustSpeed(1.2)
        end
    end

    humanoid.StateChanged:Connect(function(old, state)
        if state == Enum.HumanoidStateType.Landed then
            self.CanDoubleJump = false
            self.HasDoubleJumped = false
            humanoid.JumpPower = oldPower
        elseif state == Enum.HumanoidStateType.Freefall then
            task.wait(TIME_BETWEEN_JUMPS)
            self.CanDoubleJump = true
        end
    end)

    UserInputService.JumpRequest:Connect(onJumpRequest)
end

function PlayerController:Equip(item, equipped, playEquipAnim)
    local equipAnimId = PlayerConfig.Animations[item.Name].Equip
    local equipAnim = self.LoadedAnimations[equipAnimId]

    if playEquipAnim then
        equipAnim:Play()
    end

    if equipped then
        self.EquippedItem = item
    else
        self.EquippedItem = nil
    end

    self:UpdateMovementAnim()
end

function PlayerController:SetCurrentMovementAnim(anim)
    -- Stop previous movement anim
    if self.CurrentMovementAnim and self.CurrentMovementAnim.IsPlaying then
        self.CurrentMovementAnim:Stop()
    end

    self.CurrentMovementAnim = anim

    if self.CurrentMovementAnim ~= nil then
        self.CurrentMovementAnim:Play()
    end
end

function PlayerController:UpdateMovementAnim()
    if self.EquippedItem == nil then
        self:SetCurrentMovementAnim(nil)
        return
    end

    local idleAnimId = PlayerConfig.Animations[self.EquippedItem.Name].Idle
    local idleAnim = self.LoadedAnimations[idleAnimId]

    local runAnimId = PlayerConfig.Animations[self.EquippedItem.Name].Run
    local runAnim = self.LoadedAnimations[runAnimId]

    local movementAnim = idleAnim

    if self.CurrentSpeed > 0.1 then
        movementAnim = runAnim
    end

    if movementAnim ~= self.CurrentMovementAnim then
        self:SetCurrentMovementAnim(movementAnim)
    end
end

function PlayerController:KnitStart()
end

return PlayerController
