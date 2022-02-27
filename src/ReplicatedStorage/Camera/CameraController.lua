local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Input = require(ReplicatedStorage.Packages.Input)
local Mouse = Input.Mouse
local Keyboard = Input.Keyboard

local MIN_ZOOM = 0
local MAX_ZOOM = 20

local CameraController = Knit.CreateController {
    Name = "CameraController",
    locked = true,
    strafeMode = false,
    renderName = "CustomCam",
    priority = Enum.RenderPriority.Camera.Value - 10,
    offset = Vector3.new(2, 2, MIN_ZOOM),
    currentZoom = MIN_ZOOM + 10,
    scrollConn = nil,
    mouse = nil,
    keyboard = nil,
    sens = 3.5,
    zoomSens = 2.5,
    horizontalAngle = 0,
    verticalAngle = 0,
    verticalAngleLimits = NumberRange.new(-45, 45),
    lerpSpeed = 0.5
}

function CameraController:Lock(rootPart, character)
    self.locked = true

    local camera = workspace.CurrentCamera

    camera.CameraType = Enum.CameraType.Scriptable

    self.scrollConn = self.mouse.Scrolled:Connect(function(scrollAmount)
        self:Zoom(scrollAmount)
    end)

    RunService:BindToRenderStep(self.renderName, self.priority, function()
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

        local mouseDelta = UserInputService:GetMouseDelta() * self.sens

        self.horizontalAngle = self.horizontalAngle - mouseDelta.X / camera.ViewportSize.X
        self.verticalAngle = self.verticalAngle - mouseDelta.Y / camera.ViewportSize.Y
        self.verticalAngle = math.rad(math.clamp(math.deg(self.verticalAngle), self.verticalAngleLimits.Min,
            self.verticalAngleLimits.Max))

        local offset = Vector3.new(self.offset.X, self.offset.Y, self.currentZoom)

        local newCameraCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, self.horizontalAngle, 0) *
                                    CFrame.Angles(self.verticalAngle, 0, 0) * CFrame.new(offset)

        newCameraCFrame = camera.CFrame:Lerp(newCameraCFrame, self.lerpSpeed)

        -- Handle obstructions
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local raycastResult = workspace:Raycast(rootPart.Position, newCameraCFrame.Position - rootPart.Position,
            raycastParams)

        if (raycastResult ~= nil) then
            local obstructionDisplacement = (raycastResult.Position - rootPart.Position)
            local obstructionPosition = rootPart.Position +
                                            (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = newCameraCFrame:GetComponents()
            newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01,
                r02, r10, r11, r12, r20, r21, r22)
        end

        if self.strafeMode then
            local newHumanoidRootPartCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, self.horizontalAngle, 0)
            rootPart.CFrame = rootPart.CFrame:Lerp(newHumanoidRootPartCFrame, self.lerpSpeed / 2)
        end

        camera.CFrame = newCameraCFrame
    end)
end

function CameraController:RotateTowardsCamera(rootPart)
    local camera = workspace.CurrentCamera

    local camLV = camera.CFrame.LookVector
    local camRotation = math.atan2(-camLV.X, -camLV.Z)

    rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, camRotation, 0)
end

function CameraController:Unlock()
    self.locked = false

    UserInputService.MouseBehavior = Enum.MouseBehavior.Default

    RunService:UnbindFromRenderStep(self.renderName)
    self.scrollConn:Disconnect()
end

function CameraController:Zoom(scrollAmount)
    local zoomAmount = self.currentZoom - (scrollAmount * self.zoomSens)

    if zoomAmount <= MIN_ZOOM then
        zoomAmount = MIN_ZOOM
    elseif zoomAmount >= MAX_ZOOM then
        zoomAmount = MAX_ZOOM
    end

    self.currentZoom = zoomAmount
end

function CameraController:KnitInit()
end

function CameraController:KnitStart()
    self.mouse = Mouse.new()
    self.keyboard = Keyboard.new()

    Knit.Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")

        self:Lock(rootPart, character)

        self.mouse.LeftDown:Connect(function()
            self:RotateTowardsCamera(rootPart)
            humanoid.AutoRotate = false
            self.strafeMode = true
        end)

        self.mouse.LeftUp:Connect(function()
            humanoid.AutoRotate = true
            self.strafeMode = false
        end)

        self.keyboard.KeyDown:Connect(function(keycode)
            if keycode == Enum.KeyCode.M then
                if self.locked then
                    self:Unlock()
                else
                    self:Lock(rootPart, character)
                end
            end
        end)
    end)
end

return CameraController
