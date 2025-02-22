-- 신고하면 아구창 찢어버린다
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Drawing = Drawing or require("Drawing")

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local targetPlayer = nil
local MAX_DISTANCE = 2000 -- 조준 거리 제한
local FOV_RADIUS = 100 -- FOV 크기
local autoFireEnabled = false -- 단발 발사 기능 상태

-- FOV 원 그리기
local fovCircle = Drawing.new("Circle")

fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.NumSides = 50
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Visible = true

local function isLobbyVisible()
    return localPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Visible == true
end

local function getClosestPlayerToMouse()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local centerPosition = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local head = player.Character.Head
            local distance = (localPlayer.Character:FindFirstChild("HumanoidRootPart").Position - head.Position).Magnitude

            if humanoid and humanoid.Health > 0 and distance <= MAX_DISTANCE then
                local headPosition, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local screenPosition = Vector2.new(headPosition.X, headPosition.Y)
                    local cursorDistance = (screenPosition - centerPosition).Magnitude

                    -- ✅ FOV 범위 내의 플레이어만 감지
                    if cursorDistance < FOV_RADIUS and cursorDistance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = cursorDistance
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function lockCameraToHead()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Head") then
        local humanoid = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        local head = targetPlayer.Character.Head

        if humanoid and humanoid.Health > 0 then
            local cameraPosition = camera.CFrame.Position
            local direction = (head.Position - cameraPosition).Unit
            local ray = Ray.new(cameraPosition, direction * (head.Position - cameraPosition).Magnitude)
            local hit, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character, camera})

            if hit and hit:IsDescendantOf(targetPlayer.Character) then
                local newPosition = cameraPosition + direction * 0.5
                camera.CFrame = CFrame.new(newPosition, head.Position)
            end
        end
    end
end

UserInputService.InputBegan:Connect(function(input, isProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and not isProcessed then
        if not isLobbyVisible() and autoFireEnabled then
            mouse1click()
            fovCircle.Visible = true -- 클릭 시 FOV가 사라지는 문제 해결
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not isLobbyVisible() then
        targetPlayer = getClosestPlayerToMouse()
        autoFireEnabled = targetPlayer ~= nil -- FOV 안에 사람이 있으면 단발 발사 기능 활성화
        if targetPlayer then
            lockCameraToHead()
        end
    end
    
    -- FOV 원 위치를 화면 중앙에 고정
    if fovCircle then
        fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
        fovCircle.Visible = true -- 클릭 시 사라지는 문제 방지
    end
end)
