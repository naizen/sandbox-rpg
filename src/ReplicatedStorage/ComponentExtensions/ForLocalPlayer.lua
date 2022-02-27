local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ForLocalPlayer = {}

-- Enhancement: Add trove and player trove OnConstructing to reduce boilerplate
function ForLocalPlayer.Started(component)
    local function OnPlayerChanged()
        local playerId = component.Instance:GetAttribute("PlayerId")

        if playerId == Knit.Player.UserId then
            component:SetupForLocalPlayer()
        else
            component:CleanupForLocalPlayer()
        end
    end

    component.trove:Add(component.Instance:GetAttributeChangedSignal("PlayerId"):Connect(OnPlayerChanged))
end

return ForLocalPlayer
