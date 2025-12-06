--[[
    BERKIN HUB - BEE SWARM SIMULATOR V3
    Özellikler: Auto Farm, Remote Equip, Speed/Jump, Full Field List
]]

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Berkin Hub | BSS V3", HidePremium = false, SaveConfig = true, ConfigFolder = "BerkinHub"})

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
    WalkSpeed = 16, -- Oyunun normal hızı
    JumpPower = 50, -- Oyunun normal zıplaması
    SpeedActive = false,
    JumpActive = false
}

-- TARLALARI OTOMATİK ÇEK VE SIRALA (A-Z)
local FieldTable = {}
for _, v in pairs(Workspace.FlowerZones:GetChildren()) do
    if v:IsA("BasePart") then 
        table.insert(FieldTable, v.Name) 
    end
end
table.sort(FieldTable) -- A'dan Z'ye sıralama işlemi

-- MASKELER LİSTESİ
local MaskTable = {
    "Honey Mask", "Diamond Mask", "Gummy Mask", "Demon Mask", 
    "Bubble Mask", "Fire Mask", "Beekeeper's Mask"
}

-- ==================================================
-- FONKSİYONLAR
-- ==================================================
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
    local Time = Dist / (_G.Settings.WalkSpeed > 60 and 60 or _G.Settings.WalkSpeed) -- Çok hızlıysa tween bozulmasın diye limit
    
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
-- MENÜ TASARIMI
-- ==================================================

-- 1. HOME TAB
local HomeTab = Window:MakeTab({Name = "Ana Sayfa", Icon = "rbxassetid://4483345998", PremiumOnly = false})
HomeTab:AddSection({Name = "Genel"})
HomeTab:AddLabel("Berkin Hub V3 - Hoşgeldin!")
HomeTab:AddButton({
    Name = "Anti-AFK Aktif Et",
    Callback = function()
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        OrionLib:MakeNotification({Name = "Sistem", Content = "Anti-AFK Açıldı.", Time = 3})
    end    
})

-- 2. FARM TAB
local FarmTab = Window:MakeTab({Name = "Farming", Icon = "rbxassetid://4483345998", PremiumOnly = false})

FarmTab:AddSection({Name = "Hedef Bölge"})
-- BURADA BÜTÜN FİELDLER A-Z SIRALI GÖZÜKÜR
FarmTab:AddDropdown({
    Name = "Tarlayı Seç (Select Field)",
    Default = "Pine Tree Forest",
    Options = FieldTable,
    Callback = function(Value)
        _G.Settings.SelectField = Value
    end    
})

FarmTab:AddButton({
    Name = "Seçilen Tarlaya Işınlan",
    Callback = function()
        local F = Workspace.FlowerZones:FindFirstChild(_G.Settings.SelectField)
        if F then TweenTo(F.Position) end
    end    
})

FarmTab:AddSection({Name = "Otomasyon"})
FarmTab:AddToggle({
    Name = "Auto Farm Başlat",
    Default = false,
    Callback = function(Value)
        _G.Settings.AutoFarm = Value
        if Value then FindMyHive() end
    end    
})

FarmTab:AddToggle({
    Name = "Auto Dig (Otomatik Kaz)",
    Default = false,
    Callback = function(Value)
        _G.Settings.AutoDig = Value
    end    
})

FarmTab:AddToggle({
    Name = "Convert Balloon (Balon Bekle)",
    Default = false,
    Callback = function(Value)
        _G.Settings.ConvertBalloon = Value
    end    
})

-- 3. ITEMS TAB (YENİ - MASKE TAKMA)
local ItemsTab = Window:MakeTab({Name = "Eşyalar (Items)", Icon = "rbxassetid://4483345998", PremiumOnly = false})

ItemsTab:AddSection({Name = "Uzaktan Maske Tak"})
ItemsTab:AddDropdown({
    Name = "Maske Seç",
    Default = "Honey Mask",
    Options = MaskTable,
    Callback = function(Value)
        _G.SelectedMask = Value
    end    
})

ItemsTab:AddButton({
    Name = "Seçili Maskeyi Tak (Equip)",
    Callback = function()
        if _G.SelectedMask then
            -- BSS Equip Remote Event
            local Event = ReplicatedStorage.Events:FindFirstChild("ItemPackageEvent")
            if Event then
                -- Oyunda maskeyi takma komutu
                Event:InvokeServer("Equip", {
                    ["Type"] = _G.SelectedMask, 
                    ["Category"] = "Accessory"
                })
                OrionLib:MakeNotification({Name = "İşlem", Content = _G.SelectedMask .. " takıldı!", Time = 3})
            else
                OrionLib:MakeNotification({Name = "Hata", Content = "Event bulunamadı!", Time = 3})
            end
        end
    end    
})

-- 4. PLAYER TAB (YENİ - HIZ & ZIPLAMA)
local PlayerTab = Window:MakeTab({Name = "Karakter", Icon = "rbxassetid://4483345998", PremiumOnly = false})

PlayerTab:AddSection({Name = "Hareket Ayarları"})

PlayerTab:AddToggle({
    Name = "Hız Hilesini Aç",
    Default = false,
    Callback = function(Value)
        _G.Settings.SpeedActive = Value
    end    
})

PlayerTab:AddSlider({
    Name = "Koşma Hızı (WalkSpeed)",
    Min = 16,
    Max = 150,
    Default = 16,
    Increment = 1,
    Callback = function(Value)
        _G.Settings.WalkSpeed = Value
    end    
})

PlayerTab:AddToggle({
    Name = "Zıplama Hilesini Aç",
    Default = false,
    Callback = function(Value)
        _G.Settings.JumpActive = Value
    end    
})

PlayerTab:AddSlider({
    Name = "Zıplama Gücü (JumpPower)",
    Min = 50,
    Max = 300,
    Default = 50,
    Increment = 1,
    Callback = function(Value)
        _G.Settings.JumpPower = Value
    end    
})


-- ==================================================
-- LOOPLAR (Arka Planda Çalışanlar)
-- ==================================================

-- 1. Farm Döngüsü
spawn(function()
    while task.wait(0.1) do
        if _G.Settings.AutoFarm then
            pcall(function()
                local Stats = LocalPlayer.CoreStats
                local Pollen = Stats.Pollen.Value
                local Capacity = Stats.Capacity.Value
                
                -- Doluysa Kovana
                if Pollen >= (Capacity * 0.95) then
                    if not MyHivePosition then FindMyHive() end
                    TweenTo(MyHivePosition)
                    ReplicatedStorage.Events.PlayerHiveCommand:FireServer("ToggleHoneyMaking")
                    task.wait(_G.Settings.ConvertBalloon and 30 or 15)
                
                -- Boşsa Tarlaya
                else
                    local Field = Workspace.FlowerZones:FindFirstChild(_G.Settings.SelectField)
                    if Field then
                        local Root = LocalPlayer.Character.HumanoidRootPart
                        if (Root.Position - Field.Position).Magnitude > 30 then
                            TweenTo(Field.Position)
                        else
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

-- 2. Hız ve Zıplama Döngüsü (Oyun geri almasın diye sürekli günceller)
spawn(function()
    while task.wait(0.5) do
        local Char = LocalPlayer.Character
        if Char and Char:FindFirstChild("Humanoid") then
            if _G.Settings.SpeedActive then
                Char.Humanoid.WalkSpeed = _G.Settings.WalkSpeed
            end
            if _G.Settings.JumpActive then
                Char.Humanoid.JumpPower = _G.Settings.JumpPower
            end
        end
    end
end)

OrionLib:Init()
