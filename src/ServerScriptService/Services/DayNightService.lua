local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

-- time changer
local TIME_SHIFT = 0 -- 0.25 -- how many minutes you shift every "tick"
local WAIT_TIME = 1 / 15 -- length of the tick

-- brightness
local AMPLITUDE_B = 1
local OFFSET_B = 2

-- outdoor ambience
local AMPLITUDE_O = 20
local OFFSET_O = 100

-- shadow softness
local AMPLITUDE_S = 0.2
local OFFSET_S = 0.8

local R_COLOR_LIST = {000, 000, 000, 000, 000, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
                      000, 000, 000, 000, 000}
local G_COLOR_LIST = {165, 165, 165, 165, 165, 255, 215, 230, 255, 255, 255, 255, 255, 255, 255, 245, 230, 215, 255,
                      165, 165, 165, 165, 165}
local B_COLOR_LIST = {255, 255, 255, 255, 255, 255, 110, 135, 255, 255, 255, 255, 255, 255, 255, 215, 135, 110, 255,
                      255, 255, 255, 255, 255}

local DayNightService = Knit.CreateService {
    Name = "DayNightService",
    Client = {},
    mam = nil,
    ambience = nil,
    colorShift = nil,
    r = nil,
    g = nil,
    b = nil
}

function DayNightService:KnitInit()
end

function DayNightService:KnitStart()
    while true do
        -- time changer
        self.mam = game.Lighting:GetMinutesAfterMidnight() + TIME_SHIFT
        game.Lighting:SetMinutesAfterMidnight(self.mam)
        self.mam = self.mam / 60

        -- TODO: Determine when it is nighttime to do nighttime things like spawn ghosts or zombies. Could also increase nighttime brightness if need be.

        -- brightness
        game.Lighting.Brightness = AMPLITUDE_B * math.cos(self.mam * (math.pi / 12) + math.pi) + OFFSET_B

        -- outdoor ambient
        self.ambience = AMPLITUDE_O * math.cos(self.mam * (math.pi / 12) + math.pi) + OFFSET_O
        game.Lighting.OutdoorAmbient = Color3.fromRGB(self.ambience, self.ambience, self.ambience)

        -- shadow softness
        game.Lighting.ShadowSoftness = AMPLITUDE_S * math.cos(self.mam * (math.pi / 6)) + OFFSET_S

        -- color shift top
        self.colorShift = math.clamp(math.ceil(self.mam), 1, 24)
        self.r = ((R_COLOR_LIST[self.colorShift % 24 + 1] - R_COLOR_LIST[self.colorShift]) *
                     (self.mam - self.colorShift + 1)) + R_COLOR_LIST[self.colorShift]
        self.g = ((G_COLOR_LIST[self.colorShift % 24 + 1] - G_COLOR_LIST[self.colorShift]) *
                     (self.mam - self.colorShift + 1)) + G_COLOR_LIST[self.colorShift]
        self.b = ((B_COLOR_LIST[self.colorShift % 24 + 1] - B_COLOR_LIST[self.colorShift]) *
                     (self.mam - self.colorShift + 1)) + B_COLOR_LIST[self.colorShift]

        game.Lighting.ColorShift_Top = Color3.fromRGB(self.r, self.g, self.b)

        -- tick
        task.wait(WAIT_TIME)
    end
end

return DayNightService
