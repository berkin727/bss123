--[[
    BERKIN HUB - BEE SWARM SIMULATOR V1
    Arayüz: Orion Library
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "berkinbss | Bee Swarm Simulator", HidePremium = false, SaveConfig = true, ConfigFolder = "berkinbss"})

-- OYUN SERVİSLERİ VE DEĞİŞKENLER
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- GLOBAL AYARLAR (Menüden kontrol edilen değişkenler)
_G.Settings = {
    AutoFarm = false,
    AutoDig = false,
    ConvertBalloon = false,
    SelectField = "Pine Tree Forest", -- Varsayılan tarla
    ConvertPercent = 95, -- Çanta %95 dolunca dön
    WalkSpeed = 60
}

-- TARLA LİSTESİNİ OTOMATİK ÇEKME
local FieldTable = {}
for _, v in pairs(Workspace.FlowerZones:GetChildren()) do
    if v:IsA("BasePart") then
        table.insert(FieldTable, v.Name)
    end
end
table.sort(FieldTable) -- İsim sırasına diz

-- ==========================================================================
-- FONKSİYONLAR (LOGIC KISMI)
-- ==========================================================================

local MyHivePosition = nil

-- Kovan Bulucu
local function FindMyHive()
    for _, hive in pairs(Workspace.Honeycombs:GetChildren()) do
        if hive:FindFirstChild("Owner") and hive.Owner.Value == LocalPlayer then
            MyHivePosition = hive.SpawnPos.Value
            return true
        end
    end
    return false
end

-- Hareket (Tween) Fonksiyonu
local function TweenTo(position)
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then return end
    
    local RootPart = Character.HumanoidRootPart
    local Distance = (RootPart.Position - position).Magnitude
    local Time = Distance / _G.Settings.WalkSpeed
    
    local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Linear)
    local Tween = TweenService:Create(RootPart, TweenInfo, {CFrame = CFrame.new(position + Vector3.new(0, 5, 0))})
    
    -- Noclip (Duvar içinden geçme)
    local Noclip = game:GetService("RunService").Stepped:Connect(function()
        if Character then
            for _, part in pairs(Character:GetChildren()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)
    
    Tween:Play()
    Tween.Completed:Wait()
    if Noclip then Noclip:Disconnect() end
end

-- Ana Farm Mantığı
local function FarmLoop()
    spawn(function()
        while task.wait(0.1) do
            if _G.Settings.AutoFarm then
                pcall(function()
                    local CoreStats = LocalPlayer.CoreStats
                    local Pollen = CoreStats.Pollen.Value
                    local Capacity = CoreStats.Capacity.Value
                    local Percentage = (Pollen / Capacity) * 100

                    -- 1. DURUM: ÇANTA DOLDUYSA DÖNÜŞTÜR
                    if Percentage >= _G.Settings.ConvertPercent then
                        OrionLib:MakeNotification({Name = "Durum", Content = "Çanta Doldu! Kovana dönülüyor...", Image = "rbxassetid://4483345998", Time = 3})
                        
                        if not MyHivePosition then FindMyHive() end
                        TweenTo(MyHivePosition)
                        task.wait(0.5)
                        
                        -- Bal Yapma Sinyali
                        ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                        
                        -- Bekleme Süresi (Balon varsa daha uzun bekle)
                        if _G.Settings.ConvertBalloon then
                            task.wait(30) -- Balon için uzun süre
                        else
                            task.wait(15) -- Normal bal
                        end
                        
                    -- 2. DURUM: ÇANTA BOŞSA TARLAYA GİT
                    else
                        local TargetField = Workspace.FlowerZones:FindFirstChild(_G.Settings.SelectField)
                        if TargetField then
                            local Root = LocalPlayer.Character.HumanoidRootPart
                            -- Tarladan uzaksak git
                            if (Root.Position - TargetField.Position).Magnitude > 30 then
                                TweenTo(TargetField.Position)
                            else
                                -- Tarladaysak ve AutoDig açıksa kaz
                                if _G.Settings.AutoDig then
                                    local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                    if Tool then Tool:Activate() end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end

-- ==========================================================================
-- MENÜ TASARIMI (UI)
-- ==========================================================================

-- TABLAR
local HomeTab = Window:MakeTab({Name = "Home", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local FarmTab = Window:MakeTab({Name = "Farming", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local TeleportTab = Window:MakeTab({Name = "Teleport", Icon = "rbxassetid://4483345998", PremiumOnly = false})
local SettingsTab = Window:MakeTab({Name = "Settings", Icon = "rbxassetid://4483345998", PremiumOnly = false})

-- HOME TAB
HomeTab:AddParagraph("Hoşgeldin!", "berkinbss Scriptine hoşgeldin.\nDurum: Aktif")
HomeTab:AddButton({
    Name = "Anti-AFK Başlat",
    Callback = function()
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        OrionLib:MakeNotification({Name = "Anti-AFK", Content = "Aktif edildi!", Time = 3})
    end    
})

-- FARM TAB (Ana Kısım)
FarmTab:AddSection({Name = "Farm Ayarları"})

FarmTab:AddDropdown({
    Name = "Tarla Seç (Select Field)",
    Default = "Pine Tree Forest",
    Options = FieldTable,
    Callback = function(Value)
        _G.Settings.SelectField = Value
    end    
})

FarmTab:AddToggle({
    Name = "Auto Farm (Otomatik Başlat)",
    Default = false,
    Callback = function(Value)
        _G.Settings.AutoFarm = Value
        if Value then FindMyHive() end -- Açınca kovanı bir kere bulsun
    end    
})

FarmTab:AddToggle({
    Name = "Auto Dig (Otomatik Kaz)",
    Default = false,
    Callback = function(Value)
        _G.Settings.AutoDig = Value
    end    
})

FarmTab:AddSection({Name = "Dönüştürme Ayarları"})

FarmTab:AddToggle({
    Name = "Convert Balloon (Balonları Bekle)",
    Default = false,
    Callback = function(Value)
        _G.Settings.ConvertBalloon = Value
    end    
})

-- TELEPORT TAB (Ekstra)
TeleportTab:AddButton({
    Name = "Kovana Işınlan",
    Callback = function()
        if not MyHivePosition then FindMyHive() end
        TweenTo(MyHivePosition)
    end    
})

-- SETTINGS TAB
SettingsTab:AddSlider({
    Name = "Yürüme Hızı (Tween Speed)",
    Min = 20,
    Max = 100,
    Default = 60,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        _G.Settings.WalkSpeed = Value
    end    
})

-- Script Başlarken Loop'u Çalıştır
OrionLib:Init()
FarmLoop() -- Arka planda döngüyü başlatır
