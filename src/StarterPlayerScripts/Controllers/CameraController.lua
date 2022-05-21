local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)
local Input = require(ReplicatedStorage.Packages.Input)
local Mouse = Input.Mouse
local Keyboard = Input.Keyboard

local MIN_ZOOM = 0
local MAX_ZOOM = 20

local CameraController = Knit.CreateController {
    Name = "CameraController",
    locked = false,
    strafeMode = false,
    renderName = "CustomCam",
    freezeMovementName = "FreezeMovement",
    priority = Enum.RenderPriority.Camera.Value + 1,
    offset = Vector3.new(2, 2, MIN_ZOOM),
    currentZoom = MIN_ZOOM + 10,
    scrollConn = nil,
    mouse = nil,
    keyboard = nil,
    mouseSens = 0.3,
    zoomSens = 2.5,
    horizontalAngle = 0,
    verticalAngle = 0,
    verticalAngleLimits = NumberRange.new(-75, 75),
    lerpSpeed = 0.5,
    inputTrove = Trove.new(),
    menuOpen = false
}

function CameraController:Lock(rootPart, character)
    if self.locked then
        return
    end

    self.locked = true

    local camera = workspace.CurrentCamera

    camera.CameraType = Enum.CameraType.Scriptable

    self.scrollConn = self.mouse.Scrolled:Connect(function(scrollAmount)
        self:Zoom(scrollAmount)
    end)

    RunService:BindToRenderStep(self.renderName, self.priority, function()
        if not self.menuOpen then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end

        local mouseDelta = UserInputService:GetMouseDelta() * self.mouseSens

        local offset = Vector3.new(self.offset.X, self.offset.Y, self.currentZoom)

        self.horizontalAngle = self.horizontalAngle - mouseDelta.X
        self.verticalAngle = math.clamp(self.verticalAngle - mouseDelta.Y * 0.4, -75, 75)

        local startCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(self.horizontalAngle), 0) *
                                CFrame.Angles(math.rad(self.verticalAngle), 0, 0)

        local cameraCFrame = startCFrame:ToWorldSpace(CFrame.new(offset.X, offset.Y, offset.Z))
        local cameraFocus = startCFrame:ToWorldSpace(CFrame.new(offset.X, offset.Y, -10000))

        local newCameraCFrame = CFrame.new(cameraCFrame.Position, cameraFocus.Position)

        newCameraCFrame = camera.CFrame:Lerp(newCameraCFrame, self.lerpSpeed)

        -- Handle obstructions
        local head = character:FindFirstChild('Head')
        local raycastStartPos = head.Position + Vector3.new(0, head.Size.Y, 0)

        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        local raycastResult = workspace:Raycast(raycastStartPos, newCameraCFrame.Position - raycastStartPos,
            raycastParams)

        if (raycastResult ~= nil) then
            local obstructionDisplacement = (raycastResult.Position - raycastStartPos)
            local obstructionPosition = raycastStartPos +
                                            (obstructionDisplacement.Unit * (obstructionDisplacement.Magnitude - 0.1))
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = newCameraCFrame:GetComponents()
            newCameraCFrame = CFrame.new(obstructionPosition.x, obstructionPosition.y, obstructionPosition.z, r00, r01,
                r02, r10, r11, r12, r20, r21, r22)
        end

        if self.strafeMode then
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, math.rad(-mouseDelta.X), 0)
        end

        camera.CFrame = newCameraCFrame
    end)
end

function CameraController:RotateTowardsCamera(rootPart)
    if self.menuOpen then
        return
    end

    local camera = workspace.CurrentCamera

    local camLV = camera.CFrame.LookVector
    local camRotation = math.atan2(-camLV.X, -camLV.Z)

    rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, camRotation, 0)
end

function CameraController:Unlock()
    if not self.locked then
        return
    end

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

function CameraController:SetupCustomCamera()
    local UIController = Knit.GetController("UIController")

    Knit.Player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")

        self:Lock(rootPart, character)

        self.inputTrove:Add(self.mouse.LeftDown:Connect(function()
            self:RotateTowardsCamera(rootPart)
            humanoid.AutoRotate = false
            self.strafeMode = true
        end))

        self.inputTrove:Add(self.mouse.LeftUp:Connect(function()
            humanoid.AutoRotate = true
            self.strafeMode = false
        end))

        local function freezeMovement()
            ContextActionService:BindAction(self.freezeMovementName, function()
                return Enum.ContextActionResult.Sink
            end, false, unpack(Enum.PlayerActions:GetEnumItems()))
        end

        self.inputTrove:Add(UIController.MenuToggled:Connect(function(menuOpen)
            self.menuOpen = menuOpen

            if menuOpen then
                freezeMovement()
                self:Unlock()
            else
                ContextActionService:UnbindAction(self.freezeMovementName)
                self:Lock(rootPart, character)
            end
        end))
    end)

    Knit.Player.CharacterRemoving:Connect(function()
        self.inputTrove:Clean()

        self:Unlock()
    end)
end

function CameraController:KnitInit()
end

function CameraController:KnitStart()
    self.mouse = Mouse.new()
    self.keyboard = Keyboard.new()

    self:SetupCustomCamera()
end

return CameraController
