local PickpocketTracker, PPT = ...;

STDUI_PPT = LibStub("StdUi"):NewInstance();
MEDIA_PPT = LibStub("LibSharedMedia-3.0");

local fontName, fontSize = GameFontNormal:GetFont();
--local colorDefault = {r=1, g=1, b=1, a=1};
-- STDUI_PPT.config = {
	-- font        = {
		-- family 	= fontName,
		-- size      = fontSize,
		-- titleSize = largeFontSize,
		-- effect    = 'NONE',
		-- strata    = 'OVERLAY',
		-- color     = {
			-- normal   = { r = 1, g = 1, b = 1, a = 1 },
			-- disabled = { r = .55, g = .55, b = .55, a = 1 },
			-- header   = { r = 1, g = .9, b = 0, a = 1 },
		-- }
	-- },

	-- backdrop    = {
		-- texture        = [[Interface\Buttons\WHITE8X8]],
		-- panel          = { r = .2, g = .2, b = .2, a = 1 },
		-- slider         = { r = .15, g = .15, b = .15, a = 1 },

		-- highlight      = { r = .4, g = .4, b = 0, a = .5 },
		-- button         = { r = .2, g = .2, b = .2, a = 1 },
		-- buttonDisabled = { r = .15, g = .15, b = .15, a = 1 },

		-- border         = { r = .059, g = .059, b = .059, a = 1 },
		-- borderDisabled = { r = .4, g = .4, b = .4, a = 1 }
	-- },

	-- progressBar = {
		-- color = { r = 1, g = 0.9, b = 0, a = 0.5 },
	-- },

	-- highlight   = {
		-- color = { r = 1, g = 0.9, b = 0, a = 0.4 },
		-- blank = { r = 0, g = 0, b = 0, a = 0 }
	-- },

	-- dialog      = {
		-- width  = 400,
		-- height = 100,
		-- button = {
			-- width  = 100,
			-- height = 20,
			-- margin = 5
		-- }
	-- },

	-- tooltip     = {
		-- padding = 10
	-- }
-- };

PPT.window = STDUI_PPT:Window(UIParent, 200, 200);
PPT.window:SetPoint('BOTTOMLEFT');
PPT.window.closeBtn:Hide();

-- local index = {};
-- local mt = {
	-- __index = function(t, k)
		-- print("access to element " .. tostring(k));
		-- return t[index][k]
	-- end,
	
	-- __newindex = function(t, k, v)
		-- print("update of element " .. tostring(k) .. " to " .. tostring(v));
		-- t[index][k] = v;
	-- end
-- }

-- function PPT:Track(t)
	-- local proxy = {};
	-- proxy[index] = t;
	
	-- setmetatable(proxy, mt);
	-- return proxy
-- end

--PPT.rowConfig = PPT:Track(PPT.rowConfig);

local tooltipMoney;
local tooltipMoneyOverall;

local windowRow1, windowRow2, windowRow3, windowRow4, windowRow5;

local moneySessionCount = 0;
local loaded = false;
local tracking = false;
local autoloot = 0;
PPT.candidates = {};

--methods
function PPT:MoneyLootStringToValue(msg)
	local split = {};
	local gain = 0;
		
	--You loot 3 Silver, 24 Copper
	-- >copper = 324
	for value in string.gmatch(msg, '%d+%s%a+') do
		tinsert(split, value);
	end
	
	for key, value in pairs(split) do
		if string.find(value, "Gold") then
			gain = gain + (strsplit("Gold", value) * 100 * 100);
		end
		
		if string.find(value, "Silver") then
			gain = gain + (strsplit("Silver", value) * 100);
		end
		
		if string.find(value, "Copper") then
			gain = gain + strsplit("Copper", value);
		end
	end
	
	return gain;
end

function PPT:GetTableLength(theTable)
	local count = 0;
	
	if (theTable ~= nil) then
		for key, _ in pairs(theTable) do
			count = count + 1;
		end
	end
	
	return count;
end

local function GetLargestFrameSize(dimension, sumDimension, candidates)
	local largest = 0;
	local current = 0;
	local sum = 0;
	local visibleCandidates = PPT:GetTableLength(candidates);
	
	for _, candidate in pairs(candidates) do
		if candidate:IsVisible() and (candidate ~= nil) then
			if (dimension == "width") then
				current = candidate:GetWidth();
			elseif (dimension == "height") then
				local parent = candidate:GetParent();				
				current = parent:GetHeight();
			end		
		
			if sumDimension then sum = sum + current; end
			if (current > largest) then largest = current; end
		else
			visibleCandidates = visibleCandidates - 1;
		end
	end
	
	if sumDimension then return sum, visibleCandidates;
	else return largest, visibleCandidates; end
end

local function GetTotalPadding(dimension, framePadding)
	local padding = 0;
	
	if (framePadding ~= nil) then
		if (dimension == "width") then
			return framePadding.left + framePadding.right;
		elseif (dimension == "height") then
			return framePadding.top + framePadding.bottom;
		end
	end
	
	return padding;
end

local function GetTotalMargin(dimension, widgetMargin, visibleCandidates)
	local margin = 0;
	
	if (dimension == "width") then
		margin = widgetMargin.left + widgetMargin.right;
	elseif (dimension == "height") then
		margin = (widgetMargin.top * visibleCandidates) + (widgetMargin.bottom * visibleCandidates);
	end
	
	return margin;
end

function PPT:GetFrameMinimumSize(dimension, sumDimension, candidates, framePadding, widgetMargin)
	local size, visibleCandidates = GetLargestFrameSize(dimension, sumDimension, candidates);
	local padding = GetTotalPadding(dimension, framePadding);
	local margin = GetTotalMargin(dimension, widgetMargin, visibleCandidates)
		
	local total = (size + padding + margin);
	return total;
end

local function SearchRowOrder(rowOrder, name)
	local length = PPT:GetTableLength(rowOrder);
	local indexCurrent, indexNext;
	
	for index, pair in pairs(rowOrder) do
		--find index for name
		if (pair[1] == name) then
			indexCurrent = index;
			if (rowOrder[indexCurrent + 1] ~= nil) then				
				indexNext = indexCurrent + 1;
			end
			
			return indexCurrent, indexNext;
		end
	end

	return nil;
end

function PPT:GetRadioVisibility()
	local UiWindow = PPT_DB.AddonInterface.UiWindow;
	local var1, var2;
	
	if (UiWindow.radioGroupMoneyValue == "showAll") then
		var1 = false; --show money
		var2 = false; --show moneyOverall
	elseif (UiWindow.radioGroupMoneyValue == "hideMoneyOverall") then
		var1 = false; --show money
		var2 = true; --hide moneyOverall
	elseif (UiWindow.radioGroupMoneyValue == "hideMoney") then
		var1 = true; --hide money
		var2 = false; --show moneyOverall
	end
	
	return var1, var2;
end

function PPT:UpdateRowOffsets(candidates)
	local rowOrder = PPT_DB.UiWindow.rowOrder;	
	local indexCurrent, indexNext;
	local rowOrderLength = PPT:GetTableLength(rowOrder);
		
	--zeros offsets
	for i = 1, rowOrderLength do
		rowOrder[i][2] = 0;
	end
	
	local frames = {
		[1] = {"frameMoney", false, candidates[1]},
		[2] = {"frameMoneyOverall", false, candidates[2]},
		[3] = {"frameButtonTrack", PPT_DB.AddonInterface.UiWindow.isButtonTrackHidden, candidates[3]},
		[4] = {"frameButtonAutoloot", PPT_DB.AddonInterface.UiWindow.isButtonAutolootHidden, candidates[4]}
	};
	
	frames[1][2], frames[2][2] = PPT:GetRadioVisibility();
	local framesLength = PPT:GetTableLength(frames);
	
	for i=1, rowOrderLength do
		local rowName = rowOrder[i][1];
		
		for c=1, framesLength do
			if (frames[c][1] == rowName) then 
				rowOrder[i][3] = frames[c][2]; --add isHidden flag to end
				rowOrder[i][4] = frames[c][3]; --add candidate flag to end
			end
		end
	end
	
	local parent1 = rowOrder[1][4]:GetParent();
	local parent2 = rowOrder[2][4]:GetParent();
	local _, _, _, _, yOffset1 = parent1:GetPoint();
	local _, _, _, _, yOffset2 = parent2:GetPoint();
	
	local distance = (yOffset2 - yOffset1);
	local invisible = 0;
	
	for i=1, rowOrderLength do
		if rowOrder[i][3] then --hidden rows
			--move everything else up 1
			invisible = invisible + 1;
			
			for c=i+1, rowOrderLength do
				rowOrder[c][2] = (distance * invisible);
			end
		end
		
		local point, relativeTo, relativePoint, xOffset = rowOrder[i][4]:GetPoint();			
		rowOrder[i][4]:SetPoint(point, relativeTo, relativePoint, xOffset, -rowOrder[i][2]);
	end
end

function PPT:SetVisibility(widget, bool)
	if bool then
		widget:Show();
	else
		widget:Hide();
	end
end

function PPT:BuildPickpocketTrackerFrame()
	local position = {PPT_DB.UiWindow.relativePoint, PPT_DB.UiWindow.xOffset, PPT_DB.UiWindow.yOffset};
	
	PPT.window:SetSize(PPT_DB.UiWindow.width, PPT_DB.UiWindow.height);
	PPT.window:ClearAllPoints();
	PPT.window:SetPoint(PPT_DB.UiWindow.point, UIParent, unpack(position));
	
	local UiWindow = PPT_DB.AddonInterface.UiWindow;
	local visibleMoney, visibleMoneyOverall = PPT:GetRadioVisibility();
	
	--row 1	
	PPT.frameMoney = STDUI_PPT:Frame(PPT.window);
	PPT.frameMoney:SetAttribute("name", "frameMoney");
	PPT.frameMoney:SetSize(PPT_DB.UiWindow.buttonWidth, PPT_DB.UiWindow.buttonHeight);
	PPT.labelMoney = STDUI_PPT:FontString(PPT.frameMoney, GetCoinTextureString(moneySessionCount));
	PPT.labelMoney:SetPoint('CENTER');		

	windowRow1 = PPT.window:AddRow(PPT_DB.UiWindow.row);
	windowRow1:AddElement(PPT.frameMoney);
	PPT:SetVisibility(PPT.labelMoney, not visibleMoney);
	
	--row 2
	PPT.frameMoneyOverall = STDUI_PPT:Frame(PPT.window);
	PPT.frameMoneyOverall:SetAttribute("name", "frameMoneyOverall");
	PPT.frameMoneyOverall:SetSize(PPT_DB.UiWindow.buttonWidth, PPT_DB.UiWindow.buttonHeight);
	PPT.labelMoneyOverall = STDUI_PPT:FontString(PPT.frameMoneyOverall, GetCoinTextureString(PPT_DB.moneyOverallCount));
	PPT.labelMoneyOverall:SetPoint('CENTER');
	
	windowRow2 = PPT.window:AddRow(PPT_DB.UiWindow.row);
	windowRow2:AddElement(PPT.frameMoneyOverall);
	PPT:SetVisibility(PPT.labelMoneyOverall, not visibleMoneyOverall);
	
	--row 3
	PPT.frameButtonTrack = STDUI_PPT:Frame(PPT.window);
	PPT.frameButtonTrack:SetAttribute("name", "frameButtonTrack");
	PPT.frameButtonTrack:SetSize(PPT_DB.UiWindow.buttonWidth, PPT_DB.UiWindow.buttonHeight);
	PPT.buttonTrack = STDUI_PPT:Button(PPT.frameButtonTrack, PPT_DB.UiWindow.buttonWidth, PPT_DB.UiWindow.buttonHeight, 'Track Gold');
	PPT.buttonTrack:SetPoint('CENTER');
	
	windowRow3 = PPT.window:AddRow(PPT_DB.UiWindow.row);
	windowRow3:AddElement(PPT.frameButtonTrack);
	PPT:SetVisibility(PPT.buttonTrack, not UiWindow.isButtonTrackHidden);
	
	--row 4
	PPT.frameButtonAutoloot = STDUI_PPT:Frame(PPT.window);
	PPT.frameButtonAutoloot:SetAttribute("name", "frameButtonAutoloot");
	PPT.frameButtonAutoloot:SetSize(PPT_DB.UiWindow.buttonWidth, PPT_DB.UiWindow.buttonHeight);
	PPT.buttonAutoloot = STDUI_PPT:Button(PPT.frameButtonAutoloot, PPT_DB.UiWindow.buttonWidth, PPT_DB.UiWindow.buttonHeight, 'Auto Loot ' .. autoloot);
	PPT.buttonAutoloot:SetPoint('CENTER');		
	
	windowRow4 = PPT.window:AddRow(PPT_DB.UiWindow.row);
	windowRow4:AddElement(PPT.frameButtonAutoloot);	
	PPT:SetVisibility(PPT.buttonAutoloot, not UiWindow.isButtonAutolootHidden);
	
	PPT.window:DoLayout();
end

function PPT:ResizeToFitPickpocketTrackerFrame()	
	local width = PPT:GetFrameMinimumSize("width", false, PPT.candidates, PPT_DB.UiWindow.layout.padding, PPT_DB.UiWindow.row.margin);
	local height = PPT:GetFrameMinimumSize("height", true, PPT.candidates, PPT_DB.UiWindow.layout.padding, PPT_DB.UiWindow.row.margin);
	
	return width, height;
end

function PPT:UpdatePickpocketTrackerFrame()
	if (PPT.labelMoney ~= nil) then 
		PPT.labelMoney:SetText(GetCoinTextureString(moneySessionCount));
	end
	
	PPT.labelMoneyOverall:SetText(GetCoinTextureString(PPT_DB.moneyOverallCount));
end

local function SaveWindowSizeAndPoint()
	PPT_DB.UiWindow.point, PPT_DB.UiWindow.relativeFrame, PPT_DB.UiWindow.relativePoint, PPT_DB.UiWindow.xOffset, PPT_DB.UiWindow.yOffset = PPT.window:GetPoint();
	PPT_DB.UiWindow.width = PPT.window:GetWidth();
	PPT_DB.UiWindow.height = PPT.window:GetHeight();
end

function PPT:UpdateBackdrop()
	STDUI_PPT:ApplyBackdrop(PPT.buttonTrack, 'button');
	STDUI_PPT:ApplyBackdrop(PPT.buttonAutoloot, 'button');
	STDUI_PPT:ApplyBackdrop(PPT.window, 'panel');
end

--event handling
PPT.window:RegisterEvent("CHAT_MSG_MONEY");
PPT.window:RegisterEvent("ADDON_LOADED");
	
local function PickpocketTracker_OnEvent(self, event, msg)
	if (event == "ADDON_LOADED") and (msg == "PickpocketTracker") then
		--default globals
		--PPT_DB = nil; --force reset ingame and reload		
		if (PPT_DB == nil) then		
			PPT_DB = {
				moneyOverallCount = 0;
				
				STDUI_PPT = {
					config = {
						font = {
							family = STDUI_PPT.config.font.family,
							size = STDUI_PPT.config.font.size,
							color = {
								normal = STDUI_PPT.config.font.color.normal
							}
						},
						backdrop = {
							texture = {text = "Default", value = STDUI_PPT.config.backdrop.texture},
							panel = STDUI_PPT.config.backdrop.panel,
							border = STDUI_PPT.config.backdrop.border,
							button = STDUI_PPT.config.backdrop.button
						},
						highlight = {
							color = STDUI_PPT.config.highlight.color
						}
					}
				},
				UiWindow = {
					point = 'BOTTOMLEFT',
					relativeFrame = 'UIParent',
					relativePoint = 'BOTTOMLEFT',
					xOffset = 0,
					yOffset = 0,
					width = 200,
					height = 200,
					buttonWidth = 128,
					buttonHeight = 20,
					
					layout = {
						gutter = 0,
						columns = 1,
						padding = {
							top = 0,
							bottom = 0,
							left = 0,
							right = 0
						}
					},
					rowOrder = {
						[1] = {"frameMoney", 0},
						[2] = {"frameMoneyOverall", 0},
						[3] = {"frameButtonTrack", 0},
						[4] = {"frameButtonAutoloot", 0}
					},
					row = {
						margin = {
							top = 0,
							bottom = 0,
							left = 0,
							right = 0
						}			
					}
				},
				AddonInterface = {
					UiWindow = {
						widthSliderMin = 1,
						widthSliderMax = 1000,
						heightSliderMin = 1,
						heightSliderMax = 1000,
						radioGroupMoneyValue = "showAll", --"showAll", "hideMoneyOverall", "hideMoney"
						isAlwaysTracking = false,
						isButtonTrackHidden = false,
						isButtonAutolootHidden = false,
						isReloadingUi = true
					}
				}
			}
		end

		PPT_DB.moneyOverallCount = 130592;
		
		--setup
		local onOff = { ["1"] = "On", ["0"] = "Off" };
		autoloot = onOff[GetCVar("autoLootDefault")];
		
		PPT.window:SetWidth(PPT_DB.UiWindow.width);
		PPT.window:SetHeight(PPT_DB.UiWindow.height);
		STDUI_PPT:EasyLayout(PPT.window, PPT_DB.UiWindow.layout);
		PPT:BuildPickpocketTrackerFrame();
		
		PPT.candidates = {PPT.labelMoney, PPT.labelMoneyOverall, PPT.buttonTrack, PPT.buttonAutoloot};
		PPT:UpdateRowOffsets(PPT.candidates);
		PPT:BuildPickpocketTrackerConfig();
		
		--lock sliders to stop OnValueChanged triggering
		PPT.sliderWindowWidth.lock = true;
		PPT.sliderWindowHeight.lock = true;
		
		PPT:UpdateWindowDimension_minimum();
		PPT:UpdatePickpocketTrackerFrame();
		
		local width = STDUI_PPT.Util.roundPrecision(PPT.window:GetWidth(), 2);
		local height = STDUI_PPT.Util.roundPrecision(PPT.window:GetHeight(), 2);
		
		PPT.sliderWindowWidth.editBox:SetValue(width);
		PPT.sliderWindowHeight.editBox:SetValue(height);
		PPT.sliderWindowWidth.slider:SetValue(width);
		PPT.sliderWindowHeight.slider:SetValue(height);
		
		PPT.sliderWindowWidth.lock = false;
		PPT.sliderWindowHeight.lock = false;
		
		STDUI_PPT.config.backdrop.texture = PPT_DB.STDUI_PPT.config.backdrop.texture.value;
		STDUI_PPT.config.backdrop.panel = PPT_DB.STDUI_PPT.config.backdrop.panel;
		STDUI_PPT.config.backdrop.border = PPT_DB.STDUI_PPT.config.backdrop.border;
		STDUI_PPT.config.backdrop.button = PPT_DB.STDUI_PPT.config.backdrop.button;
		STDUI_PPT.config.highlight.color = PPT_DB.STDUI_PPT.config.highlight.color;
		PPT:UpdateBackdrop();
		
		-- tooltipMoney = STDUI_PPT:FrameTooltip(PPT.frameMoney, 'Gold collected this session.', 'tooltipMoney', 'TOPRIGHT', true);			
		-- PPT.frameMoney:SetScript("OnEnter", function() 
			-- if not PPT_DB.AddonInterface.UiWindow.isMoneyHidden then tooltipMoney:Show(); end
		-- end);
		-- PPT.frameMoney:SetScript("OnLeave", function() tooltipMoney:Hide() end);
		
		-- tooltipMoneyOverall = STDUI_PPT:FrameTooltip(PPT.frameMoneyOverall, 'Total gold accumluated across multiple sessions.', 'tooltipMoneyOverall', 'TOPRIGHT', true);
		-- PPT.frameMoneyOverall:SetScript("OnEnter", function() 
			-- if not PPT_DB.AddonInterface.UiWindow.isMoneyOverallHidden then tooltipMoneyOverall:Show(); end
		-- end);
		-- PPT.frameMoneyOverall:SetScript("OnLeave", function() tooltipMoneyOverall:Hide() end);
		
		PPT.window:SetScript("OnSizeChanged", function()
			SaveWindowSizeAndPoint();
		end);
		
		PPT.window:SetScript("OnLeave", function()
			SaveWindowSizeAndPoint();
		end);
		
		PPT.buttonTrack:SetScript("OnClick", 
			function()
				if (tracking == false) then 
					PPT.buttonTrack:SetText('Stop');
					tracking = true;
				else
					PPT.buttonTrack:SetText('Track Gold');
					tracking = false;
					
					PPT.checkboxToggleAlwaysTracking:SetChecked(false);
				end
			end
		);
		
		if (PPT.frameButtonAutoloot ~= nil) then
			PPT.buttonAutoloot:SetScript("OnClick",
				function()
					if (autoloot == "Off") then
						SetCVar("autoLootDefault", "1");
					elseif (autoloot == "On") then
						SetCVar("autoLootDefault", "0");
					end
					
					autoloot = onOff[GetCVar("autoLootDefault")];
					PPT.buttonAutoloot:SetText('Auto Loot ' .. autoloot);
				end
			);
		end
		
		if PPT_DB.AddonInterface.UiWindow.isAlwaysTracking then PPT.buttonTrack:Click(); end
		
		loaded = true;
		PPT.window:DoLayout();
	end
	
	if (event == "CHAT_MSG_MONEY") and (loaded == true) and (tracking == true) then
		local gain = PPT:MoneyLootStringToValue(msg);
		moneySessionCount = moneySessionCount + gain;
		PPT_DB.moneyOverallCount = PPT_DB.moneyOverallCount + gain;
		
		PPT:UpdatePickpocketTrackerFrame();
		PPT.window:DoLayout();
	end
end

PPT.window:SetScript("OnEvent", PickpocketTracker_OnEvent);