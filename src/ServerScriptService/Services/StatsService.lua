local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerConfig = require(StarterPlayer.StarterPlayerScripts.Source.PlayerConfig)

local StatsDataStore = DataStoreService:GetDataStore("Stats")

local INIT_PLAYER_STATS = {
    overall = {
        xp = 0,
        level = 1
    },
    strength = {
        xp = 0,
        level = 1
    },
    range = {
        xp = 0,
        level = 1
    }
}

local StatsService = Knit.CreateService {
    Name = "StatsService",
    Client = {
        StatsChanged = Knit.CreateSignal()
    },
    Stats = {}
}

function StatsService.Client:GetStats(player)
    return self.Server:GetStats(player)
end

function StatsService:GetStats(player)
    local stats = self.Stats[player.UserId]
    return stats or nil
end

function StatsService:KnitInit()
    local function LoadStats(player)
        local success, playerStats = pcall(function()
            return StatsDataStore:GetAsync(player.UserId)
        end)

        if success and playerStats then
            self.Stats[player.UserId] = playerStats
        else
            self.Stats[player.UserId] = INIT_PLAYER_STATS
        end

        -- self:PrintStats(player)
        self:LeaderboardSetup(player)
        -- self:ResetStats(player)
        self.Client.StatsChanged:Fire(player, self.Stats[player.UserId])
    end

    local function SaveStats(player)
        local success = pcall(function()
            StatsDataStore:setAsync(player.UserId, self.Stats[player.UserId])
        end)

        if success then
            print("Saved Stats")
        else
            print("Failed Saving Stats")
        end
    end

    Players.PlayerAdded:Connect(LoadStats)
    Players.PlayerRemoving:Connect(SaveStats)
end

function StatsService:UpdateStat(player, statType, statKey, updateAmount)
    local currentValue = self.Stats[player.UserId][statType][statKey]
    local updatedValue = currentValue + updateAmount

    self.Stats[player.UserId][statType][statKey] = updatedValue

    if statType == 'overall' and statKey == 'xp' then
        -- Level up based on experience
        local currentLevel = self.Stats[player.UserId][statType].level
        local reachedNextLevel = updatedValue >= currentLevel * PlayerConfig.XpPerLevelFactor

        if reachedNextLevel then
            self:LevelUp(player)
        end
    end

    local stats = self.Stats[player.UserId]

    self.Client.StatsChanged:Fire(player, stats, statType)
end

function StatsService:ResetStats(player)
    self.Stats[player.UserId] = INIT_PLAYER_STATS
end

function StatsService:PrintStats(player)
    for type, stat in pairs(self.Stats[player.UserId]) do
        print(type)
        for k, v in pairs(stat) do
            print(k .. ': ' .. v)
        end
    end
end

function StatsService:LevelUp(player)
    local nextLevel = self.Stats[player.UserId].overall.level + 1
    self.Stats[player.UserId].overall.level = nextLevel
    self:UpdateLeaderstats(player, 'Level', nextLevel)

    -- TODO: Play ding sound and visual fx on player
    print("GRATS YOU LEVELED UP! ", nextLevel)
end

function StatsService.Client:GetXpProgress(player, stats, statType)
    return self.Server:GetXpProgress(stats, statType)
end

function StatsService:GetXpProgress(stats, statType)
    local xp = stats[statType].xp
    local level = stats[statType].level
    local startXp = (level - 1) * PlayerConfig.XpPerLevelFactor

    local xpPercent = (xp - startXp) / PlayerConfig.XpPerLevelFactor

    return xpPercent
end

function StatsService:LeaderboardSetup(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = self.Stats[player.UserId].overall.level
    level.Parent = leaderstats
end

function StatsService:UpdateLeaderstats(player, statName, updateAmount)
    local leaderstats = player.leaderstats
    local stat = leaderstats and leaderstats:FindFirstChild(statName)
    if stat then
        stat.Value = updateAmount
    end
end

function StatsService:KnitStart()
end

return StatsService
