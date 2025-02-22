-- 신고하면 아구창 찢어버린다
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Drawing = Drawing or require("Drawing")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local targetPlayer = nil
local MAX_DISTANCE = 2000 -- 조준 거리 제한
local FOV_RADIUS_BODY = 100 -- 몸통 FOV 크기
local FOV_RADIUS_HEAD = 55.5 -- 머리 FOV 크기
local autoFireEnabled = false -- 단발 발사 기능 상태

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

local function getClosestPlayer()
    local closestHead = nil
    local closestBody = nil
    local shortestDistanceHead = math.huge
    local shortestDistanceBody = math.huge
    local centerPosition = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and humanoid.Health > 0 and rootPart then
                local bodyParts = player.Character:GetChildren()
                for _, part in ipairs(bodyParts) do
                    if part:IsA("BasePart") then
                        local partPosition, partOnScreen = camera:WorldToViewportPoint(part.Position)
                        if partOnScreen then
                            local partScreenPos = Vector2.new(partPosition.X, partPosition.Y)
                            local partCursorDistance = (partScreenPos - centerPosition).Magnitude
                            
                            if partCursorDistance < FOV_RADIUS_HEAD and partCursorDistance < shortestDistanceHead then
                                closestHead = player
                                shortestDistanceHead = partCursorDistance
                            end
                            
                            if partCursorDistance < FOV_RADIUS_BODY and partCursorDistance < shortestDistanceBody then
                                local fullBodyInside = partCursorDistance + (rootPart.Size.Magnitude / 2) < FOV_RADIUS_BODY
                                if fullBodyInside then
                                    closestBody = player
                                    shortestDistanceBody = partCursorDistance
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return closestHead or closestBody, closestHead and closestHead.Character:FindFirstChild("Head") or closestBody and closestBody.Character:FindFirstChild("HumanoidRootPart")
end

local function lockCameraToTarget(targetPart)
    if targetPlayer and targetPlayer.Character and targetPart then
        local cameraPosition = camera.CFrame.Position
        local direction = (targetPart.Position - cameraPosition).Unit
        local newPosition = cameraPosition + direction * 0.5
        camera.CFrame = CFrame.new(newPosition, targetPart.Position)
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        if not isLobbyVisible() and autoFireEnabled then
            mouse1click()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        local closestPlayer, targetPart = getClosestPlayer()
        
        if closestPlayer then
            targetPlayer = closestPlayer
            autoFireEnabled = true
            lockCameraToTarget(targetPart)
        else
            targetPlayer = nil
            autoFireEnabled = false
        end
    end
    
    -- FOV 원 위치를 화면 중앙에 고정
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovCircle.Visible = true
    
    fovHeadCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    fovHeadCircle.Visible = true
end)
