local PickpocketTracker, PPT = ...;

PPT.PickpocketTrackerConfig = {};
PPT.PickpocketTrackerConfig.panel = CreateFrame("Frame", "PickpocketTrackerConfig", UIParent);
PPT.PickpocketTrackerConfig.panel.name = "PickpocketTracker";
InterfaceOptions_AddCategory(PPT.PickpocketTrackerConfig.panel);
PPT.PickpocketTrackerConfig.panel:Hide();

local configFrame;
local numericBoxWindowWidth;
local checkboxToggleAutolootButton;
local checkboxToggleTrackButton;

local checkboxToggleFrameMoney;
local radioButtonShowAllMoney;
local radioButtonMoney;
local radioButtonMoneyOverall;

local marginAll = 2;
local optionsRowConfig = {
	margin = {
		top = marginAll,
		bottom = marginAll,
		left = marginAll,
		right = marginAll
	}
}

local numericBoxPadding = {};
numericBoxPadding.all = nil;
numericBoxPadding.top = nil;
numericBoxPadding.bottom = nil;
numericBoxPadding.left = nil;
numericBoxPadding.right = nil;

local numericBoxMargin = {};
numericBoxMargin.all = nil;
numericBoxMargin.top = nil;
numericBoxMargin.bottom = nil;
numericBoxMargin.left = nil;
numericBoxMargin.right = nil;

--local fontFamily;
--local fontSize;
--local fontColor;

local dropdownWindowTexture;
local colorPickerButtonBackdrop;
local colorPickerButtonHighlight;
local colorPickerWindowBackdrop;
local colorPickerBackdropBorder;	

local configRow1, configRow2, configRow3, configRow4, configRow5, configRow6, configRow7, configRow8, configRow9, configRow10, configRow11, configRow12, configRow13, configRow14;

local function NumericValidator(self)
	local value = self:GetNumber();
	local UiWindow = PPT_DB.AddonInterface.UiWindow;
	local isValid = false;
	local minimum, maximum;
	
	if (value == nil) then 
		STDUI_PPT:MarkAsValid(self, isValid);
		return false
	end

	if (self == numericBoxWindowWidth) then
		minimum = UiWindow.widthSliderMin;
		maximum = UiWindow.widthSliderMax;
	elseif (self == numericBoxWindowHeight) then
		minimum = UiWindow.heightSliderMin;
		maximum = UiWindow.heightSliderMax;
	end
		
	if (minimum ~= nil) and (maximum ~= nil) then
		if (value >= minimum) and (value <= maximum) then
			self.value = value;
			isValid = true;
		end
	end
	
	STDUI_PPT:MarkAsValid(self, isValid);
	return isValid;
end

function PPT:CreateDropdownPair(name, path)
	return {text = name, value = path};
end

function PPT:BuildPickpocketTrackerConfig()
	configFrame = STDUI_PPT:Frame(PPT.PickpocketTrackerConfig.panel, 600, 800);
	configFrame:SetPoint('TOPLEFT');
	STDUI_PPT:EasyLayout(
		configFrame,
		{
			gutter  = 0,
			columns = 7,
			padding = 
			{
				top    = 5,
				right  = 10,
				left   = 10,
				bottom = 0,
			}
		}
	);
	
	local UiWindow = PPT_DB.AddonInterface.UiWindow;
	
	local fontColor = {.99, .82, 0, .99};
	local labelBlank = STDUI_PPT:FontString(configFrame, '');
	local optionsLabelConfig = STDUI_PPT.Util.tableMerge(optionsRowConfig, {margin = {top = 24}});
	
	--row 1
	local labelAddonName = STDUI_PPT:Label(configFrame, "Pickpocket Tracker Options", STDUI_PPT.config.font.size + 4);
	labelAddonName:SetTextColor(unpack(fontColor));
	
	configRow1 = configFrame:AddRow(optionsRowConfig);
	configRow1:AddElements(labelAddonName, {column = 'even'});
	
	--row 2
	PPT.sliderWindowWidth = STDUI_PPT:SliderWithBox(configFrame, 100, 20, PPT_DB.UiWindow.width, false, UiWindow.widthSliderMin, UiWindow.widthSliderMax);
	PPT.sliderWindowHeight = STDUI_PPT:SliderWithBox(configFrame, 100, 20, PPT_DB.UiWindow.height, false, UiWindow.heightSliderMin, UiWindow.heightSliderMax);
	PPT.sliderWindowWidth.editBox:SetWidth(100);
	PPT.sliderWindowHeight.editBox:SetWidth(100);
	PPT.sliderWindowWidth:SetPrecision(2);
	PPT.sliderWindowHeight:SetPrecision(2);
	PPT.sliderWindowWidth:SetValueStep(.01);
	PPT.sliderWindowHeight:SetValueStep(.01);
	
	local labelWindowWidth = STDUI_PPT:AddLabel(configFrame, PPT.sliderWindowWidth, "Window Width");
	local labelWindowHeight = STDUI_PPT:AddLabel(configFrame, PPT.sliderWindowHeight, "Window Height");
	labelWindowWidth:SetTextColor(unpack(fontColor));
	labelWindowHeight:SetTextColor(unpack(fontColor));
	
	configRow2 = configFrame:AddRow(optionsLabelConfig);
	configRow2:AddElement(PPT.sliderWindowWidth, {column = 3, margin = {bottom = 20}});
	configRow2:AddElement(labelBlank, {column = 1});
	configRow2:AddElement(PPT.sliderWindowHeight, {column = 3});
	
	--row 3
	PPT.checkboxToggleAlwaysTracking = STDUI_PPT:Checkbox(configFrame, "Always Track Gold", 20, 20);
	checkboxToggleTrackButton = STDUI_PPT:Checkbox(configFrame, "Hide Track Gold Button", 20, 20);
	PPT.checkboxToggleAlwaysTracking:SetChecked(UiWindow.isAlwaysTracking, true);	
	checkboxToggleTrackButton:SetChecked(UiWindow.isButtonTrackHidden, true);
	
	configRow3 = configFrame:AddRow(optionsLabelConfig);
	configRow3:AddElements(PPT.checkboxToggleAlwaysTracking, checkboxToggleTrackButton, {column = 2});
	
	--row 4
	checkboxToggleAutolootButton = STDUI_PPT:Checkbox(configFrame, "Hide Auto Loot Button", 20, 20);
	checkboxToggleAutolootButton:SetChecked(UiWindow.isButtonAutolootHidden, true);
	
	configRow4 = configFrame:AddRow(optionsRowConfig);
	configRow4:AddElement(checkboxToggleAutolootButton);
	
	--row 5
	STDUI_PPT:RadioGroup("radioGroupMoneyLabels");
	radioButtonShowAllMoney = STDUI_PPT:Radio(configFrame, "Show Session and Overall Gold", "radioGroupMoneyLabels", 40, 20);
	radioButtonMoney = STDUI_PPT:Radio(configFrame, "Hide Overall Gold", "radioGroupMoneyLabels", 40, 20);
	radioButtonMoneyOverall = STDUI_PPT:Radio(configFrame, "Hide Session Gold", "radioGroupMoneyLabels", 40, 20);
	radioButtonShowAllMoney:SetValue("showAll");
	radioButtonMoney:SetValue("hideMoneyOverall");
	radioButtonMoneyOverall:SetValue("hideMoney");
	
	configRow5 = configFrame:AddRow(optionsRowConfig);
	configRow5:AddElement(radioButtonShowAllMoney, {column = 3});
	configRow5:AddElements(radioButtonMoney, radioButtonMoneyOverall, {column = 2});
	STDUI_PPT:SetRadioGroupValue("radioGroupMoneyLabels", UiWindow.radioGroupMoneyValue);
	
	--row 6
	local labelPadding = STDUI_PPT:Label(configFrame, "Window Padding", STDUI_PPT.config.font.size + 2);
	labelPadding:SetTextColor(unpack(fontColor));
	
	configRow6 = configFrame:AddRow(optionsRowConfig);
	configRow6:AddElement(labelPadding, {margin = {top = 8}});
	
	--row 7
	local padding = PPT_DB.UiWindow.layout.padding;	
	numericBoxPadding.all = STDUI_PPT:NumericBox(configFrame, 40, 16, 0);
	numericBoxPadding.top = STDUI_PPT:NumericBox(configFrame, 40, 16, padding.top);
	numericBoxPadding.bottom = STDUI_PPT:NumericBox(configFrame, 40, 16, padding.bottom);
	numericBoxPadding.left = STDUI_PPT:NumericBox(configFrame, 40, 16, padding.left);
	numericBoxPadding.right = STDUI_PPT:NumericBox(configFrame, 40, 16, padding.right);
	
	for _, value in pairs(numericBoxPadding) do
		value:SetMinValue(0);
		value:SetMaxValue(50);
	end
	
	local labelsPadding = {}
	labelsPadding.all = STDUI_PPT:AddLabel(configFrame, numericBoxPadding.all, "All");
	labelsPadding.top = STDUI_PPT:AddLabel(configFrame, numericBoxPadding.top, "Top");
	labelsPadding.bottom = STDUI_PPT:AddLabel(configFrame, numericBoxPadding.bottom, "Bottom");
	labelsPadding.left = STDUI_PPT:AddLabel(configFrame, numericBoxPadding.left, "Left");
	labelsPadding.right = STDUI_PPT:AddLabel(configFrame, numericBoxPadding.right, "Right");
	
	for _, value in pairs(labelsPadding) do
		value:SetTextColor(unpack(fontColor));
	end
	
	configRow7 = configFrame:AddRow(optionsLabelConfig);
	configRow7:AddElement(numericBoxPadding.all, {column = 1});
	configRow7:AddElement(labelBlank, {column = 1});
	configRow7:AddElements(numericBoxPadding.top, numericBoxPadding.bottom, numericBoxPadding.left, numericBoxPadding.right, {column = 1});
	
	--row 8
	local labelMargin = STDUI_PPT:Label(configFrame, "Widget Margins", STDUI_PPT.config.font.size + 2);
	labelMargin:SetTextColor(labelWindowWidth:GetTextColor());
	
	configRow8 = configFrame:AddRow(optionsRowConfig);
	configRow8:AddElement(labelMargin, {margin = {top = 8}});
	
	--row 9
	local margin = PPT_DB.UiWindow.row.margin;
	numericBoxMargin.all = STDUI_PPT:NumericBox(configFrame, 40, 16, 0);
	numericBoxMargin.top = STDUI_PPT:NumericBox(configFrame, 40, 16, margin.top);
	numericBoxMargin.bottom = STDUI_PPT:NumericBox(configFrame, 40, 16, margin.bottom);
	numericBoxMargin.left = STDUI_PPT:NumericBox(configFrame, 40, 16, margin.left);
	numericBoxMargin.right = STDUI_PPT:NumericBox(configFrame, 40, 16, margin.right);
	
	for _, value in pairs(numericBoxMargin) do
		value:SetMinValue(0);
		value:SetMaxValue(50);
	end
	
	local labelsMargin = {}
	labelsMargin.all = STDUI_PPT:AddLabel(configFrame, numericBoxMargin.all, "All");
	labelsMargin.top = STDUI_PPT:AddLabel(configFrame, numericBoxMargin.top, "Top");
	labelsMargin.bottom = STDUI_PPT:AddLabel(configFrame, numericBoxMargin.bottom, "Bottom");
	labelsMargin.left = STDUI_PPT:AddLabel(configFrame, numericBoxMargin.left, "Left");
	labelsMargin.right = STDUI_PPT:AddLabel(configFrame, numericBoxMargin.right, "Right");
	
	for _, value in pairs(labelsMargin) do
		value:SetTextColor(unpack(fontColor));
	end
	
	configRow9 = configFrame:AddRow(optionsLabelConfig);
	configRow9:AddElement(numericBoxMargin.all, {column = 1});
	configRow9:AddElement(labelBlank, {column = 1});
	configRow9:AddElements(numericBoxMargin.top, numericBoxMargin.bottom, numericBoxMargin.left, numericBoxMargin.right, {column = 1});
	
	--row 10
	local labelWindowBackdrop = STDUI_PPT:Label(configFrame, "Backdrop and Colors", STDUI_PPT.config.font.size + 2);
	labelWindowBackdrop:SetTextColor(unpack(fontColor));
	
	configRow10 = configFrame:AddRow(optionsRowConfig);
	configRow10:AddElements(labelWindowBackdrop, {column = 'even', margin = {top = 8}});
	
	--row 11
	local backgroundTextureTable = {};
	for bg, path in pairs(MEDIA_PPT.MediaTable.background) do
		table.insert(backgroundTextureTable, PPT:CreateDropdownPair(bg, path));
	end
	
	dropdownWindowTexture = STDUI_PPT:Dropdown(configFrame, 100, 20, backgroundTextureTable, PPT_DB.STDUI_PPT.config.backdrop.texture);
	dropdownWindowTexture:SetPlaceholder("Select a backdrop");
	colorPickerWindowBackdrop = STDUI_PPT:ColorInput(configFrame, "Window Color", 100, 20, PPT_DB.STDUI_PPT.config.backdrop.panel);
	colorPickerBackdropBorder = STDUI_PPT:ColorInput(configFrame, "Border Color", 100, 20, PPT_DB.STDUI_PPT.config.backdrop.border);
	local labelWindowTexture = STDUI_PPT:AddLabel(configFrame, dropdownWindowTexture, "Window");
	labelWindowTexture:SetTextColor(unpack(fontColor));
	
	configRow11 = configFrame:AddRow(optionsLabelConfig);
	configRow11:AddElement(dropdownWindowTexture, {column = 2});
	configRow11:AddElement(labelBlank, {column = 1});
	configRow11:AddElement(colorPickerWindowBackdrop, {column = 2});
	configRow11:AddElement(colorPickerBackdropBorder, {column = 2});
	
	--row 12
	colorPickerButtonBackdrop = STDUI_PPT:ColorInput(configFrame, "Button Color", 100, 20, PPT_DB.STDUI_PPT.config.backdrop.button);
	colorPickerButtonHighlight = STDUI_PPT:ColorInput(configFrame, "Button Highlight Color", 100, 20, PPT_DB.STDUI_PPT.config.highlight.color);
	local labelButtonBackdrop = STDUI_PPT:AddLabel(configFrame, colorPickerButtonBackdrop, "Button Colors");
	labelButtonBackdrop:SetTextColor(unpack(fontColor));
	
	configRow12 = configFrame:AddRow(optionsLabelConfig);
	configRow12:AddElement(colorPickerButtonBackdrop, {column = 2});
	configRow12:AddElement(colorPickerButtonHighlight, {column = 2});
	
	--[[		
		bg color 32bit
			transparent w/out focus
	--]]
	
	colorPickerButtonHighlight.OnValueChanged = function(_, rgba)
		PPT_DB.STDUI_PPT.config.highlight.color = rgba;
		STDUI_PPT.config.highlight.color = rgba;
		
		PPT.UpdateBackdrop();
	end
	
	colorPickerButtonBackdrop.OnValueChanged = function(_, rgba)	
		PPT_DB.STDUI_PPT.config.backdrop.button = rgba;
		STDUI_PPT.config.backdrop.button = rgba;
		
		PPT.UpdateBackdrop();
	end
	
	colorPickerBackdropBorder.OnValueChanged = function(_, rgba)	
		PPT_DB.STDUI_PPT.config.backdrop.border = rgba;
		STDUI_PPT.config.backdrop.border = rgba;
		
		for x, y in pairs(PPT.buttonTrack.origBackdropBorderColor) do
			print(x, ' ', y);
		end
		print(STDUI_PPT.Util.roundPrecision(rgba.r, 3), STDUI_PPT.Util.roundPrecision(rgba.g, 3), STDUI_PPT.Util.roundPrecision(rgba.b, 3), STDUI_PPT.Util.roundPrecision(rgba.a, 3));
		PPT.buttonTrack.origBackdropBorderColor = rgba;
		
		PPT.UpdateBackdrop();
	end
	
	colorPickerWindowBackdrop.OnValueChanged = function(_, rgba)	
		PPT_DB.STDUI_PPT.config.backdrop.panel = rgba;
		STDUI_PPT.config.backdrop.panel = rgba;
		
		PPT.UpdateBackdrop();
	end
	
	dropdownWindowTexture.OnValueChanged = function(text, value)
		PPT_DB.STDUI_PPT.config.backdrop.texture = PPT:CreateDropdownPair(text, value);		
		STDUI_PPT.config.backdrop.texture = PPT_DB.STDUI_PPT.config.backdrop.texture.value;
		
		PPT:UpdateBackdrop();
	end
	
	local reloadConfirm;
	local buttons = {
		ok = {
			text = "OK",
			onClick = function(button)
				button.window:Hide();
				C_UI.Reload();
			end
		},
		later = {
			text = "Later",
			onClick = function(button)
				button.window:Hide();
			end
		},
	}	
	
	checkboxToggleTrackButton.OnValueChanged = function(_, state)
		UiWindow.isButtonTrackHidden = state;
		
		PPT:SetVisibility(PPT.buttonTrack, not UiWindow.isButtonTrackHidden);
		PPT:UpdateWindowDimension_minimum();
	end
	
	PPT.checkboxToggleAlwaysTracking.OnValueChanged = function(_, state)
		UiWindow.isAlwaysTracking = state;
		
		if state then
			if (PPT.buttonTrack:GetText() == "Track Gold") then
				PPT.buttonTrack:Click();
			end
			
			checkboxToggleTrackButton:Enable();
		else
			checkboxToggleTrackButton:SetChecked(false);
			checkboxToggleTrackButton:Disable();
		end
	end
	
	checkboxToggleAutolootButton.OnValueChanged = function(_, state)
		UiWindow.isButtonAutolootHidden = state;
		PPT:SetVisibility(PPT.buttonAutoloot, not UiWindow.isButtonAutolootHidden);
		
		PPT:UpdateWindowDimension_minimum();	
	end
	
	STDUI_PPT:OnRadioGroupValueChanged("radioGroupMoneyLabels", function(value) 
		UiWindow.radioGroupMoneyValue = value;
		
		local visibleMoney, visibleMoneyOverall = PPT:GetRadioVisibility();
		PPT:SetVisibility(PPT.labelMoney, not visibleMoney);
		PPT:SetVisibility(PPT.labelMoneyOverall, not visibleMoneyOverall);

		PPT:UpdateWindowDimension_minimum();
	end);
	
	PPT.sliderWindowWidth.OnValueChanged = function(_, value)
		PPT_DB.UiWindow.width = value;
		PPT.window:SetWidth(value);
		PPT:UpdateWindowDimension_minimum();
	end
	PPT.sliderWindowHeight.OnValueChanged = function(_, value)
		PPT_DB.UiWindow.height = value;
		PPT.window:SetHeight(value);
		PPT:UpdateWindowDimension_minimum();
	end

	--create OnValueChanged events for all padding and margin inputs
	for i=1, 2 do
		local currentTable;
		local currentType;
		local currentConfig;
		
		if (i==1) then
			currentTable = numericBoxPadding;
			currentType = "padding";
			currentConfig = "layout";
		elseif (i==2) then
			currentTable = numericBoxMargin;
			currentType = "margin";
			currentConfig = "row";
		end
		
		local directions = {"all", "top", "bottom", "left", "right"};
		
		for k=1, PPT:GetTableLength(directions) do
			if (directions[k] == directions[1]) then
				currentTable[directions[k]].OnValueChanged = function(_, newValue)
					for _, v in pairs(currentTable) do
						if (v ~= currentTable["all"]) then v:SetValue(newValue); end
					end
				end
			else
				currentTable[directions[k]].OnValueChanged = function(_, newValue)
					PPT_DB.UiWindow[currentConfig][currentType][directions[k]] = newValue;					
					PPT:UpdateWindowDimension_minimum();
				end
			end
		end
	end
	
	configFrame:DoLayout();
end

local function GetLargestWidthHeight()
	local largestWidth_raw, largestHeight_raw = PPT:ResizeToFitPickpocketTrackerFrame();
	local largestWidth = STDUI_PPT.Util.roundPrecision(largestWidth_raw, 2);
	local largestHeight = STDUI_PPT.Util.roundPrecision(largestHeight_raw, 2);
	
	return largestWidth, largestHeight;
end

function PPT:UpdateWindowDimension_minimum()
	local largestWidth, largestHeight = GetLargestWidthHeight();
	local UiWindow = PPT_DB.AddonInterface.UiWindow;
	
	UiWindow.widthSliderMin = largestWidth;
	UiWindow.heightSliderMin = largestHeight;
	
	PPT.sliderWindowWidth:SetMinMaxValues(largestWidth, UiWindow.widthSliderMax);
	PPT.sliderWindowHeight:SetMinMaxValues(largestHeight, UiWindow.heightSliderMax);
	
	--safeguard if PPT.window is too small
	if (largestWidth > STDUI_PPT.Util.roundPrecision(PPT.window:GetWidth(), 2)) then PPT.window:SetWidth(largestWidth); end
	if (largestHeight > STDUI_PPT.Util.roundPrecision(PPT.window:GetHeight(), 2)) then PPT.window:SetHeight(largestHeight); end
	
	--adjust rows for new margins
	for _, row in pairs(PPT.window.rows) do
		--individual rows
		row.config.margin = PPT_DB.UiWindow.row.margin;
	end
	
	STDUI_PPT:EasyLayout(PPT.window, PPT_DB.UiWindow.layout);
	PPT.window:DoLayout();
	
	PPT:UpdateRowOffsets(PPT.candidates);
end

--function PickpocketTrackerConfig_OnLoad()	
	-- STDUI_PPT:SetRadioGroupValue("radioGroupMoneyLabels", PPT_DB.AddonInterface.UiWindow.radioGroupMoneyValue);
	-- print("config loaded: ", PPT_DB.AddonInterface.UiWindow.radioGroupMoneyValue);
--end

--PPT.PickpocketTrackerConfig.panel:SetScript("OnShow", PickpocketTrackerConfig_OnLoad);