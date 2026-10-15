
--[[
    CeeHub v1.0
    Made by CeeWorks

    Neon Aurora UI - electric violet, cyan and magenta

    Place in:
    StarterPlayer > StarterPlayerScripts

    RightShift = Show / Hide

    Discord: CeeWorks Studio
    Invite Code: W5hU4DEJKZ
]]

-- SERVICES

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CLEAN OLD INSTANCE

if type(_G.CeeHubCleanup) == "function" then
	pcall(_G.CeeHubCleanup)
end

local old = playerGui:FindFirstChild("CeeHub")
if old then
	old:Destroy()
end

-- THEME

-- Legacy ORANGE keys remain so the existing UI and game logic need no rewrites.
local C = {
	BG = Color3.fromRGB(10, 11, 29),
	SIDE = Color3.fromRGB(16, 15, 42),
	CARD = Color3.fromRGB(26, 25, 57),
	HOVER = Color3.fromRGB(42, 35, 85),
	ORANGE = Color3.fromRGB(166, 91, 255), -- electric violet
	ORANGE_DARK = Color3.fromRGB(107, 47, 214),
	ORANGE_LIGHT = Color3.fromRGB(112, 241, 255), -- ice cyan
	WHITE = Color3.fromRGB(250, 247, 255),
	MUTED = Color3.fromRGB(171, 175, 211),
	BORDER = Color3.fromRGB(70, 66, 121),
	GREEN = Color3.fromRGB(92, 247, 206),
	CYAN = Color3.fromRGB(57, 230, 255),
	PINK = Color3.fromRGB(255, 80, 207)
}

local state = {
	esp = false,
	names = false,
	teamCheck = true,
	aim = false,
	fov = true,
	radius = 100,
	targetPart = "Head",
	animations = true
}

local mouseOverrideThreshold = 15
local mouseOverrideCooldown = 0.65

local running = true
local connections = {}
local playerConnections = {}
local playerVisuals = {}
local pages = {}
local navButtons = {}
local refreshers = {}

local currentPage = "Home"
local currentTarget = nil
local ignoredTarget = nil
local overrideUntil = 0
local mouseMovement = 0
local previousMouseMovement = 0

-- HELPERS

local function create(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		object[property] = value
	end

	object.Parent = parent
	return object
end

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function corner(parent, radius)
	return create("UICorner", {
		CornerRadius = UDim.new(0, radius or 14)
	}, parent)
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color or C.BORDER,
		Thickness = thickness or 1.5,
		Transparency = transparency or 0
	}, parent)
end

local function tween(object, properties, duration)
	local animation = TweenService:Create(
		object,
		TweenInfo.new(
			state.animations and (duration or 0.22) or 0.01,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)

	animation:Play()
	return animation
end

local function label(parent, value, size, color, bold)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = value,
		TextSize = size or 14,
		TextColor3 = color or C.WHITE,
		Font = bold and Enum.Font.GothamBold
			or Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center
	}, parent)
end

local function gradient(parent, first, second, rotation)
	return create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, first),
			ColorSequenceKeypoint.new(1, second)
		}),
		Rotation = rotation or 0
	}, parent)
end

-- Subtle neon fades; these affect appearance only.
local function neonFade(parent, first, middle, last, rotation)
	return create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, first),
			ColorSequenceKeypoint.new(0.5, middle),
			ColorSequenceKeypoint.new(1, last)
		}),
		Rotation = rotation or 25
	}, parent)
end

-- GUI

local gui = create("ScreenGui", {
	Name = "CeeHub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 100,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

-- SMALLER MAIN WINDOW

local WINDOW_WIDTH = 700
local WINDOW_HEIGHT = 450

local shadow = create("Frame", {
	Name = "Shadow",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(
		WINDOW_WIDTH + 10,
		WINDOW_HEIGHT + 10
	),
	BackgroundColor3 = Color3.fromRGB(9, 5, 28),
	BackgroundTransparency = 0.68,
	BorderSizePixel = 0,
	ZIndex = 0
}, gui)

corner(shadow, 25)
local shadowScale = create("UIScale", {Scale = 1}, shadow)

-- Soft luminous rim, positioned behind the main window.
local neonHalo = create("Frame", {
	Name = "NeonHalo",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WINDOW_WIDTH + 6, WINDOW_HEIGHT + 6),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.25,
	BorderSizePixel = 0,
	ZIndex = 0
}, gui)
corner(neonHalo, 24)
neonFade(neonHalo, C.CYAN, C.ORANGE, C.PINK, 20)
local haloScale = create("UIScale", {Scale = 1}, neonHalo)

local main = create("Frame", {
	Name = "Main",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(
		WINDOW_WIDTH,
		WINDOW_HEIGHT
	),
	BackgroundColor3 = C.BG,
	BorderSizePixel = 0,
	ClipsDescendants = true
}, gui)

corner(main, 22)
-- Deep aurora tint, clipped by the same rounded silhouette.
neonFade(main, Color3.fromRGB(12, 12, 36), Color3.fromRGB(21, 15, 48), Color3.fromRGB(9, 20, 42), 130)
-- Main clips all content to the rounded outer silhouette.

local scale = create("UIScale", {
	Scale = 1
}, main)

local lastViewport = Vector2.zero

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then return end

	local viewport = camera.ViewportSize
	if viewport.X < 100 or viewport.Y < 100 then
		return
	end

	if viewport == lastViewport then
		return
	end

	lastViewport = viewport

	scale.Scale = math.clamp(
		math.min(
			(viewport.X - 35) / WINDOW_WIDTH,
			(viewport.Y - 35) / WINDOW_HEIGHT
		),
		0.4,
		1
	)
	shadowScale.Scale = scale.Scale
	haloScale.Scale = scale.Scale
end

updateScale()

-- SIDEBAR

local SIDEBAR_WIDTH = 185

local sidebar = create("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
	BackgroundColor3 = C.SIDE,
	BorderSizePixel = 0
}, main)

-- Rounded exterior, with a straight INNER edge for the orange divider.
corner(sidebar, 22)
create("Frame", {
	Name = "SidebarInnerEdge",
	Position = UDim2.new(1, -24, 0, 0),
	Size = UDim2.new(0, 24, 1, 0),
	BackgroundColor3 = C.SIDE,
	BorderSizePixel = 0
}, sidebar)

local sidebarAccent = create("Frame", {
	Position = UDim2.new(1, -3, 0, 0),
	Size = UDim2.new(0, 3, 1, 0),
	BackgroundColor3 = C.ORANGE,
	BorderSizePixel = 0
}, sidebar)
neonFade(sidebarAccent, C.CYAN, C.ORANGE, C.PINK, 90)

-- CEEHUB LOGO

local logo = label(
	sidebar,
	"CeeHub",
	27,
	C.WHITE,
	true
)

logo.Position = UDim2.fromOffset(17, 15)
logo.Size = UDim2.fromOffset(155, 38)

local logoUnderline = create("Frame", {
	Position = UDim2.fromOffset(18, 57),
	Size = UDim2.fromOffset(84, 4),
	BackgroundColor3 = C.ORANGE,
	BorderSizePixel = 0
}, sidebar)

corner(logoUnderline, 4)
neonFade(logoUnderline, C.CYAN, C.ORANGE, C.PINK, 0)

local version = label(
	sidebar,
	"VERSION 1.0",
	10,
	C.MUTED,
	true
)

version.Position = UDim2.fromOffset(18, 67)
version.Size = UDim2.fromOffset(145, 19)

-- NAVIGATION

local nav = create("Frame", {
	Position = UDim2.fromOffset(12, 105),
	Size = UDim2.new(1, -27, 0, 235),
	BackgroundTransparency = 1
}, sidebar)

create("UIListLayout", {
	Padding = UDim.new(0, 7),
	SortOrder = Enum.SortOrder.LayoutOrder
}, nav)

-- DISCORD COMMUNITY

local discordCard = create("TextButton", {
	Name = "DiscordInvite",
	Text = "",
	AutoButtonColor = false,
	Position = UDim2.new(0, 12, 1, -103),
	Size = UDim2.new(1, -27, 0, 72),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0
}, sidebar)

corner(discordCard, 14)
stroke(discordCard, C.ORANGE, 1.7)
neonFade(discordCard, Color3.fromRGB(36, 20, 73), Color3.fromRGB(27, 28, 69), Color3.fromRGB(16, 39, 61), 15)

local discordTitle = label(
	discordCard,
	"JOIN OUR DISCORD!",
	11,
	C.ORANGE,
	true
)

discordTitle.Position = UDim2.fromOffset(7, 6)
discordTitle.Size = UDim2.new(1, -14, 0, 17)
discordTitle.TextXAlignment = Enum.TextXAlignment.Center

local discordName = label(
	discordCard,
	"CeeWorks Studio",
	11,
	C.WHITE,
	true
)

discordName.Position = UDim2.fromOffset(7, 25)
discordName.Size = UDim2.new(1, -14, 0, 17)
discordName.TextXAlignment = Enum.TextXAlignment.Center

local discordCode = label(
	discordCard,
	"W5hU4DEJKZ",
	14,
	C.ORANGE_LIGHT,
	true
)

discordCode.Position = UDim2.fromOffset(7, 45)
discordCode.Size = UDim2.new(1, -14, 0, 19)
discordCode.TextXAlignment = Enum.TextXAlignment.Center

local footer = label(
	sidebar,
	"Made by CeeWorks",
	10,
	C.MUTED
)

footer.Position = UDim2.new(0, 17, 1, -27)
footer.Size = UDim2.fromOffset(150, 19)

-- CONTENT

local content = create("Frame", {
	Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0),
	Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, 0),
	BackgroundTransparency = 1
}, main)

local header = create("Frame", {
	Size = UDim2.new(1, 0, 0, 65),
	BackgroundColor3 = C.SIDE,
	BorderSizePixel = 0
}, content)

-- Round the header itself: an uncovered header rectangle can make
-- the main window's top-right corner look square in Roblox.
corner(header, 22)

-- Keep only the lower part of the header squared so its bottom
-- separator stays straight, while the upper-right edge is rounded.
create("Frame", {
	Name = "HeaderSquareBottom",
	Position = UDim2.new(0, 0, 1, -22),
	Size = UDim2.new(1, 0, 0, 22),
	BackgroundColor3 = C.SIDE,
	BorderSizePixel = 0
}, header)

local heading = label(
	header,
	"DASHBOARD",
	20,
	C.WHITE,
	true
)

heading.Position = UDim2.fromOffset(23, 12)
heading.Size = UDim2.fromOffset(290, 31)

local headerSubtitle = label(
	header,
	"Universal Aimbot + ESP",
	10,
	C.MUTED
)

headerSubtitle.Position = UDim2.fromOffset(24, 40)
headerSubtitle.Size = UDim2.fromOffset(310, 16)

local headerLine = create("Frame", {
	Position = UDim2.new(0, 0, 1, -2),
	Size = UDim2.new(1, 0, 0, 2),
	BackgroundColor3 = C.BORDER,
	BorderSizePixel = 0
}, header)
neonFade(headerLine, C.CYAN, C.ORANGE, C.PINK, 0)

local function headerButton(symbol, offset)
	local button = create("TextButton", {
		Position = UDim2.new(1, offset, 0, 15),
		Size = UDim2.fromOffset(33, 33),
		BackgroundColor3 = C.CARD,
		Text = symbol,
		TextColor3 = C.WHITE,
		TextSize = 19,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false
	}, header)

	corner(button, 11)

	connect(button.MouseEnter, function()
		tween(button, {
			BackgroundColor3 = C.ORANGE_DARK
		})
	end)

	connect(button.MouseLeave, function()
		tween(button, {
			BackgroundColor3 = C.CARD
		})
	end)

	return button
end

local minimizeButton = headerButton("−", -78)
local closeButton = headerButton("×", -40)

-- PAGE HOLDER
-- Extra padding prevents rounded cards from being clipped.

local holder = create("Frame", {
	Position = UDim2.fromOffset(19, 78),
	Size = UDim2.new(1, -38, 1, -92),
	BackgroundTransparency = 1,
	ClipsDescendants = true
}, content)

-- NOTIFICATIONS

local function notify(message)
	if not running then return end

	local notification = create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -15, 1, 60),
		Size = UDim2.fromOffset(285, 45),
		BackgroundColor3 = C.CARD,
		BorderSizePixel = 0,
		ZIndex = 30
	}, gui)

	corner(notification, 12)
	stroke(notification, C.ORANGE, 1.5)

	local notificationText = label(
		notification,
		"◆  " .. message,
		12,
		C.WHITE,
		true
	)

	notificationText.Position = UDim2.fromOffset(12, 5)
	notificationText.Size = UDim2.new(1, -24, 1, -10)
	notificationText.ZIndex = 31

	tween(notification, {
		Position = UDim2.new(1, -15, 1, -15)
	}, 0.3)

	task.delay(2.2, function()
		if not notification.Parent then return end

		local animation = tween(notification, {
			Position = UDim2.new(1, -15, 1, 60)
		}, 0.3)

		animation.Completed:Wait()

		if notification.Parent then
			notification:Destroy()
		end
	end)
end

-- INTERACTIVE DISCORD CARD
-- Roblox experiences cannot directly launch Discord/Chrome via a LocalScript.
-- Direct players to the experience's official Social Links instead.

local discordPopup = create("Frame", {
	Name = "DiscordInfoPopup",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(350, 185),
	BackgroundColor3 = C.SIDE,
	BorderSizePixel = 0,
	Visible = false,
	ZIndex = 60
}, gui)
corner(discordPopup, 16)
stroke(discordPopup, C.ORANGE, 1.8)

local popupHeading = label(discordPopup, "CeeWorks Studio", 19, C.WHITE, true)
popupHeading.Position = UDim2.fromOffset(18, 15)
popupHeading.Size = UDim2.new(1, -70, 0, 28)
popupHeading.ZIndex = 61

local popupDescription = label(
	discordPopup,
	"Find our Discord in the Roblox experience's Social Links.",
	12,
	C.MUTED
)
popupDescription.Position = UDim2.fromOffset(18, 53)
popupDescription.Size = UDim2.new(1, -36, 0, 46)
popupDescription.TextWrapped = true
popupDescription.ZIndex = 61

local popupCode = label(discordPopup, "Invite code: W5hU4DEJKZ", 15, C.ORANGE_LIGHT, true)
popupCode.Position = UDim2.fromOffset(18, 109)
popupCode.Size = UDim2.new(1, -36, 0, 27)
popupCode.ZIndex = 61

local popupClose = create("TextButton", {
	Position = UDim2.new(1, -45, 0, 12),
	Size = UDim2.fromOffset(30, 30),
	BackgroundColor3 = C.CARD,
	Text = "×",
	TextColor3 = C.WHITE,
	TextSize = 21,
	Font = Enum.Font.GothamBold,
	AutoButtonColor = false,
	ZIndex = 62
}, discordPopup)
corner(popupClose, 10)

connect(discordCard.MouseButton1Click, function()
	discordPopup.Visible = not discordPopup.Visible
end)

connect(discordCard.MouseEnter, function()
	tween(discordCard, {BackgroundColor3 = C.HOVER}, 0.18)
end)

connect(discordCard.MouseLeave, function()
	tween(discordCard, {BackgroundColor3 = C.CARD}, 0.18)
end)

connect(popupClose.MouseButton1Click, function()
	discordPopup.Visible = false
end)

-- PAGES

local function addPage(name)
	local page = create("ScrollingFrame", {
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.ORANGE,
		Visible = false,
		ClipsDescendants = true
	}, holder)

	-- Padding creates breathing room around all cards.

	create("UIPadding", {
		PaddingLeft = UDim.new(0, 3),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 3),
		PaddingBottom = UDim.new(0, 15)
	}, page)

	create("UIListLayout", {
		Padding = UDim.new(0, 11),
		SortOrder = Enum.SortOrder.LayoutOrder
	}, page)

	pages[name] = page
	return page
end

local function switchPage(name)
	currentPage = name

	for pageName, page in pairs(pages) do
		page.Visible = pageName == name

		if page.Visible then
			page.Position = UDim2.fromOffset(9, 0)

			tween(page, {
				Position = UDim2.fromOffset(0, 0)
			}, 0.24)
		end
	end

	for pageName, button in pairs(navButtons) do
		local selected = pageName == name

		tween(button, {
			BackgroundColor3 = selected
				and C.ORANGE_DARK
				or C.CARD,

			TextColor3 = selected
				and C.WHITE
				or C.MUTED
		}, 0.2)
	end

	heading.Text = string.upper(
		name == "Home" and "Dashboard" or name
	)
end

local tabs = {
	{"Home", "⌂"},
	{"Visuals", "◈"},
	{"Targeting", "◎"},
	{"Players", "◉"},
	{"Settings", "⚙"}
}

for index, tab in ipairs(tabs) do
	local name = tab[1]
	local symbol = tab[2]

	addPage(name)

	local button = create("TextButton", {
		Name = name,
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = C.CARD,
		Text = "  " .. symbol .. "     " .. name,
		TextColor3 = C.MUTED,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutoButtonColor = false
	}, nav)

	corner(button, 12)

	navButtons[name] = button

	connect(button.MouseEnter, function()
		if currentPage ~= name then
			tween(button, {
				BackgroundColor3 = C.HOVER
			})
		end
	end)

	connect(button.MouseLeave, function()
		if currentPage ~= name then
			tween(button, {
				BackgroundColor3 = C.CARD
			})
		end
	end)

	connect(button.MouseButton1Click, function()
		switchPage(name)
	end)
end

-- SECTION TITLES

local function section(page, name)
	local sectionLabel = label(
		page,
		"//  " .. string.upper(name),
		13,
		C.WHITE,
		true
	)

	sectionLabel.Size = UDim2.new(1, 0, 0, 27)

	return sectionLabel
end

local function refreshKey(key)
	for _, refresh in ipairs(refreshers[key] or {}) do
		refresh()
	end
end

-- ROUNDED FEATURE CARDS

local function toggle(page, name, description, key, callback)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 69),
		BackgroundColor3 = C.CARD,
		BorderSizePixel = 0
	}, page)

	corner(card, 15)
	neonFade(card, Color3.fromRGB(28, 25, 63), Color3.fromRGB(29, 29, 66), Color3.fromRGB(20, 40, 65), 0)

	local outline = stroke(
		card,
		C.BORDER,
		1.5,
		0.12
	)

	local titleLabel = label(
		card,
		name,
		14,
		C.WHITE,
		true
	)

	titleLabel.Position = UDim2.fromOffset(17, 11)
	titleLabel.Size = UDim2.new(1, -115, 0, 24)

	local descriptionLabel = label(
		card,
		description,
		10,
		C.MUTED
	)

	descriptionLabel.Position = UDim2.fromOffset(17, 37)
	descriptionLabel.Size = UDim2.new(1, -115, 0, 18)

	local button = create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.fromOffset(53, 29),
		BackgroundColor3 = C.BORDER,
		Text = "",
		AutoButtonColor = false
	}, card)

	corner(button, 15)

	local knob = create("Frame", {
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(21, 21),
		BackgroundColor3 = C.WHITE,
		BorderSizePixel = 0
	}, button)

	corner(knob, 12)

	local function refresh()
		local enabled = state[key]

		tween(button, {
			BackgroundColor3 = enabled
				and C.ORANGE
				or C.BORDER
		})

		tween(knob, {
			Position = enabled
				and UDim2.fromOffset(28, 4)
				or UDim2.fromOffset(4, 4)
		})
	end

	refreshers[key] = refreshers[key] or {}
	table.insert(refreshers[key], refresh)

	connect(card.MouseEnter, function()
		tween(card, {
			BackgroundColor3 = C.HOVER
		})

		tween(outline, {
			Color = C.ORANGE
		})
	end)

	connect(card.MouseLeave, function()
		tween(card, {
			BackgroundColor3 = C.CARD
		})

		tween(outline, {
			Color = C.BORDER
		})
	end)

	connect(button.MouseButton1Click, function()
		state[key] = not state[key]

		if callback then
			callback(state[key])
		end

		refreshKey(key)

		notify(
			name .. (
				state[key] and " enabled" or " disabled"
			)
		)
	end)

	refresh()
end

-- SLIDERS

local function slider(page, name, minimum, maximum, initial, callback)
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 91),
		BackgroundColor3 = C.CARD,
		BorderSizePixel = 0
	}, page)

	corner(card, 15)
	stroke(card, C.BORDER, 1.5, 0.12)

	local nameLabel = label(
		card,
		name,
		14,
		C.WHITE,
		true
	)

	nameLabel.Position = UDim2.fromOffset(17, 10)
	nameLabel.Size = UDim2.new(1, -110, 0, 25)

	local valueLabel = label(
		card,
		tostring(initial),
		14,
		C.ORANGE_LIGHT,
		true
	)

	valueLabel.Position = UDim2.new(1, -78, 0, 10)
	valueLabel.Size = UDim2.fromOffset(60, 25)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local track = create("Frame", {
		Position = UDim2.fromOffset(18, 61),
		Size = UDim2.new(1, -36, 0, 7),
		BackgroundColor3 = C.BORDER,
		BorderSizePixel = 0
	}, card)

	corner(track, 6)

	local alpha =
		(initial - minimum) / (maximum - minimum)

	local fill = create("Frame", {
		Size = UDim2.fromScale(alpha, 1),
		BackgroundColor3 = C.ORANGE,
		BorderSizePixel = 0
	}, track)

	corner(fill, 6)

	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(alpha, 0.5),
		Size = UDim2.fromOffset(17, 17),
		BackgroundColor3 = C.WHITE,
		BorderSizePixel = 0
	}, track)

	corner(dot, 9)

	local hitbox = create("TextButton", {
		Position = UDim2.fromOffset(0, -14),
		Size = UDim2.new(1, 0, 0, 35),
		BackgroundTransparency = 1,
		Text = ""
	}, track)

	local dragging = false

	local function update(x)
		if track.AbsoluteSize.X <= 0 then
			return
		end

		local a = math.clamp(
			(x - track.AbsolutePosition.X)
				/ track.AbsoluteSize.X,
			0,
			1
		)

		local value = math.floor(
			minimum + (maximum - minimum) * a
		)

		fill.Size = UDim2.fromScale(a, 1)
		dot.Position = UDim2.fromScale(a, 0.5)
		valueLabel.Text = tostring(value)

		if callback then
			callback(value)
		end
	end

	connect(hitbox.InputBegan, function(input)
		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = true
			update(input.Position.X)
		end
	end)

	connect(UIS.InputChanged, function(input)
		if dragging and (
			input.UserInputType ==
				Enum.UserInputType.MouseMovement
				or input.UserInputType ==
				Enum.UserInputType.Touch
			) then
			update(input.Position.X)
		end
	end)

	connect(UIS.InputEnded, function(input)
		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			dragging = false
		end
	end)
end

-- PLAYER VISUALS

local function clearVisual(target)
	local objects = playerVisuals[target]

	if objects then
		for _, object in pairs(objects) do
			if object then
				object:Destroy()
			end
		end
	end

	playerVisuals[target] = nil
end

local function eligible(target)
	if target == player then
		return false
	end

	if state.teamCheck
		and not player.Neutral
		and not target.Neutral
		and player.Team == target.Team then

		return false
	end

	return true
end

local function updateVisual(target)
	clearVisual(target)

	if not eligible(target) then return end

	local character = target.Character
	if not character then return end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not humanoid or humanoid.Health <= 0 then
		return
	end

	playerVisuals[target] = {}

	if state.esp then
		local highlight = create("Highlight", {
			Name = "CeeHubESP",
			Adornee = character,
			DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
			FillColor = C.ORANGE,
			OutlineColor = C.ORANGE_LIGHT,
			FillTransparency = 0.78,
			OutlineTransparency = 0
		}, gui)

		playerVisuals[target].highlight = highlight
	end

	if state.names then
		local head = character:FindFirstChild("Head")

		if head then
			local tag = create("BillboardGui", {
				Name = "CeeHubName",
				Adornee = head,
				Size = UDim2.fromOffset(150, 32),
				StudsOffset = Vector3.new(0, 2.8, 0),
				AlwaysOnTop = true,
				MaxDistance = 1000
			}, gui)

			local nameBackground = create("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = C.SIDE,
				BackgroundTransparency = 0.12,
				BorderSizePixel = 0
			}, tag)

			corner(nameBackground, 10)
			stroke(nameBackground, C.ORANGE, 1.3)

			local nameText = label(
				nameBackground,
				target.DisplayName,
				13,
				C.WHITE,
				true
			)

			nameText.Size = UDim2.fromScale(1, 1)
			nameText.TextXAlignment =
				Enum.TextXAlignment.Center

			playerVisuals[target].tag = tag
		end
	end
end

local function refreshVisuals()
	for _, target in ipairs(Players:GetPlayers()) do
		updateVisual(target)
	end
end

local function watchPlayer(target)
	if target == player then return end
	if playerConnections[target] then return end

	playerConnections[target] = {}

	local added = target.CharacterAdded:Connect(function()
		task.wait(0.3)

		if running then
			updateVisual(target)
		end
	end)

	local removing = target.CharacterRemoving:Connect(function()
		clearVisual(target)
	end)

	table.insert(playerConnections[target], added)
	table.insert(playerConnections[target], removing)

	if target.Character then
		updateVisual(target)
	end
end

for _, target in ipairs(Players:GetPlayers()) do
	watchPlayer(target)
end

connect(Players.PlayerAdded, watchPlayer)

connect(Players.PlayerRemoving, function(target)
	clearVisual(target)

	for _, connection in ipairs(
		playerConnections[target] or {}
		) do
		connection:Disconnect()
	end

	playerConnections[target] = nil

	if currentTarget
		and currentTarget.Parent == target.Character then

		currentTarget = nil
	end

	if ignoredTarget == target then
		ignoredTarget = nil
	end
end)

connect(
	player:GetPropertyChangedSignal("Team"),
	refreshVisuals
)

-- FOV CIRCLE

local fov = create("Frame", {
	Name = "FOVCircle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(
		state.radius * 2,
		state.radius * 2
	),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false
}, gui)

create("UICorner", {
	CornerRadius = UDim.new(1, 0)
}, fov)

create("UIStroke", {
	Color = C.ORANGE,
	Thickness = 2,
	Transparency = 0.1
}, fov)

local function updateFov()
	fov.Visible = state.fov

	tween(fov, {
		Size = UDim2.fromOffset(
			state.radius * 2,
			state.radius * 2
		)
	}, 0.2)
end

-- TARGETING

local function getAimPart(character)
	if state.targetPart == "Head" then
		return character:FindFirstChild("Head")
	end

	return character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("HumanoidRootPart")
end

local function targetInsideFov(part)
	local camera = workspace.CurrentCamera

	if not camera or not part then
		return false, math.huge
	end

	local point, onScreen =
		camera:WorldToViewportPoint(part.Position)

	if not onScreen or point.Z <= 0 then
		return false, math.huge
	end

	local center = camera.ViewportSize / 2

	local distance = (
		Vector2.new(point.X, point.Y) - center
	).Magnitude

	return distance <= state.radius, distance
end

local function validTargetPart(part)
	if not part or not part.Parent then
		return false
	end

	local character = part.Parent

	local targetPlayer =
		Players:GetPlayerFromCharacter(character)

	if not targetPlayer or not eligible(targetPlayer) then
		return false
	end

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	return humanoid ~= nil and humanoid.Health > 0
end

local function findNearestTarget()
	local nearest = nil
	local nearestDistance = state.radius

	for _, target in ipairs(Players:GetPlayers()) do
		if eligible(target)
			and target ~= ignoredTarget
			and target.Character then

			local humanoid =
				target.Character:FindFirstChildOfClass("Humanoid")

			local part = getAimPart(target.Character)

			if humanoid and humanoid.Health > 0 and part then
				local inside, distance =
					targetInsideFov(part)

				if inside and distance <= nearestDistance then
					nearest = part
					nearestDistance = distance
				end
			end
		end
	end

	return nearest
end

local function isFirstPerson()
	local camera = workspace.CurrentCamera
	local character = player.Character

	if not camera or not character then
		return false
	end

	local head = character:FindFirstChild("Head")
	if not head then return false end

	return (
		camera.CFrame.Position - head.Position
	).Magnitude < 1.5
end

-- MOUSE OVERRIDE

connect(UIS.InputChanged, function(input, processed)
	if not running or not state.aim then
		return
	end

	if input.UserInputType ==
		Enum.UserInputType.MouseMovement then

		if processed and UIS:GetFocusedTextBox() then
			return
		end

		mouseMovement =
			mouseMovement + input.Delta.Magnitude
	end
end)

local function breakLock()
	if not currentTarget then return end

	local character = currentTarget.Parent

	ignoredTarget =
		Players:GetPlayerFromCharacter(character)

	currentTarget = nil

	overrideUntil =
		os.clock() + mouseOverrideCooldown
end

-- CAMERA CONTROLLER

local aimRenderName = "CeeHubAimAssist"

RunService:BindToRenderStep(
	aimRenderName,
	Enum.RenderPriority.Camera.Value + 2,
	function()
		if not running then return end

		updateScale()

		local movement = mouseMovement
		mouseMovement = 0

		if not state.aim then
			currentTarget = nil
			ignoredTarget = nil
			previousMouseMovement = 0
			return
		end

		local camera = workspace.CurrentCamera
		if not camera then return end

		if ignoredTarget then
			local character = ignoredTarget.Character
			local part =
				character and getAimPart(character)

			if not part or not validTargetPart(part) then
				ignoredTarget = nil
			else
				local inside = targetInsideFov(part)

				if not inside then
					ignoredTarget = nil
				end
			end
		end

		if currentTarget then
			local combinedMovement =
				movement + previousMouseMovement * 0.5

			if combinedMovement >= mouseOverrideThreshold then
				breakLock()
				previousMouseMovement = 0
				return
			end
		end

		previousMouseMovement = movement

		if os.clock() < overrideUntil then
			return
		end

		if not validTargetPart(currentTarget) then
			currentTarget = findNearestTarget()
		end

		if not currentTarget then
			return
		end

		local origin = camera.CFrame.Position
		local targetPosition = currentTarget.Position

		if (targetPosition - origin).Magnitude < 0.01 then
			return
		end

		local lockedCamera =
			CFrame.lookAt(origin, targetPosition)

		camera.CFrame = lockedCamera

		if isFirstPerson() then
			local character = player.Character

			if character then
				local root =
					character:FindFirstChild("HumanoidRootPart")

				local humanoid =
					character:FindFirstChildOfClass("Humanoid")

				if root and humanoid
					and humanoid.Health > 0 then

					local look = lockedCamera.LookVector
					local flatLook =
						Vector3.new(look.X, 0, look.Z)

					if flatLook.Magnitude > 0.001 then
						local rootPosition = root.Position

						root.CFrame = CFrame.lookAt(
							rootPosition,
							rootPosition + flatLook.Unit
						)
					end
				end
			end
		end
	end
)

-- HOME DASHBOARD

local home = pages.Home

local banner = create("Frame", {
	Size = UDim2.new(1, 0, 0, 132),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0,
	ClipsDescendants = true
}, home)

corner(banner, 16)
-- Thin violet border; no bulky stripe across the top.
stroke(banner, C.ORANGE, 1.5, 0.06)

-- Aurora fade: rich violet -> pink -> midnight cyan.
local bannerGradient = create("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 34, 151)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(65, 27, 112)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 79, 105))
	}),
	Rotation = 12
}, banner)

-- Soft glass shine; kept behind the existing text and within rounded bounds.
local glassShine = create("Frame", {
	Name = "NeonGlassShine",
	Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(1, 0.65),
	BackgroundColor3 = Color3.fromRGB(192, 166, 255),
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0
}, banner)
create("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1)
	}),
	Rotation = 90
}, glassShine)

local gradientAnimation = TweenService:Create(
	bannerGradient,
	TweenInfo.new(
		5,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut,
		-1,
		true
	),
	{Rotation = -15}
)

gradientAnimation:Play()

-- WELCOME TEXT

local welcome = label(
	banner,
	"WELCOME TO CeeHub",
	20,
	C.WHITE,
	true
)

welcome.Position = UDim2.fromOffset(18, 21)
welcome.Size = UDim2.new(1, -110, 0, 34)

local subtitle = label(
	banner,
	"Universal Aimbot + ESP",
	11,
	C.MUTED
)

subtitle.Position = UDim2.fromOffset(19, 57)
subtitle.Size = UDim2.new(1, -115, 0, 23)

local credit = label(
	banner,
	"MADE BY CEEWORKS  •  VERSION 1.0",
	10,
	C.ORANGE_LIGHT,
	true
)

credit.Position = UDim2.fromOffset(19, 101)
credit.Size = UDim2.new(1, -110, 0, 19)

-- Original game branding is replaced with CeeHub's own neon badge.
local neonEmblem = label(banner, "✦", 31, C.ORANGE_LIGHT, true)
neonEmblem.AnchorPoint = Vector2.new(1, 0)
neonEmblem.Position = UDim2.new(1, -29, 0, 27)
neonEmblem.Size = UDim2.fromOffset(50, 42)
neonEmblem.TextXAlignment = Enum.TextXAlignment.Center

local neonEmblemLine = create("Frame", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -18, 0, 75),
	Size = UDim2.fromOffset(78, 2),
	BackgroundColor3 = C.CYAN,
	BorderSizePixel = 0
}, banner)
corner(neonEmblemLine, 2)
neonFade(neonEmblemLine, C.CYAN, C.ORANGE, C.PINK, 0)

local neonEdition = label(banner, "CeeWorks Studio", 9, C.ORANGE_LIGHT, true)
neonEdition.AnchorPoint = Vector2.new(1, 0)
neonEdition.Position = UDim2.new(1, -12, 0, 82)
neonEdition.Size = UDim2.fromOffset(91, 16)
neonEdition.TextXAlignment = Enum.TextXAlignment.Center

-- QUICK FEATURES

section(home, "Quick Features")

toggle(
	home,
	"Player ESP",
	"Highlight other players",
	"esp",
	refreshVisuals
)

toggle(
	home,
	"Lock On",
	"Automatic tracking with mouse override",
	"aim",
	function(enabled)
		if not enabled then
			currentTarget = nil
			ignoredTarget = nil
		end
	end
)

toggle(
	home,
	"FOV Circle",
	"Show targeting radius",
	"fov",
	updateFov
)

-- VISUALS

local visualsPage = pages.Visuals

section(visualsPage, "Player Visuals")

toggle(
	visualsPage,
	"Player ESP",
	"Orange highlights around players",
	"esp",
	refreshVisuals
)

toggle(
	visualsPage,
	"Player Names",
	"Display names above characters",
	"names",
	refreshVisuals
)

toggle(
	visualsPage,
	"Team Check",
	"Ignore players on your team",
	"teamCheck",
	function()
		refreshVisuals()
		currentTarget = nil
	end
)

-- TARGETING

local targeting = pages.Targeting

section(targeting, "Lock On Settings")

toggle(
	targeting,
	"Lock On",
	"Automatically track targets inside FOV",
	"aim",
	function(enabled)
		if not enabled then
			currentTarget = nil
			ignoredTarget = nil
		end
	end
)

toggle(
	targeting,
	"Show FOV Circle",
	"Display targeting circle",
	"fov",
	updateFov
)

slider(
	targeting,
	"FOV Radius",
	40,
	350,
	100,
	function(value)
		state.radius = value
		updateFov()
	end
)

slider(
	targeting,
	"Mouse Override Strength",
	15,
	120,
	15,
	function(value)
		mouseOverrideThreshold = value
	end
)

-- TARGET PART

local targetCard = create("Frame", {
	Size = UDim2.new(1, 0, 0, 90),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0
}, targeting)

corner(targetCard, 15)
stroke(targetCard, C.BORDER, 1.5, 0.12)

local targetLabel = label(
	targetCard,
	"Target Part",
	14,
	C.WHITE,
	true
)

targetLabel.Position = UDim2.fromOffset(17, 9)
targetLabel.Size = UDim2.new(1, -34, 0, 26)

local function targetButton(name, x)
	local button = create("TextButton", {
		Position = UDim2.new(x, 0, 0, 43),
		Size = UDim2.new(0.45, 0, 0, 33),
		BackgroundColor3 = C.BORDER,
		Text = name,
		TextColor3 = C.WHITE,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		AutoButtonColor = false
	}, targetCard)

	corner(button, 11)

	connect(button.MouseButton1Click, function()
		state.targetPart = name
		currentTarget = nil
	end)

	return button
end

local headButton = targetButton("Head", 0.035)
local torsoButton = targetButton("Torso", 0.515)

local function refreshTargetButtons()
	tween(headButton, {
		BackgroundColor3 =
			state.targetPart == "Head"
			and C.ORANGE_DARK
			or C.BORDER
	})

	tween(torsoButton, {
		BackgroundColor3 =
			state.targetPart == "Torso"
			and C.ORANGE_DARK
			or C.BORDER
	})
end

connect(headButton.MouseButton1Click, refreshTargetButtons)
connect(torsoButton.MouseButton1Click, refreshTargetButtons)

refreshTargetButtons()

-- PLAYERS

local playersPage = pages.Players

section(playersPage, "Player Profile")

local profile = create("Frame", {
	Size = UDim2.new(1, 0, 0, 115),
	BackgroundColor3 = C.CARD,
	BorderSizePixel = 0
}, playersPage)

corner(profile, 15)
stroke(profile, C.BORDER, 1.5, 0.12)

local avatar = create("ImageLabel", {
	Position = UDim2.fromOffset(17, 17),
	Size = UDim2.fromOffset(80, 80),
	BackgroundColor3 = C.ORANGE_DARK,
	BorderSizePixel = 0
}, profile)

corner(avatar, 13)
stroke(avatar, C.ORANGE, 1.5)

task.spawn(function()
	local success, image = pcall(function()
		return Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)
	end)

	if success and avatar.Parent then
		avatar.Image = image
	end
end)

local displayName = label(
	profile,
	player.DisplayName,
	18,
	C.WHITE,
	true
)

displayName.Position = UDim2.fromOffset(112, 16)
displayName.Size = UDim2.new(1, -130, 0, 29)

local username = label(
	profile,
	"@" .. player.Name,
	12,
	C.MUTED
)

username.Position = UDim2.fromOffset(112, 47)
username.Size = UDim2.new(1, -130, 0, 20)

local userId = label(
	profile,
	"User ID: " .. player.UserId,
	11,
	C.ORANGE_LIGHT
)

userId.Position = UDim2.fromOffset(112, 73)
userId.Size = UDim2.new(1, -130, 0, 20)

-- SETTINGS

local settingsPage = pages.Settings

section(settingsPage, "Interface Settings")

toggle(
	settingsPage,
	"Animations",
	"Enable smooth UI transitions",
	"animations"
)

-- DRAG WINDOW

local draggingWindow = false
local dragStart
local startPosition

connect(header.InputBegan, function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingWindow = true
		dragStart = input.Position
		startPosition = main.Position
	end
end)

connect(UIS.InputChanged, function(input)
	if draggingWindow and (
		input.UserInputType ==
			Enum.UserInputType.MouseMovement
			or input.UserInputType ==
			Enum.UserInputType.Touch
		) then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)

		shadow.Position = main.Position
		neonHalo.Position = main.Position
	end
end)

connect(UIS.InputEnded, function(input)
	if input.UserInputType ==
		Enum.UserInputType.MouseButton1
		or input.UserInputType ==
		Enum.UserInputType.Touch then

		draggingWindow = false
	end
end)

-- MINIMIZE

local minimized = false

connect(minimizeButton.MouseButton1Click, function()
	minimized = not minimized

	sidebar.Visible = not minimized
	holder.Visible = not minimized

	content.Position = minimized
		and UDim2.fromOffset(0, 0)
		or UDim2.fromOffset(SIDEBAR_WIDTH, 0)

	content.Size = minimized
		and UDim2.fromScale(1, 1)
		or UDim2.new(1, -SIDEBAR_WIDTH, 1, 0)

	heading.Text = minimized
		and "CeeHub"
		or string.upper(
			currentPage == "Home"
			and "Dashboard"
			or currentPage
		)

	minimizeButton.Text = minimized and "+" or "−"

	tween(main, {
		Size = minimized
			and UDim2.fromOffset(340, 65)
			or UDim2.fromOffset(
				WINDOW_WIDTH,
				WINDOW_HEIGHT
			)
	}, 0.3)

	tween(neonHalo, {
		Size = minimized
			and UDim2.fromOffset(346, 71)
			or UDim2.fromOffset(WINDOW_WIDTH + 6, WINDOW_HEIGHT + 6)
	}, 0.3)

	tween(shadow, {
		Size = minimized
			and UDim2.fromOffset(350, 75)
			or UDim2.fromOffset(
				WINDOW_WIDTH + 10,
				WINDOW_HEIGHT + 10
			)
	}, 0.3)
end)

-- CLEANUP

local function cleanup()
	if not running then return end

	running = false

	RunService:UnbindFromRenderStep(aimRenderName)

	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	for _, list in pairs(playerConnections) do
		for _, connection in ipairs(list) do
			connection:Disconnect()
		end
	end

	for target in pairs(playerVisuals) do
		clearVisual(target)
	end

	gradientAnimation:Cancel()

	if gui.Parent then
		gui:Destroy()
	end

	if _G.CeeHubCleanup == cleanup then
		_G.CeeHubCleanup = nil
	end
end

_G.CeeHubCleanup = cleanup

connect(closeButton.MouseButton1Click, cleanup)

connect(UIS.InputBegan, function(input, processed)
	if processed then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		main.Visible = not main.Visible
		shadow.Visible = main.Visible
		neonHalo.Visible = main.Visible
	end
end)

-- STARTUP

switchPage("Home")
updateFov()

print(
	"[CeeHub] v1.0 loaded - Made by CeeWorks"
)
