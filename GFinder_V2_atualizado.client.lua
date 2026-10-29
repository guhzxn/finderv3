--[[
    G FINDER - GUI + ranking framework
    Instalação: Roblox Studio > StarterPlayer > StarterPlayerScripts > LocalScript

    IMPORTANTE:
    - Este arquivo implementa a GUI, filtros, ordenação, Job ID manual e teleporte.
    - Para resultados reais, conecte `publishServerResults(results)` a uma fonte de dados
      autorizada do SEU jogo. O Roblox não oferece uma API pública universal para ler
      raridades/Money/s de todos os servidores de jogos de terceiros.
    - A consulta pública de servidores, quando feita no servidor do seu próprio jogo,
      deve ser implementada separadamente com APIs/serviços permitidos.
]]

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local C = {
    bg = Color3.fromRGB(17, 19, 23),
    header = Color3.fromRGB(24, 27, 32),
    panel = Color3.fromRGB(29, 32, 38),
    panelAlt = Color3.fromRGB(36, 40, 47),
    row = Color3.fromRGB(31, 34, 40),
    border = Color3.fromRGB(58, 63, 73),
    white = Color3.fromRGB(245, 247, 250),
    muted = Color3.fromRGB(157, 165, 178),
    soft = Color3.fromRGB(205, 211, 221),
    accent = Color3.fromRGB(225, 230, 239),
    good = Color3.fromRGB(135, 218, 163),
    bad = Color3.fromRGB(238, 132, 132),
}

local function new(className, props, parent)
    local inst = Instance.new(className)
    for key, value in pairs(props or {}) do inst[key] = value end
    inst.Parent = parent
    return inst
end

local function corner(parent, px)
    new("UICorner", {CornerRadius = UDim.new(0, px or 9)}, parent)
end

local function outline(parent, transparency)
    new("UIStroke", {
        Color = C.border,
        Thickness = 1,
        Transparency = transparency or 0.1,
    }, parent)
end

local function text(parent, value, size, color, font)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = value or "",
        TextColor3 = color or C.white,
        Font = font or Enum.Font.Gotham,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        BorderSizePixel = 0,
    }, parent)
end

local function button(parent, value, width, strong)
    local b = new("TextButton", {
        BackgroundColor3 = strong and C.accent or C.panelAlt,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Size = UDim2.new(0, width or 100, 0, 32),
        Text = value,
        TextColor3 = strong and C.bg or C.white,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
    }, parent)
    corner(b, 8)
    if not strong then outline(b) end
    return b
end

local function input(parent, placeholder, value, width)
    local box = new("TextBox", {
        BackgroundColor3 = C.bg,
        BorderSizePixel = 0,
        Size = UDim2.new(0, width or 120, 0, 32),
        Text = value or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = C.muted,
        TextColor3 = C.white,
        ClearTextOnFocus = false,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
    corner(box, 8)
    outline(box)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 8),
    }, box)
    return box
end

local function notify(titleText, messageText)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = titleText,
            Text = messageText,
            Duration = 4,
        })
    end)
end

local gui = new("ScreenGui", {
    Name = "GFinder",
    ResetOnSpawn = false,
    IgnoreGuiInset = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = new("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 760, 0, 620),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, gui)
corner(main, 14)
outline(main, 0)

local uiScale = new("UIScale", {Scale = 1}, main)
local function fitScreen()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    uiScale.Scale = math.clamp(math.min(v.X / 820, v.Y / 690), 0.58, 1)
end
fitScreen()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitScreen)
end

-- Header
local header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.header,
    BorderSizePixel = 0,
}, main)
corner(header, 14)
new("Frame", {
    Position = UDim2.new(0, 0, 1, -14),
    Size = UDim2.new(1, 0, 0, 14),
    BackgroundColor3 = C.header,
    BorderSizePixel = 0,
}, header)

-- Custom G / lightning emblem built from text so no external image is needed.
local logo = new("Frame", {
    Position = UDim2.new(0, 16, 0, 10),
    Size = UDim2.new(0, 44, 0, 44),
    BackgroundColor3 = C.panelAlt,
    BorderSizePixel = 0,
}, header)
corner(logo, 12)
outline(logo, 0.05)
local logoG = text(logo, "G", 30, C.white, Enum.Font.GothamBlack)
logoG.Position = UDim2.new(0, 5, 0, 0)
logoG.Size = UDim2.new(1, -10, 1, 0)
logoG.TextXAlignment = Enum.TextXAlignment.Center
local bolt = text(logo, "ϟ", 22, C.soft, Enum.Font.GothamBlack)
bolt.Position = UDim2.new(0, 19, 0, 8)
bolt.Size = UDim2.new(0, 18, 0, 27)
bolt.TextXAlignment = Enum.TextXAlignment.Center

local appTitle = text(header, "G FINDER", 19, C.white, Enum.Font.GothamBlack)
appTitle.Position = UDim2.new(0, 72, 0, 10)
appTitle.Size = UDim2.new(0, 155, 0, 25)
local subtitle = text(header, "SERVER SCANNER  /  BETA", 9, C.muted, Enum.Font.GothamBold)
subtitle.Position = UDim2.new(0, 73, 0, 35)
subtitle.Size = UDim2.new(0, 220, 0, 17)

local statusDot = new("Frame", {
    Position = UDim2.new(1, -158, 0, 25),
    Size = UDim2.new(0, 8, 0, 8),
    BackgroundColor3 = C.muted,
    BorderSizePixel = 0,
}, header)
corner(statusDot, 8)
local status = text(header, "INATIVO", 11, C.muted, Enum.Font.GothamBold)
status.Position = UDim2.new(1, -144, 0, 16)
status.Size = UDim2.new(0, 82, 0, 26)
local minimize = button(header, "—", 34, false)
minimize.Position = UDim2.new(1, -48, 0, 17)

local body = new("Frame", {
    Name = "Body",
    Position = UDim2.new(0, 16, 0, 80),
    Size = UDim2.new(1, -32, 1, -96),
    BackgroundTransparency = 1,
}, main)

-- Summary cards
local summary = new("Frame", {
    Size = UDim2.new(1, 0, 0, 78),
    BackgroundTransparency = 1,
}, body)
local summaryLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 10),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, summary)

local function statCard(titleText, initialValue, order)
    local card = new("Frame", {
        Size = UDim2.new(1/3, -7, 1, 0),
        BackgroundColor3 = C.panel,
        BorderSizePixel = 0,
        LayoutOrder = order,
    }, summary)
    corner(card, 10)
    outline(card)
    local t = text(card, titleText, 10, C.muted, Enum.Font.GothamBold)
    t.Position = UDim2.new(0, 13, 0, 9)
    t.Size = UDim2.new(1, -22, 0, 18)
    local v = text(card, initialValue, 23, C.white, Enum.Font.GothamBold)
    v.Position = UDim2.new(0, 13, 0, 29)
    v.Size = UDim2.new(1, -22, 0, 34)
    return v
end

local totalStat = statCard("SERVIDORES VERIFICADOS", "0", 1)
local freeStat = statCard("SERVIDORES COM VAGAS", "0", 2)
local bestStat = statCard("MAIOR MONEY/S", "—", 3)

-- Filter panel
local filters = new("Frame", {
    Position = UDim2.new(0, 0, 0, 90),
    Size = UDim2.new(1, 0, 0, 122),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, body)
corner(filters, 10)
outline(filters)
local filterTitle = text(filters, "FILTROS DE BUSCA", 10, C.muted, Enum.Font.GothamBold)
filterTitle.Position = UDim2.new(0, 13, 0, 7)
filterTitle.Size = UDim2.new(0, 160, 0, 18)

local start = button(filters, "INICIAR BUSCA", 126, true)
start.Position = UDim2.new(1, -139, 0, 7)

local rarityLabel = text(filters, "RARIDADES", 9, C.muted, Enum.Font.GothamBold)
rarityLabel.Position = UDim2.new(0, 13, 0, 31)
rarityLabel.Size = UDim2.new(0, 100, 0, 16)
local rarityBtn = button(filters, "TODAS  v", 132, false)
rarityBtn.Position = UDim2.new(0, 13, 0, 50)

local moneyLabel = text(filters, "MÍNIMO MONEY/S", 9, C.muted, Enum.Font.GothamBold)
moneyLabel.Position = UDim2.new(0, 159, 0, 31)
moneyLabel.Size = UDim2.new(0, 125, 0, 16)
local moneyInput = input(filters, "Ex.: 44000000000", "44000000000", 150)
moneyInput.Position = UDim2.new(0, 159, 0, 50)

local slotsLabel = text(filters, "VAGAS MÍNIMAS", 9, C.muted, Enum.Font.GothamBold)
slotsLabel.Position = UDim2.new(0, 322, 0, 31)
slotsLabel.Size = UDim2.new(0, 120, 0, 16)
local slotsBtn = button(filters, "1 VAGA  v", 120, false)
slotsBtn.Position = UDim2.new(0, 322, 0, 50)

local sortLabel = text(filters, "ORDENAR POR", 9, C.muted, Enum.Font.GothamBold)
sortLabel.Position = UDim2.new(0, 455, 0, 31)
sortLabel.Size = UDim2.new(0, 110, 0, 16)
local sortBtn = button(filters, "MAIOR MONEY/S  v", 155, false)
sortBtn.Position = UDim2.new(0, 455, 0, 50)

local giantOnly = true
local giantBtn = button(filters, "GIGANTES: SIM", 132, true)
giantBtn.Position = UDim2.new(0, 13, 0, 82)

local sizeLabel = text(filters, "TAMANHO MÍN. (×)", 9, C.muted, Enum.Font.GothamBold)
sizeLabel.Position = UDim2.new(0, 159, 0, 78)
sizeLabel.Size = UDim2.new(0, 115, 0, 16)
local sizeInput = input(filters, "Ex.: 4", "4", 72)
sizeInput.Position = UDim2.new(0, 159, 0, 94)
sizeInput.Size = UDim2.new(0, 72, 0, 24)

local filterHint = text(filters, "Somente alvos selecionados; dados reais exigem uma fonte autorizada.", 9, C.muted)
filterHint.Position = UDim2.new(0, 245, 0, 87)
filterHint.Size = UDim2.new(1, -258, 0, 28)
filterHint.TextWrapped = true

-- Results
local resultsTitle = text(body, "SERVIDORES ENCONTRADOS", 10, C.muted, Enum.Font.GothamBold)
resultsTitle.Position = UDim2.new(0, 2, 0, 222)
resultsTitle.Size = UDim2.new(0, 260, 0, 20)
local resultsCount = text(body, "0 RESULTADOS", 10, C.muted, Enum.Font.GothamBold)
resultsCount.Position = UDim2.new(1, -130, 0, 222)
resultsCount.Size = UDim2.new(0, 128, 0, 20)
resultsCount.TextXAlignment = Enum.TextXAlignment.Right

local list = new("ScrollingFrame", {
    Name = "Results",
    Position = UDim2.new(0, 0, 0, 246),
    Size = UDim2.new(1, 0, 1, -324),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.muted,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, body)
corner(list, 10)
outline(list)
new("UIPadding", {
    PaddingTop = UDim.new(0, 9),
    PaddingBottom = UDim.new(0, 9),
    PaddingLeft = UDim.new(0, 9),
    PaddingRight = UDim.new(0, 9),
}, list)
new("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, list)

local empty = text(list, "Nenhum resultado válido.\nA fonte deve fornecer pets-alvo, Money/s, tamanho, Job ID e horário real.", 12, C.muted)
empty.Name = "EmptyState"
empty.Size = UDim2.new(1, -8, 0, 60)
empty.TextXAlignment = Enum.TextXAlignment.Center
empty.TextWrapped = true
empty.LayoutOrder = 0

-- Job ID footer
local jobPanel = new("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 0, 66),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, body)
corner(jobPanel, 10)
outline(jobPanel)
local jobTitle = text(jobPanel, "JOB ID MANAGER", 9, C.muted, Enum.Font.GothamBold)
jobTitle.Position = UDim2.new(0, 12, 0, 4)
jobTitle.Size = UDim2.new(0, 120, 0, 15)
local jobInput = input(jobPanel, "Cole o Job ID da instância...", "", 300)
jobInput.Position = UDim2.new(0, 12, 0, 25)
jobInput.Size = UDim2.new(1, -270, 0, 30)
local joinJob = button(jobPanel, "ENTRAR", 92, true)
joinJob.Position = UDim2.new(1, -246, 0, 24)
local copyJob = button(jobPanel, "COPIAR ID ATUAL", 142, false)
copyJob.Position = UDim2.new(1, -146, 0, 24)

-- State and data adapter
local rarityOptions = {"TODAS", "SECRET", "ETERNAL", "DIVINE"}
local rarityIndex = 1
local slotOptions = {1, 2, 3, 4, 5, 6, 7}
local slotIndex = 1
local sortOptions = {"MAIOR MONEY/S", "MAIS VAGAS", "MAIS RECENTES"}
local sortIndex = 1
local scanning = false
local minimized = false
local records = {}
local selectedJobId = nil

-- Lista autorizada pelo projeto: somente os oito alvos escolhidos.
-- A correspondência ignora maiúsculas/minúsculas, mas exige o nome do alvo.
local TARGET_PETS = {
    "Leão Solar Celestial",
    "Baleia do Céu Real",
    "Arcanjo",
    "Queimador de Mundos",
    "Rei Gorila",
    "Chama Noturna",
    "Oni Tigre",
    "Kitsune",
}

local function normalizeName(value)
    return string.lower(tostring(value or ""))
end

local function isTargetPet(value)
    local candidate = normalizeName(value)
    for _, target in ipairs(TARGET_PETS) do
        if candidate == normalizeName(target) then
            return true
        end
    end
    return false
end

local function validJobId(value)
    return type(value) == "string"
        and #value >= 8
        and #value <= 100
        and not string.find(value, "%s")
end

local function fmt(n)
    n = tonumber(n) or 0
    if n >= 1e12 then return string.format("%.2fT", n / 1e12) end
    if n >= 1e9 then return string.format("%.2fB", n / 1e9) end
    if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
    if n >= 1e3 then return string.format("%.2fK", n / 1e3) end
    return tostring(math.floor(n))
end

local function setScanning(value)
    scanning = value
    start.Text = scanning and "PAUSAR BUSCA" or "INICIAR BUSCA"
    status.Text = scanning and "BUSCANDO" or "INATIVO"
    status.TextColor3 = scanning and C.good or C.muted
    statusDot.BackgroundColor3 = scanning and C.good or C.muted
end

local function clearRows()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") and child.Name == "ServerCard" then child:Destroy() end
    end
end

local function render()
    clearRows()
    local filtered = {}
    local minimumMoney = math.max(0, tonumber(moneyInput.Text) or 44000000000)
    local minimumSlots = slotOptions[slotIndex]
    local minimumSize = math.max(1, tonumber(sizeInput.Text) or 4)
    local rarity = rarityOptions[rarityIndex]
    local now = os.time()
    local seen = {}

    for _, item in ipairs(records) do
        local maxPlayers = tonumber(item.maxPlayers) or 7
        local playing = tonumber(item.playing)
        local money = tonumber(item.moneyPerSecond)
        local sizeMultiplier = tonumber(item.sizeMultiplier)
        local freeSlots = playing and math.max(0, maxPlayers - playing) or 0
        local rarityMatch = rarity == "TODAS" or string.upper(tostring(item.rarity or "")) == rarity
        local targetMatch = isTargetPet(item.name)
        local moneyMatch = money ~= nil and money >= minimumMoney
        local sizeMatch = not giantOnly or (sizeMultiplier ~= nil and sizeMultiplier >= minimumSize)
        local slotsMatch = playing == nil or freeSlots >= minimumSlots
        local jobMatch = validJobId(item.jobId)
        local checkedAt = tonumber(item.checkedAt)
        local freshMatch = checkedAt ~= nil and checkedAt <= now + 30 and (now - checkedAt) <= 300
        local duplicateKey = tostring(item.jobId) .. "|" .. normalizeName(item.name)

        if targetMatch and rarityMatch and moneyMatch and sizeMatch and slotsMatch
            and jobMatch and freshMatch and not seen[duplicateKey] then
            seen[duplicateKey] = true
            table.insert(filtered, item)
        end
    end

    if sortIndex == 1 then
        table.sort(filtered, function(a, b)
            return (tonumber(a.moneyPerSecond) or 0) > (tonumber(b.moneyPerSecond) or 0)
        end)
    elseif sortIndex == 2 then
        table.sort(filtered, function(a, b)
            return ((tonumber(a.maxPlayers) or 7) - (tonumber(a.playing) or 7))
                > ((tonumber(b.maxPlayers) or 7) - (tonumber(b.playing) or 7))
        end)
    else
        table.sort(filtered, function(a, b)
            return (tonumber(a.checkedAt) or 0) > (tonumber(b.checkedAt) or 0)
        end)
    end

    totalStat.Text = tostring(#records)
    local available = 0
    local bestMoney = 0
    for _, item in ipairs(records) do
        local playing = tonumber(item.playing)
        local maxPlayers = tonumber(item.maxPlayers) or 7
        if playing and playing < maxPlayers then available += 1 end
        bestMoney = math.max(bestMoney, tonumber(item.moneyPerSecond) or 0)
    end
    freeStat.Text = tostring(available)
    bestStat.Text = bestMoney > 0 and fmt(bestMoney) or "—"
    resultsCount.Text = tostring(#filtered) .. " RESULTADOS"
    empty.Visible = #filtered == 0

    for index, item in ipairs(filtered) do
        local playing = tonumber(item.playing) or 0
        local maxPlayers = tonumber(item.maxPlayers) or 7
        local freeSlots = math.max(0, maxPlayers - playing)
        local card = new("Frame", {
            Name = "ServerCard",
            Size = UDim2.new(1, -2, 0, 86),
            BackgroundColor3 = C.row,
            BorderSizePixel = 0,
            LayoutOrder = index,
        }, list)
        corner(card, 9)
        outline(card)

        local rarityText = string.upper(tostring(item.rarity or "DESCONHECIDA"))
        local name = text(card, tostring(item.name or "Servidor"), 14, C.white, Enum.Font.GothamBold)
        name.Position = UDim2.new(0, 12, 0, 7)
        name.Size = UDim2.new(1, -190, 0, 21)
        name.TextTruncate = Enum.TextTruncate.AtEnd

        local sizeText = tonumber(item.sizeMultiplier)
            and string.format("%.1f×", tonumber(item.sizeMultiplier)) or "tamanho não verificado"
        local details = text(card,
            rarityText .. "   •   " .. fmt(item.moneyPerSecond) .. "/s   •   " .. sizeText,
            10, C.soft, Enum.Font.GothamMedium)
        details.Position = UDim2.new(0, 12, 0, 31)
        details.Size = UDim2.new(1, -190, 0, 18)
        details.TextTruncate = Enum.TextTruncate.AtEnd

        local biome = tostring(item.biome or "bioma não informado")
        local idLabel = text(card, biome .. "   •   JOB ID  " .. tostring(item.jobId or "indisponível"), 9, C.muted)
        idLabel.Position = UDim2.new(0, 12, 0, 55)
        idLabel.Size = UDim2.new(1, -190, 0, 17)
        idLabel.TextTruncate = Enum.TextTruncate.AtEnd

        local enter = button(card, freeSlots > 0 and "ENTRAR" or "CHEIO", 82, freeSlots > 0)
        enter.Position = UDim2.new(1, -94, 0, 10)
        enter.Size = UDim2.new(0, 82, 0, 29)
        enter.MouseButton1Click:Connect(function()
            if freeSlots <= 0 then
                notify("Servidor cheio", "Não há vagas disponíveis neste resultado.")
                return
            end
            if not validJobId(item.jobId) then
                notify("Job ID indisponível", "Este resultado não contém um Job ID válido.")
                return
            end
            selectedJobId = item.jobId
            jobInput.Text = item.jobId
            local ok, err = pcall(function()
                TeleportService:TeleportToPlaceInstance(tonumber(item.placeId) or game.PlaceId, item.jobId, player)
            end)
            if not ok then notify("Falha no teleporte", tostring(err)) end
        end)

        local copy = button(card, "COPIAR ID", 82, false)
        copy.Position = UDim2.new(1, -94, 0, 48)
        copy.Size = UDim2.new(0, 82, 0, 27)
        copy.MouseButton1Click:Connect(function()
            selectedJobId = item.jobId
            if item.jobId then
                jobInput.Text = item.jobId
                jobInput:CaptureFocus()
                jobInput.CursorPosition = #jobInput.Text + 1
                notify("Job ID selecionado", "Use Ctrl+A e Ctrl+C para copiar.")
            end
        end)
    end
end

-- Use esta função para fornecer dados reais vindos de uma integração autorizada.
-- Cada item esperado:
-- {name, biome, rarity, moneyPerSecond, sizeMultiplier, playing, maxPlayers,
--  jobId, placeId, checkedAt}
-- checkedAt deve ser um timestamp Unix recente; o painel descarta dados com mais de 5 minutos.
local function publishServerResults(results)
    records = type(results) == "table" and results or {}
    render()
end

start.MouseButton1Click:Connect(function()
    setScanning(not scanning)
    filterHint.Text = scanning
        and "Busca ativada na interface; conecte aqui sua fonte autorizada de dados."
        or "Busca pausada. Os resultados carregados permanecem na lista."
end)

rarityBtn.MouseButton1Click:Connect(function()
    rarityIndex = rarityIndex % #rarityOptions + 1
    rarityBtn.Text = rarityOptions[rarityIndex] .. "  v"
    render()
end)

slotsBtn.MouseButton1Click:Connect(function()
    slotIndex = slotIndex % #slotOptions + 1
    local n = slotOptions[slotIndex]
    slotsBtn.Text = tostring(n) .. (n == 1 and " VAGA  v" or " VAGAS  v")
    render()
end)

sortBtn.MouseButton1Click:Connect(function()
    sortIndex = sortIndex % #sortOptions + 1
    sortBtn.Text = sortOptions[sortIndex] .. "  v"
    render()
end)

moneyInput.FocusLost:Connect(render)
sizeInput.FocusLost:Connect(render)

giantBtn.MouseButton1Click:Connect(function()
    giantOnly = not giantOnly
    giantBtn.Text = giantOnly and "GIGANTES: SIM" or "GIGANTES: NÃO"
    giantBtn.BackgroundColor3 = giantOnly and C.accent or C.panelAlt
    giantBtn.TextColor3 = giantOnly and C.bg or C.white
    render()
end)

joinJob.MouseButton1Click:Connect(function()
    local jobId = string.gsub(jobInput.Text, "^%s*(.-)%s*$", "%1")
    if jobId == "" or #jobId > 100 or string.find(jobId, "%s") then
        notify("Job ID inválido", "Cole um Job ID válido.")
        return
    end
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, player)
    end)
    if not ok then notify("Falha no teleporte", tostring(err)) end
end)

copyJob.MouseButton1Click:Connect(function()
    local id = game.JobId
    if id == "" then
        notify("Job ID indisponível", "O ambiente atual não forneceu um Job ID.")
        return
    end
    jobInput.Text = id
    jobInput:CaptureFocus()
    jobInput.CursorPosition = #jobInput.Text + 1
    notify("Job ID selecionado", "Use Ctrl+A e Ctrl+C para copiar.")
end)

minimize.MouseButton1Click:Connect(function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.new(0, 760, 0, 66) or UDim2.new(0, 760, 0, 620)
    minimize.Text = minimized and "+" or "—"
end)

-- Arrastar janela pelo cabeçalho
do
    local dragging = false
    local dragStart, startPos
    header.InputBegan:Connect(function(inputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1
            or inputObject.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inputObject.Position
            startPos = main.Position
            inputObject.Changed:Connect(function()
                if inputObject.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inputObject)
        if dragging and (inputObject.UserInputType == Enum.UserInputType.MouseMovement
            or inputObject.UserInputType == Enum.UserInputType.Touch) then
            local delta = inputObject.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Função de integração disponível dentro deste LocalScript:
-- publishServerResults({
--   {name="Exemplo", rarity="SECRET", moneyPerSecond=123456, playing=5,
--    maxPlayers=7, jobId="JOB_ID", placeId=game.PlaceId, checkedAt=os.time()}
-- })
-- Os valores acima são apenas um exemplo fictício.
_G.GFinderPublishResults = publishServerResults

setScanning(false)
render()
