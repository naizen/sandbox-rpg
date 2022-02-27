local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)
local ForLocalPlayer = require(ReplicatedStorage.Source.ComponentExtensions.ForLocalPlayer)

local ClientItem = Component.new({
    Tag = "Item",
    Extensions = {ForLocalPlayer}
})

function ClientItem:Construct()
    self.trove = Trove.new()
    self.playerTrove = Trove.new()
    self.trove:Add(self.playerTrove)
end

function ClientItem:SetupForLocalPlayer()
    local function OnUserInput(input, processed)
        if processed then
            return
        end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.E then
                self.Instance.Drop:FireServer()
            end
        end
    end

    self.playerTrove:Add(UserInputService.InputBegan:Connect(OnUserInput))
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
