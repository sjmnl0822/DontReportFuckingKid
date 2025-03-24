-- 신고하면 아구창 찢어버린다
  
local Players = game:GetService("Players")
  
local RunService = game:GetService("RunService")
  
local UserInputService = game:GetService("UserInputService")
  
local Drawing = Drawing or require("Drawing")
  
local localPlayer = Players.LocalPlayer
  
local camera = workspace.CurrentCamera
  

  
-- 기존 스크립트 제거
  
if _G.AimbotConnections then
  
    for _, connection in ipairs(_G.AimbotConnections) do
  
        if connection and connection.Disconnect then
  
            connection:Disconnect()
  
        end
  
    end
  
end
  
_G.AimbotConnections = {}
  

  
if _G.FOV_Circle then
  
    _G.FOV_Circle:Remove()
  
end
  
_G.FOV_Circle = nil
  

  
local targetPlayer = nil 
local MAX_DISTANCE = 750 -- 거리 제한
  
local aimEnabled = false
  
local SMOOTHING_FACTOR = 0.5 -- 에임 부드러움
  

  
-- FOV 원 생성
  
local fovCircle = Drawing.new("Circle")
  
fovCircle.Color = Color3.fromRGB(255, 255, 255)
  
fovCircle.Thickness = 1
  
fovCircle.NumSides = 50
  
fovCircle.Radius = 100
  
fovCircle.Filled = false
  
fovCircle.Transparency = 0.05
  
fovCircle.Visible = true
  
_G.FOV_Circle = fovCircle
  

  
local function getClosestPlayer()
  
    local closestPlayer = nil
  
    local shortestCursorDistance = math.huge
  
    local centerPosition = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
  
    local localRoot = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
  
    if not localRoot then return nil end
  

  
    for _, player in ipairs(Players:GetPlayers()) do
  
        if player ~= localPlayer and player.Character then -- 자신 제외
  
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
  
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
  
            if humanoid and humanoid.Health > 0 and rootPart then
  
                local worldDistance = (rootPart.Position - localRoot.Position).Magnitude
  
                local screenPosition, onScreen = camera:WorldToViewportPoint(rootPart.Position)
  
                local cursorDistance = (Vector2.new(screenPosition.X, screenPosition.Y) - centerPosition).Magnitude
  
                
  
                -- 거리 제한 및 FOV 내에 있는 경우만 타겟으로 삼기
  
                if worldDistance <= MAX_DISTANCE and cursorDistance <= fovCircle.Radius and onScreen then
  
                    if cursorDistance < shortestCursorDistance then
  
                        closestPlayer = player
  
                        shortestCursorDistance = cursorDistance
  
                    end
  
                end
  
            end
  
        end
  
    end
  
    return closestPlayer
  
end
  

  
local function aimAtTarget(targetPart)
  
    if targetPlayer and targetPlayer.Character and targetPart then
  
        local targetScreenPosition = camera:WorldToViewportPoint(targetPart.Position)
  
        local mouseDelta = Vector2.new(targetScreenPosition.X, targetScreenPosition.Y) - UserInputService:GetMouseLocation()
  
        mouseDelta = mouseDelta * SMOOTHING_FACTOR -- 부드러운 이동 적용
  
        mousemoverel(mouseDelta.X, mouseDelta.Y)
  
        
  
        -- 화면도 조준한 위치로 이동 (마우스를 따라가도록 수정)
  
        -- 화면 조준 제거
  
    end
  
end
  

  
local function centerMouse()
  
    local viewportSize = camera.ViewportSize
  
    local centerPosition = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
  
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
  
    UserInputService.MouseIconEnabled = false
  
    mousemoverel(centerPosition.X - UserInputService:GetMouseLocation().X, centerPosition.Y - UserInputService:GetMouseLocation().Y)
  
end
  

  
local aimStart = UserInputService.InputBegan:Connect(function(input, isProcessed)
  
    
  
    if input.KeyCode == Enum.KeyCode.Nine then -- 9번 키를 눌렀을 때 에임봇 활성화
  
        centerMouse() -- 마우스를 중앙에 고정
  
        aimEnabled = true
  
    end
  
end)
  

  
local aimEnd = UserInputService.InputEnded:Connect(function(input)
  
    if input.KeyCode == Enum.KeyCode.Nine then -- 9번 키를 떼면 에임봇 비활성화
  
        aimEnabled = false
  
        targetPlayer = nil -- 에임봇 해제 시 타겟 초기화
  
        
  
    end
  
end)
  

  
local aimLoop = RunService.Heartbeat:Connect(function()
  
    if aimEnabled then
  
        local closestPlayer = getClosestPlayer()
  
        if closestPlayer and (not targetPlayer or not targetPlayer.Character or not targetPlayer:FindFirstChildOfClass("Humanoid") or targetPlayer:FindFirstChildOfClass("Humanoid").Health <= 0) then
  
            
  
            targetPlayer = closestPlayer
  
            local targetPart = closestPlayer.Character:FindFirstChild("Head") or closestPlayer.Character:FindFirstChild("HumanoidRootPart")
  
            aimAtTarget(targetPart)
  
                else
  
            targetPlayer = nil
  
            lastTarget = nil
  
        end
  
    else
  
        targetPlayer = nil
  
        lastTarget = nil
  
    end
  

  
    -- FOV 원 위치를 화면 중앙에 고정
  
    fovCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
  
    fovCircle.Visible = true
  
end)
  

  
-- 연결 관리
  
_G.AimbotConnections = {aimStart, aimEnd, aimLoop} 
