local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local MoneyController = Knit.CreateController {
   Name = "MoneyController"
}

function MoneyController:KnitStart()
    -- Only call Knit.GetService once
    local MoneyService = Knit.GetService("MoneyService")

    MoneyService.MoneyChanged:Connect(function(money)
        print("money: ", money)
    end)
end

function MoneyController:KnitInit()
   print("MoneyController init")
end

return MoneyController