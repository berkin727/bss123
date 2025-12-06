--[[
    BERKIN HUB - BEE SWARM SIMULATOR V4 (FIXED UI)
    Özellikler: Her şey ANA SAYFADA. Sekme sorunu yok.
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Berkin Hub | BSS V4 (Full)", HidePremium = false, SaveConfig = true, ConfigFolder = "BerkinHubV4"})

-- OYUN SERVİSLERİ
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- AYARLAR
_G.Settings = {
    AutoFarm = false,
    AutoDig = false,
    ConvertBalloon = false,
    SelectField = "Pine Tree Forest",
    WalkSpeed = 16,
    JumpPower = 50,
    SpeedActive = false,
    JumpActive = false
}

-- TARLALARI ÇEKME FONKSİYONU
local function GetFields()
    local FieldTable = {}
    for _, v in pairs(Workspace.FlowerZones:GetChildren()) do
        if v:IsA("BasePart") then table.insert(FieldTable, v.Name) end
    end
    table.sort(FieldTable)
    return FieldTable
end

local FieldTable = GetFields()

local MaskTable = {
    "Honey Mask", "Diamond Mask", "Gummy Mask", "Demon Mask", 
    "Bubble Mask", "Fire Mask", "Beekeeper's Mask"
}

-- FONKSİYONLAR
local MyHivePosition = nil

local function FindMyHive()
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            MyHivePosition = hive.SpawnPos.Value
            return true
        end
    end
end

local function TweenTo(position)
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    local Root = Character.HumanoidRootPart
    local Dist = (Root.Position - position).Magnitude
    local Time = Dist / (_G.Settings.WalkSpeed > 60 and 60 or _G.Settings.WalkSpeed)
    
    local TI = TweenInfo.new(Time, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(Root, TI, {CFrame = CFrame.new(position + Vector3.new(0, 5, 0))})
    
    local NC = RunService.Stepped:Connect(function()
        if Character then
            for _, p in pairs(Character:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
    Tween:Play()
    Tween.Completed:Wait()
    if NC then NC:Disconnect() end
end

-- ==================================================
-- MENÜ TASARIMI (HEPSİ TEK SAYFADA)
-- ==================================================

-- MAIN TAB (Her şey burada)
local MainTab = Window:MakeTab({Name = "Ana Menü (Main)", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- BÖLÜM 1: FARMING
MainTab:AddSection({Name = "Farm Ayarları"})

MainTab:AddDropdown({
    Name = "Tarlayı Seç (Select Field)",
    Default = "Pine Tree Forest",
    Options = FieldTable,
    Callback = function(Value)
        _G.Settings.SelectField = Value
    end    
})

MainTab:AddButton({
    Name = "Tarlaya Işınlan (Git)",
    Callback = function()
        local F = Workspace.FlowerZones:FindFirstChild(_G.Settings.SelectField)
        if F then TweenTo(F.Position) end
    end    
})

MainTab:AddToggle({
    Name = "Auto Farm 
