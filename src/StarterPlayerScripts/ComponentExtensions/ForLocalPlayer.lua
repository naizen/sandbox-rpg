local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ForLocalPlayer = {}

function ForLocalPlayer.Started(component)
    local function OnPlayerChanged()
        -- print("ForLocalPlayer: player id changed: ", component.Tag)

        if not Knit.Player then
            return
        end

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
