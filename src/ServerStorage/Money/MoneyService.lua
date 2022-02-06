local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local MoneyConfig = require(script.Parent.MoneyConfig)

local MoneyService = Knit.CreateService {
    Name = "MoneyService",
    Client = {
       MoneyChanged = Knit.CreateSignal()
    },
    _MoneyPerPlayer = {},
}

function MoneyService.Client:GetMoney(player: Player)
   return self.Server:GetMoney(player)
end

function MoneyService:GetMoney(player: Player): number
   local money = self._MoneyPerPlayer[player] or MoneyConfig.StartingMoney
   return money
end

function MoneyService:AddMoney(player: Player, amount: number)
   local currentMoney = self:GetMoney(player)

   if amount > 0 then
      local newMoney = currentMoney + amount
      self._MoneyPerPlayer[player] = newMoney

      self.Client.MoneyChanged:Fire(player, newMoney)
   end
end

function MoneyService:KnitStart()
   print("MoneyService started")

   while true do
      task.wait(1)

      for _,player in ipairs(Players:GetPlayers()) do
         self:AddMoney(player, math.random(1, 10))
      end
   end

end

function MoneyService:KnitInit()
   print("MoneyService init")

   Players.PlayerRemoving:Connect(function(player)
      self._MoneyPerPlayer[player] = nil
   end)
end

return MoneyService