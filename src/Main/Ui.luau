local HttpService = game:GetService("HttpService") :: HttpService

local pluginRoot = script:FindFirstAncestor("PluginRoot")
local Constants = require(pluginRoot.Constants)

local Ui = {}

local SERVE_URL = `http://localhost:{Constants.ServePort}`

local function pingServer(): (boolean, string?)
	local ok, err = pcall(function()
		HttpService:RequestAsync({
			Method = "GET",
			Url = `{SERVE_URL}/__ping`,
		})
	end)

	if ok then
		return true
	end

	local msg = tostring(err)
	if msg:find("Http requests are not enabled") then
		return false,
			"HTTP requests aren't enabled.\n\nOpen Game Settings → Security → toggle on \"Allow HTTP Requests\", then try again."
	end
	return false,
		`The lune server isn't reachable on port {Constants.ServePort}.\n\n`
		.. `Open a terminal in the project folder and run:\n    lune run serve\n\n`
		.. `Keep that terminal open while using the plugin.\n\n(Underlying error: {msg})`
end

local function parseAssetInput(raw: string): (number?, string?)
	local match = raw:match("(%d+)")
	if not match then
		return nil,
			"Couldn't find an asset ID in that input.\nPaste a numeric asset ID (e.g. 7228490061) or a roblox.com URL containing one."
	end
	return tonumber(match)
end

local function applyTheme(
	root: Frame,
	statusFrame: Frame,
	textNodes: { TextLabel },
	input: TextBox,
	runButton: TextButton
)
	local theme = settings().Studio.Theme
	root.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)

	local textColor = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	for _, node in textNodes do
		node.TextColor3 = textColor
	end

	input.TextColor3 = textColor
	input.PlaceholderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.DimmedText)
	input.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBackground)
	input.BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.InputFieldBorder)

	runButton.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
	runButton.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.ButtonText)
	runButton.BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border)

	statusFrame.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.TableItem)
	statusFrame.BorderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border)
end

function Ui.build(plugin: Plugin, runJailbreak: (input: string | number) -> { Instance })
	local toolbar = plugin:CreateToolbar("Asset Jailbreak")
	local toolbarButton = toolbar:CreateButton(
		"AssetJailbreakOpen",
		"Open the Asset Jailbreak panel",
		"",
		"Jailbreak"
	)
	toolbarButton.ClickableWhenViewportHidden = true

	local widget = plugin:CreateDockWidgetPluginGui(
		"AssetJailbreak",
		DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 420, 560, 340, 420)
	)
	widget.Title = "Asset Jailbreak"
	widget.Name = "AssetJailbreak"
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = widget

	local rootPad = Instance.new("UIPadding")
	rootPad.PaddingTop = UDim.new(0, 12)
	rootPad.PaddingBottom = UDim.new(0, 12)
	rootPad.PaddingLeft = UDim.new(0, 12)
	rootPad.PaddingRight = UDim.new(0, 12)
	rootPad.Parent = scroll

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)
	layout.Parent = scroll

	local textNodes: { TextLabel } = {}
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	local function makeLabel(text: string, isHeader: boolean?): TextLabel
		local label = Instance.new("TextLabel")
		label.AutomaticSize = Enum.AutomaticSize.Y
		label.Size = UDim2.new(1, 0, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextWrapped = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextYAlignment = Enum.TextYAlignment.Top
		label.Font = if isHeader then Enum.Font.GothamBold else Enum.Font.Gotham
		label.TextSize = if isHeader then 15 else 13
		label.LayoutOrder = nextOrder()
		label.Parent = scroll
		table.insert(textNodes, label)
		return label
	end

	makeLabel("Asset Jailbreak", true)
	makeLabel(
		"Paste an asset ID or a roblox.com asset URL below and click Run. "
			.. "The plugin asks the lune server to download the asset locally, then inserts it into Workspace as an editable mesh / image."
	)

	makeLabel("How to use", true)
	makeLabel(
		"1. In a terminal, from the project folder, run:  lune run serve\n"
			.. "   (keep that terminal open while using the plugin)\n"
			.. "2. Enable HTTP requests:  Game Settings → Security → Allow HTTP Requests\n"
			.. "3. Paste an asset ID or a roblox.com URL into the box below, then click Run.\n"
			.. "4. Result is inserted into Workspace and selected for you.\n\n"
			.. "Alternative: in Studio's command bar you can also call  _G.jailbreak(<id-or-url>)."
	)

	local input = Instance.new("TextBox")
	input.Size = UDim2.new(1, 0, 0, 30)
	input.PlaceholderText = "asset id or roblox.com URL"
	input.ClearTextOnFocus = false
	input.Text = ""
	input.TextXAlignment = Enum.TextXAlignment.Left
	input.Font = Enum.Font.Code
	input.TextSize = 14
	input.LayoutOrder = nextOrder()
	input.Parent = scroll
	local inputPad = Instance.new("UIPadding")
	inputPad.PaddingLeft = UDim.new(0, 6)
	inputPad.PaddingRight = UDim.new(0, 6)
	inputPad.Parent = input

	local runButton = Instance.new("TextButton")
	runButton.Size = UDim2.new(1, 0, 0, 32)
	runButton.Text = "Run"
	runButton.Font = Enum.Font.GothamMedium
	runButton.TextSize = 14
	runButton.AutoButtonColor = true
	runButton.LayoutOrder = nextOrder()
	runButton.Parent = scroll

	local statusFrame = Instance.new("Frame")
	statusFrame.Size = UDim2.new(1, 0, 0, 0)
	statusFrame.AutomaticSize = Enum.AutomaticSize.Y
	statusFrame.LayoutOrder = nextOrder()
	statusFrame.Parent = scroll
	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 4)
	statusCorner.Parent = statusFrame
	local statusPad = Instance.new("UIPadding")
	statusPad.PaddingTop = UDim.new(0, 6)
	statusPad.PaddingBottom = UDim.new(0, 6)
	statusPad.PaddingLeft = UDim.new(0, 8)
	statusPad.PaddingRight = UDim.new(0, 8)
	statusPad.Parent = statusFrame

	local statusLabel = Instance.new("TextLabel")
	statusLabel.AutomaticSize = Enum.AutomaticSize.Y
	statusLabel.Size = UDim2.new(1, 0, 0, 0)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Idle. Paste an asset and click Run."
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusLabel.Font = Enum.Font.Code
	statusLabel.TextSize = 12
	statusLabel.Parent = statusFrame

	local function setStatus(kind: "info" | "ok" | "error", message: string)
		local color = if kind == "ok"
			then Color3.fromRGB(120, 200, 120)
			elseif kind == "error" then Color3.fromRGB(230, 110, 110)
			else settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		statusLabel.TextColor3 = color
		statusLabel.Text = message
	end

	local running = false
	local function run()
		if running then
			return
		end
		running = true
		runButton.Active = false
		runButton.AutoButtonColor = false
		runButton.Text = "Working..."

		setStatus("info", "Checking lune server...")

		local raw = input.Text
		if raw:match("^%s*$") then
			setStatus("error", "Input is empty. Paste an asset ID or URL.")
		else
			local serverOk, serverErr = pingServer()
			if not serverOk then
				setStatus("error", serverErr or "Unknown server error.")
			else
				local id, parseErr = parseAssetInput(raw)
				if not id then
					setStatus("error", parseErr :: string)
				else
					setStatus("info", `Server ok. Jailbreaking asset {id}...`)
					local ok, result = pcall(runJailbreak, id :: number)
					if ok then
						local n = if type(result) == "table" then #result else 0
						setStatus("ok", `Done. Inserted {n} instance(s) into Workspace and selected them.`)
					else
						setStatus("error", `Jailbreak failed: {tostring(result)}`)
					end
				end
			end
		end

		running = false
		runButton.Active = true
		runButton.AutoButtonColor = true
		runButton.Text = "Run"
	end

	runButton.Activated:Connect(run)
	input.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			run()
		end
	end)

	toolbarButton.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end)
	widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		toolbarButton:SetActive(widget.Enabled)
	end)
	toolbarButton:SetActive(widget.Enabled)

	local function refreshTheme()
		applyTheme(scroll :: any, statusFrame, textNodes, input, runButton)
	end
	refreshTheme()
	settings().Studio.ThemeChanged:Connect(refreshTheme)
end

return Ui
