RaidBrowser.gui.raidset = {};

local frame = CreateFrame("Frame", "RaidBrowserRaidSetMenu", LFRBrowseFrame, "UIDropDownMenuTemplate")
UIDropDownMenu_SetWidth(RaidBrowserRaidSetMenu, 150)
frame:SetWidth(90);

local current_selection = nil;

---@return boolean
local function is_active_selected(_)
	return 'Active' == current_selection;
end

---@return boolean
local function is_primary_selected(_)
	return 'Primary' == current_selection;
end

---@return boolean
local function is_secondary_selected(_)
	return 'Secondary' == current_selection;
end

local function is_both_selected(option)
	return ('Both' == current_selection);
end

---@param selection 'Active'|'Primary'|'Secondary'
local function set_selection(selection)
	local text = '';

	if selection == 'Both' then
		local spec1, gs1 = RaidBrowser.stats.get_raidset('Primary')
		local spec2, gs2 = RaidBrowser.stats.get_raidset('Secondary')
		

		if spec1 and gs1 then
			gs1 = math.floor(gs1 / 100) / 10
			text = text .. gs1 .. ' ' .. spec1
		else
			text = text .. '-'
		end
		text = text .. ' / '
		if spec2 and gs2 then
			gs2 = math.floor(gs2 / 100) / 10
			text = text .. gs2 .. ' ' .. spec2
		else
			text = text .. '-'
		end
		if not (spec1 or spec2) then
			text = 'Set any spec first';
		end
		
	else
		---@diagnostic disable-next-line: param-type-mismatch
		local spec, gs = RaidBrowser.stats.get_raidset(selection)
		if not spec then
			text = 'Free slot';
		elseif not gs then
			text = spec;
		else
			text = gs..' '..spec
		end
	end

	UIDropDownMenu_SetText(RaidBrowserRaidSetMenu, text)
	current_selection = selection;
end

local function on_active()
	set_selection('Active');
	RaidBrowser.stats.select_current_raidset('Active');
	RaidBrowser.check_button()
end

local function on_primary()
	set_selection('Primary');
	RaidBrowser.stats.select_current_raidset('Primary');
	RaidBrowser.check_button()
end

local function on_secondary()
	set_selection('Secondary');
	RaidBrowser.stats.select_current_raidset('Secondary');
	RaidBrowser.check_button()
end

local function on_both()
	set_selection('Both');
	RaidBrowser.stats.select_current_raidset('Both');
	RaidBrowser.check_button()
end

local menu = {
	{
		text = 'Active',
		func = on_active,
		checked = is_active_selected,
	},

	{
		text = "Primary",
		func = on_primary,
		checked = is_primary_selected,
	},

	{
		text = "Secondary",
		func = on_secondary,
		checked = is_secondary_selected,
	},
	
	{ 
		text = "Both", 
		func = on_both, 
		checked = is_both_selected,
	}
}

-- Get the menu option text
local function get_option_active(option)
    local spec, gs = RaidBrowser.stats.get_active_raidset()
    return (option .. ': ' .. gs .. ' ' .. spec)
end

-- Get the menu option text
local function get_option_text(option)
	local spec, gs = RaidBrowser.stats.get_raidset(option);
	if not spec then
		return option .. ': Free slot';
	end
	
	return (option .. ': ' .. gs .. ' ' .. spec);
end

-- Get the menu option texts
local function get_option_texts(option)
	local spec1, gs1 = RaidBrowser.stats.get_raidset('Primary');
	local spec2, gs2 = RaidBrowser.stats.get_raidset('Secondary');
	if not spec1 then
		return (option .. ': Open');
	end

	if not (spec1 or spec2) then
		return (option .. ': Set any spec first')
	elseif (spec1 and spec2) then
		return (option .. ': ' .. gs1 .. ' ' .. spec1 .. ' / ' .. gs2 .. ' ' .. spec2)
	elseif spec1 then
		return (option .. ': ' .. gs1 .. ' ' .. spec1 .. ' / ' .. '-')
	elseif spec2 then
		return (option .. ': ' .. '-' .. ' / ' .. gs2 .. ' ' .. spec2)
	end
	
	return (option .. ': ' .. gs1 .. ' ' .. spec1 .. ' / ' .. gs2 .. ' ' .. spec2);
end

-- Setup dropdown menu for the raidset selection
frame:SetPoint("CENTER", LFRBrowseFrame, "CENTER", 30, 165)
UIDropDownMenu_Initialize(frame, EasyMenu_Initialize, nil, nil, menu);

local function show_menu()
	menu[1].text = get_option_text('Active');
	menu[2].text = get_option_text('Primary');
	menu[3].text = get_option_text('Secondary');
	menu[4].text = get_option_texts('Both');
	ToggleDropDownMenu(1, nil, frame, frame, 25, 10, menu);	 
end

RaidBrowserRaidSetMenuButton:SetScript('OnClick', show_menu)

local function on_raidset_save()
	if current_selection == 'Primary' then
		RaidBrowser.stats.save_primary_raidset();

	elseif current_selection == 'Secondary' then
		RaidBrowser.stats.save_secondary_raidset();
	end

	local spec, gs = RaidBrowser.stats.current_raidset();

	---@diagnostic disable-next-line: undefined-field
	RaidBrowser:Print('Raidset saved: ' .. spec .. ' ' .. gs .. 'gs');
	set_selection(current_selection);
end

function RaidBrowser.gui.raidset.initialize()
	set_selection(RaidBrowserCharacterCurrentRaidset);
end

local function check_button(button)
    if is_active_selected() or is_both_selected() then
        button:Disable()
    else
        button:Enable()
    end
end

function RaidBrowser.check_button()
    if is_active_selected() or is_both_selected() then
        RaidBrowserRaidSetSaveButton:Disable()
        RaidBrowserRaidSetSaveButton:SetText("Select spec first")
        RaidBrowserRaidSetSaveButton:Hide()
    else
        RaidBrowserRaidSetSaveButton:Enable()
        RaidBrowserRaidSetSaveButton:SetText("Save gear+spec")
        RaidBrowserRaidSetSaveButton:Show()
    end
end

local function onEvent(this, event, arg1)
	if event == "PLAYER_EQUIPMENT_CHANGED" or "PLAYER_SPECIALIZATION_CHANGED" then
		RaidBrowser.gui.raidset.initialize()
	end
end

local function onShow(this)
	-- update displayed Spec + GS in selection onShow
	RaidBrowser.gui.raidset.initialize()
end

frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:SetScript("OnEvent", onEvent)
frame:SetScript("onShow", onShow)


-- Create raidset save button
local button = CreateFrame("BUTTON", "RaidBrowserRaidSetSaveButton", LFRBrowseFrame, "OptionsButtonTemplate")
button:SetPoint("CENTER", LFRBrowseFrame, "CENTER", -53, 168)
button:EnableMouse(true)
button:RegisterForClicks("AnyUp")

button:SetText("Save Raid Gear");
button:SetWidth(110);
button:SetScript("OnClick", on_raidset_save);
button:Show();
check_button(button);
