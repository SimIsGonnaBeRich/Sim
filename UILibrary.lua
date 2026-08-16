local Library = {}
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

function Library:CreateWindow(titleText)
    local Window = {}
    
    -- [[ 1. 기본 창 생성 ]]
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SimUIHub"
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local MainFrame = Instance.new("CanvasGroup", ScreenGui)
    MainFrame.Name = "Frame"
    MainFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    -- [ 창 드래그(이동) 기능 ]
    local dragging, dragInput, dragStart, startPos
    MainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- [[ 2. 디자인 바(Bar) 구성 ]]
    local TopBar = Instance.new("Frame", MainFrame)
    TopBar.Size = UDim2.new(1, 0, 0.06, 0)
    TopBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    
    local TitleLabel = Instance.new("TextLabel", TopBar)
    TitleLabel.Size = UDim2.new(1, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = titleText or "Made by Sim"
    TitleLabel.TextColor3 = Color3.fromRGB(201, 201, 201)
    TitleLabel.Font = Enum.Font.PatrickHand
    TitleLabel.TextScaled = true

    local BottomBar = Instance.new("Frame", MainFrame)
    BottomBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BottomBar.AnchorPoint = Vector2.new(0, 1)
    BottomBar.Size = UDim2.new(1, 0, 0.04, 0)
    BottomBar.Position = UDim2.new(0, 0, 1, 0)
    
    local BottomRightText = Instance.new("TextLabel", BottomBar)
    BottomRightText.Size = UDim2.new(1, -20, 1, 0)
    BottomRightText.Position = UDim2.new(0.5, 0, 0.5, 0)
    BottomRightText.AnchorPoint = Vector2.new(0.5, 0.5)
    BottomRightText.BackgroundTransparency = 1
    BottomRightText.Text = "Beta"
    BottomRightText.TextColor3 = Color3.fromRGB(201, 201, 201)
    BottomRightText.Font = Enum.Font.PatrickHand
    BottomRightText.TextScaled = true
    BottomRightText.TextXAlignment = Enum.TextXAlignment.Right

    local RightBar = Instance.new("Frame", MainFrame)
    RightBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    RightBar.AnchorPoint = Vector2.new(1, 0)
    RightBar.Size = UDim2.new(0.06, 0, 0.9, -2)
    RightBar.Position = UDim2.new(1, 0, 0.06, 1)

    local LeftBar = Instance.new("ImageLabel", MainFrame)
    LeftBar.Size = UDim2.new(0.25, 0, 0.9, -2)
    LeftBar.Position = UDim2.new(0, 0, 0.06, 1)
    LeftBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    local LeftBarLayout = Instance.new("UIListLayout", LeftBar)
    LeftBarLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local Workspace = Instance.new("Frame", MainFrame)
    Workspace.Size = UDim2.new(0.69, -2, 0.9, -2)
    Workspace.Position = UDim2.new(0.25, 1, 0.06, 1)
    Workspace.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Workspace.BorderSizePixel = 0

    local firstTab = true

    -- [[ 3. 탭(Tab) 생성 함수 ]]
    function Window:CreateTab(tabName)
        local Tab = {}
        
        local TabButton = Instance.new("TextButton", LeftBar)
        TabButton.Size = UDim2.new(1, 0, 0.1, 0)
        TabButton.Text = tabName
        TabButton.TextColor3 = Color3.fromRGB(201, 201, 201)
        TabButton.BackgroundTransparency = 1
        TabButton.Font = Enum.Font.PatrickHand
        TabButton.TextScaled = true

        local ScrollFrame = Instance.new("ScrollingFrame", Workspace)
        ScrollFrame.Size = UDim2.new(1, 0, 1, 0)
        ScrollFrame.BackgroundTransparency = 1
        ScrollFrame.ScrollBarThickness = 5
        ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(136, 81, 236)
        ScrollFrame.Visible = firstTab
        firstTab = false
        
        local ScrollLayout = Instance.new("UIListLayout", ScrollFrame)
        ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ScrollLayout.Padding = UDim.new(0, 5)

        TabButton.MouseButton1Click:Connect(function()
            for _, child in pairs(Workspace:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            ScrollFrame.Visible = true
        end)

        -- [[ 4. 그룹(Group) 생성 함수 ]]
        function Tab:CreateGroup()
            local Group = {}
            local orderCounter = 1 -- 📌 LayoutOrder 순서를 정렬할 카운터
            
            local GroupFrame = Instance.new("Frame", ScrollFrame)
            GroupFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            GroupFrame.BackgroundTransparency = 1
            GroupFrame.Size = UDim2.new(1, -2, 0, 0)
            GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
            Instance.new("UICorner", GroupFrame)
            
            local Stroke = Instance.new("UIStroke", GroupFrame)
            Stroke.Color = Color3.fromRGB(201, 201, 201)
            
            local GroupLayout = Instance.new("UIListLayout", GroupFrame)
            GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder -- 📌 LayoutOrder로 정렬

            -- 📌 구분선(Border) 자동 추가 & LayoutOrder 지정 로직
            local function checkBorder()
                if orderCounter > 1 then
                    local Border = Instance.new("Frame", GroupFrame)
                    Border.Name = "Border"
                    Border.Size = UDim2.new(1, 0, 0, 1)
                    Border.BackgroundColor3 = Color3.fromRGB(201, 201, 201)
                    Border.BorderSizePixel = 0
                    Border.LayoutOrder = orderCounter -- 📌 보더 위치 고정
                    orderCounter = orderCounter + 1
                end
            end

            -- [ 1. 일반 토글 ]
            function Group:AddToggle(name, callback)
                checkBorder()
                local state = false
                local Toggle = Instance.new("Frame", GroupFrame)
                Toggle.Size = UDim2.new(1, 0, 0, 40)
                Toggle.BackgroundTransparency = 1
                Toggle.LayoutOrder = orderCounter -- 📌 위치 고정
                orderCounter = orderCounter + 1
                
                local Title = Instance.new("TextLabel", Toggle)
                Title.Size = UDim2.new(0.5, 0, 0.5, 0)
                Title.Position = UDim2.new(0.05, 0, 0.25, 0)
                Title.Text = name
                Title.TextColor3 = Color3.fromRGB(201, 201, 201)
                Title.Font = Enum.Font.PatrickHand
                Title.TextScaled = true
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.BackgroundTransparency = 1
                
                local Button = Instance.new("TextButton", Toggle)
                Button.Size = UDim2.new(0, 40, 0.5, 0)
                Button.Position = UDim2.new(0.85, 0, 0.25, 0)
                Button.Text = ""
                Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Instance.new("UICorner", Button).CornerRadius = UDim.new(0.2, 0)
                local BtnStroke = Instance.new("UIStroke", Button)
                BtnStroke.Color = Color3.fromRGB(201, 201, 201)

                Button.MouseButton1Click:Connect(function()
                    state = not state
                    Button.BackgroundColor3 = state and Color3.fromRGB(136, 81, 236) or Color3.fromRGB(0, 0, 0)
                    if callback then callback(state) end
                end)
            end

            -- [ 2. 일반 슬라이더 ]
            function Group:AddSlider(name, min, max, default, callback)
                checkBorder()
                local SliderFrame = Instance.new("Frame", GroupFrame)
                SliderFrame.Size = UDim2.new(1, 0, 0, 50)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.LayoutOrder = orderCounter
                orderCounter = orderCounter + 1

                local Title = Instance.new("TextLabel", SliderFrame)
                Title.Size = UDim2.new(0.5, 0, 0.5, 0)
                Title.Position = UDim2.new(0.05, 0, 0.25, 0)
                Title.Text = name
                Title.TextColor3 = Color3.fromRGB(201, 201, 201)
                Title.Font = Enum.Font.PatrickHand
                Title.TextScaled = true
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.BackgroundTransparency = 1

                local ValueText = Instance.new("TextLabel", SliderFrame)
                ValueText.Size = UDim2.new(0.18, 0, 0.5, 0)
                ValueText.Position = UDim2.new(0.85, 0, 0.25, 0)
                ValueText.Text = tostring(default)
                ValueText.TextColor3 = Color3.fromRGB(136, 81, 236)
                ValueText.Font = Enum.Font.PatrickHand
                ValueText.TextScaled = true
                ValueText.BackgroundTransparency = 1

                local Bar = Instance.new("TextButton", SliderFrame)
                Bar.Size = UDim2.new(0.4, 0, 0.1, 0)
                Bar.Position = UDim2.new(0.4, 0, 0.45, 0)
                Bar.BackgroundColor3 = Color3.fromRGB(201, 201, 201)
                Bar.Text = ""
                Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

                local Fill = Instance.new("Frame", Bar)
                Fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
                Fill.BackgroundColor3 = Color3.fromRGB(136, 81, 236)
                Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

                local dragging = false
                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mousePos = UserInputService:GetMouseLocation().X
                        local relativePos = mousePos - Bar.AbsolutePosition.X
                        local percentage = math.clamp(relativePos / Bar.AbsoluteSize.X, 0, 1)
                        
                        Fill.Size = UDim2.new(percentage, 0, 1, 0)
                        local value = math.floor(min + ((max - min) * percentage))
                        ValueText.Text = tostring(value)
                        if callback then callback(value) end
                    end
                end)
            end

            -- [ 3. 드롭다운 ]
            function Group:AddDropdown(name, options, callback)
                checkBorder()
                local DropFrame = Instance.new("Frame", GroupFrame)
                DropFrame.Size = UDim2.new(1, 0, 0, 50)
                DropFrame.BackgroundTransparency = 1
                DropFrame.LayoutOrder = orderCounter
                orderCounter = orderCounter + 1

                local Title = Instance.new("TextLabel", DropFrame)
                Title.Size = UDim2.new(0.5, 0, 0.5, 0)
                Title.Position = UDim2.new(0.05, 0, 0.25, 0)
                Title.Text = name
                Title.TextColor3 = Color3.fromRGB(201, 201, 201)
                Title.Font = Enum.Font.PatrickHand
                Title.TextScaled = true
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.BackgroundTransparency = 1

                local DropButton = Instance.new("TextButton", DropFrame)
                DropButton.Size = UDim2.new(0.3, 0, 0.6, 0)
                DropButton.Position = UDim2.new(0.65, 0, 0.2, 0)
                DropButton.Text = "Select..."
                DropButton.TextColor3 = Color3.fromRGB(136, 81, 236)
                DropButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                DropButton.Font = Enum.Font.PatrickHand
                DropButton.TextScaled = true
                Instance.new("UICorner", DropButton).CornerRadius = UDim.new(0.2, 0)
                local DropStroke = Instance.new("UIStroke", DropButton)
                DropStroke.Color = Color3.fromRGB(201, 201, 201)

                local List = Instance.new("Frame", DropFrame)
                List.Size = UDim2.new(0.3, 0, 0, 0)
                List.Position = UDim2.new(0.65, 0, 0.85, 0)
                List.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                List.AutomaticSize = Enum.AutomaticSize.Y
                List.Visible = false
                List.ZIndex = 5
                Instance.new("UICorner", List)
                local ListStroke = Instance.new("UIStroke", List)
                ListStroke.Color = Color3.fromRGB(201, 201, 201)
                
                local ListLayout = Instance.new("UIListLayout", List)
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

                DropButton.MouseButton1Click:Connect(function()
                    List.Visible = not List.Visible
                end)

                for _, option in ipairs(options) do
                    local OptionBtn = Instance.new("TextButton", List)
                    OptionBtn.Size = UDim2.new(1, 0, 0, 30)
                    OptionBtn.Text = option
                    OptionBtn.TextColor3 = Color3.fromRGB(201, 201, 201)
                    OptionBtn.BackgroundTransparency = 1
                    OptionBtn.Font = Enum.Font.PatrickHand
                    OptionBtn.TextScaled = true
                    OptionBtn.ZIndex = 6

                    OptionBtn.MouseButton1Click:Connect(function()
                        DropButton.Text = option
                        List.Visible = false
                        if callback then callback(option) end
                    end)
                end
            end

            -- 📌 [ 4. 토글 + 슬라이더 통합본 (ToggleSlider) ]
            function Group:AddToggleSlider(name, min, max, default, callback)
                checkBorder()
                local state = false -- 토글 상태
                local currentValue = default
                
                local TSFrame = Instance.new("Frame", GroupFrame)
                TSFrame.Size = UDim2.new(1, 0, 0, 60)
                TSFrame.BackgroundTransparency = 1
                TSFrame.LayoutOrder = orderCounter
                orderCounter = orderCounter + 1
                
                local Title = Instance.new("TextLabel", TSFrame)
                Title.Size = UDim2.new(0.45, 0, 0.5, 0)
                Title.Position = UDim2.new(0.05, 0, 0.25, 0)
                Title.Text = name
                Title.TextColor3 = Color3.fromRGB(201, 201, 201)
                Title.Font = Enum.Font.PatrickHand
                Title.TextScaled = true
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.BackgroundTransparency = 1
                
                -- 버튼(토글 겸 수치 표시)
                local ValueBtn = Instance.new("TextButton", TSFrame)
                ValueBtn.Size = UDim2.new(0, 45, 0.5, 0) -- 제공된 UIAspectRatio 기준
                ValueBtn.Position = UDim2.new(0.85, 0, 0.25, 0)
                ValueBtn.Text = "" -- 꺼져있을 땐 텍스트 숨김 (일반 토글처럼)
                ValueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                ValueBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                ValueBtn.Font = Enum.Font.PatrickHand
                ValueBtn.TextScaled = true
                Instance.new("UICorner", ValueBtn).CornerRadius = UDim.new(0.2, 0)
                local BtnStroke = Instance.new("UIStroke", ValueBtn)
                BtnStroke.Color = Color3.fromRGB(201, 201, 201)
                
                -- 슬라이더 바
                local Bar = Instance.new("TextButton", TSFrame)
                Bar.Size = UDim2.new(0.35, 0, 0.1, 0)
                Bar.Position = UDim2.new(0.48, 0, 0.45, 0)
                Bar.BackgroundColor3 = Color3.fromRGB(201, 201, 201)
                Bar.Text = ""
                Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)
                
                local Fill = Instance.new("Frame", Bar)
                Fill.Size = UDim2.new(math.clamp((default - min) / (max - min), 0, 1), 0, 1, 0)
                Fill.BackgroundColor3 = Color3.fromRGB(136, 81, 236)
                Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

                -- 📌 토글 클릭 로직
                ValueBtn.MouseButton1Click:Connect(function()
                    state = not state
                    if state then
                        ValueBtn.BackgroundColor3 = Color3.fromRGB(136, 81, 236)
                        ValueBtn.Text = tostring(currentValue) -- 켜지면 수치 보임
                    else
                        ValueBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        ValueBtn.Text = "" -- 꺼지면 수치 숨김
                    end
                    if callback then callback(state, currentValue) end
                end)
                
                -- 📌 슬라이더 드래그 로직 (토글이 켜져있을 때만 유효!)
                local dragging = false
                Bar.InputBegan:Connect(function(input)
                    if not state then return end -- 켜져있지 않으면 무시!
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and state and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local mousePos = UserInputService:GetMouseLocation().X
                        local relativePos = mousePos - Bar.AbsolutePosition.X
                        local percentage = math.clamp(relativePos / Bar.AbsoluteSize.X, 0, 1)
                        
                        Fill.Size = UDim2.new(percentage, 0, 1, 0)
                        currentValue = math.floor(min + ((max - min) * percentage))
                        
                        -- 수치 실시간 업데이트
                        ValueBtn.Text = tostring(currentValue)
                        if callback then callback(state, currentValue) end
                    end
                end)
            end

            return Group
        end

        return Tab
    end

    return Window
end

return Library