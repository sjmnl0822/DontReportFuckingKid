-- 신고하면 아구창 찢어버린다
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Drawing = Drawing or require("Drawing")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local targetPlayer = nil
local MAX_DISTANCE = 1500 -- 들키지 않도록 거리 제한 감소
local FOV_RADIUS_BODY = 70 -- 몸통 FOV 크기 증가
local FOV_RADIUS_HEAD = 35 -- 머리 FOV 크기 증가
local autoFireEnabled = false -- 단발 발사 기능 상태
local fovMultiplier = 1 -- FOV 배율

-- 몸통 조준 FOV 원
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 50
fovCircle.Radius = FOV_RADIUS_BODY
fovCircle.Filled = false
fovCircle.Visible = true

-- 머리 조준 FOV 원
local fovHeadCircle = Drawing.new("Circle")
fovHeadCircle.Color = Color3.fromRGB(255, 0, 0)
fovHeadCircle.Thickness = 1
fovHeadCircle.NumSides = 50
fovHeadCircle.Radius = FOV_RADIUS_HEAD
fovHeadCircle.Filled = false
fovHeadCircle.Visible = true

local function isLobbyVisible()
    return localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

local function getClosestPlayerInFOV()
    local closestHeadshot = nil
    local closestBodyshot = nil
    local shortestDistanceHead = math.huge
    local shortestDistanceBody = math.huge
    local centerPosition = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                for _, part in ipairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local screenPosition, onScreen = camera:WorldToViewportPoint(part.Position)
                        local cursorDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - centerPosition).Magnitude
                        
                        if onScreen then
                            if cursorDistance <= (FOV_RADIUS_HEAD * fovMultiplier) and cursorDistance < shortestDistanceHead then
                                closestHeadshot = player
                                shortestDistanceHead = cursorDistance
                            elseif cursorDistance <= (FOV_RADIUS_BODY * fovMultiplier) and cursorDistance < shortestDistanceBody then
                                closestBodyshot = player
                                shortestDistanceBody = cursorDistance
                            end
                        end
                    end
                end
            end
        end
    end
    return closestHeadshot or closestBodyshot, closestHeadshot and closestHeadshot.Character:FindFirstChild("Head") or closestBodyshot and closestBodyshot.Character:FindFirstChild("HumanoidRootPart")
end

local function lockCameraToTarget(targetPart)
    if targetPlayer and targetPlayer.Character and targetPart then
        camera.CFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        if not isLobbyVisible() and autoFireEnabled then
            mouse1click()
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then -- 우클릭 감지
        fovMultiplier = 1.5 -- 우클릭 시 FOV 증가 폭 증가
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then -- 우클릭 해제 시 원래 크기로
        fovMultiplier = 1
    end
end)

RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        local closestPlayer, targetPart = getClosestPlayerInFOV()

        if closestPlayer then
            targetPlayer = closestPlayer
            autoFireEnabled = true
            lockCameraToTarget(targetPart)
        else
            targetPlayer = nil
            autoFireEnabled = false
        end
    end

    -- FOV 원 크기 적용 및 위치를 화면 중앙에 고정
    fovCircle.Radius = FOV_RADIUS_BODY * fovMultiplier
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Visible = true

    fovHeadCircle.Radius = FOV_RADIUS_HEAD * fovMultiplier
    fovHeadCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovHeadCircle.Visible = true
end)
