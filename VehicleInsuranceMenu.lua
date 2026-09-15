-- ============================================================
-- FS25_VehicleInsuranceMenu.lua
-- by Marcus (Cobra Modding)
-- 
--
-- Version 1.0.0.0
--
--
-- Keine Änderung am Skript ohne meine Erlaubnis
-- ============================================================

VehicleInsuranceFrame = {}
local VehicleInsuranceFrame_mt = Class(VehicleInsuranceFrame, TabbedMenuFrameElement)

function VehicleInsuranceFrame.new()
    local self = TabbedMenuFrameElement.new(nil, VehicleInsuranceFrame_mt)
    self.name = "VehicleInsuranceFrame"
    return self
end

function VehicleInsuranceFrame:initialize()
    VehicleInsuranceFrame:superClass().initialize(self)
    self.menuButtonInfo = {{inputAction=InputAction.MENU_BACK}}
    if self.subCategoryTabs ~= nil then
        for i, tab in pairs(self.subCategoryTabs) do
            local background = tab:getDescendantByName("background")
            local selected = function()
                return g_vehicleInsurance ~= nil and (g_vehicleInsurance.selectedTab or 1) == i
            end
            if background ~= nil then background.getIsSelected = selected end
            tab.getIsSelected = selected
        end
    end
end

function VehicleInsuranceFrame:getMenuButtonInfo()
    return self.menuButtonInfo or {}
end

function VehicleInsuranceFrame:setInsuranceTab(index)
    local mod = g_vehicleInsurance
    if mod ~= nil then mod.selectedTab = index or 1 end
    if self.subCategoryPaging ~= nil and self.subCategoryPaging:getState() ~= index then
        self.subCategoryPaging:setState(index, true)
    end
end

function VehicleInsuranceFrame:onClickTabVehicles()
    self:setInsuranceTab(1)
end

function VehicleInsuranceFrame:onClickTabTariffs()
    self:setInsuranceTab(2)
end

function VehicleInsuranceFrame:onPagingChanged()
    if self.subCategoryPaging ~= nil then self:setInsuranceTab(self.subCategoryPaging:getState()) end
end

function VehicleInsuranceFrame:refreshHeader()
    local mod = g_vehicleInsurance
    if mod == nil then return end
    if self.insuranceTitleText ~= nil then
        local mapName = mod:getMapName()
        self.insuranceTitleText:setText(mapName ~= "" and ("SCHADENSVERSICHERUNG · " .. mapName) or "SCHADENSVERSICHERUNG")
    end
    if self.currentBalanceText ~= nil then
        self.currentBalanceText:setText(g_i18n:formatMoney(mod:getFarmMoney(), 0, true, true))
    end
    if self.subCategoryPaging ~= nil then
        self.subCategoryPaging:setTexts({"FAHRZEUGE", "TARIFE"})
        self.subCategoryPaging:setState(mod.selectedTab or 1, true)
    end
end

function VehicleInsuranceFrame:onFrameOpen()
    VehicleInsuranceFrame:superClass().onFrameOpen(self)
    local mod = g_vehicleInsurance
    if mod ~= nil then
        mod.isMenuPageOpen = true
        mod.selected = math.max(1, mod.selected or 1)
        mod.listOffset = math.max(1, mod.listOffset or 1)
        mod.selectedTab = mod.selectedTab or 1
        self:refreshHeader()
    end
end

function VehicleInsuranceFrame:onFrameClose()
    if g_vehicleInsurance ~= nil then g_vehicleInsurance.scrollDrag = nil end
    if g_vehicleInsurance ~= nil then g_vehicleInsurance.isMenuPageOpen = false end
    VehicleInsuranceFrame:superClass().onFrameClose(self)
end

function VehicleInsuranceFrame:draw()
    VehicleInsuranceFrame:superClass().draw(self)
    if g_vehicleInsurance ~= nil then
        self:refreshHeader()
        g_vehicleInsurance:drawMenuSurface()
    end
end

function VehicleInsuranceFrame:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    return VehicleInsuranceFrame:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
end

VehicleInsuranceMenu = {modDirectory=g_currentModDirectory}

function VehicleInsuranceMenu:addPage(inGameMenu)
    if inGameMenu == nil or inGameMenu.pageVehicleInsurance ~= nil then return end
    if inGameMenu.registerPage == nil or inGameMenu.addPageTab == nil or inGameMenu.pagingElement == nil then
        Logging.warning("[VehicleInsurance] ESC menu page API unavailable")
        return
    end
    if not self.profilesLoaded then
        g_gui:loadProfiles(self.modDirectory .. "gui/guiProfiles.xml")
        self.profilesLoaded = true
    end
    local template = VehicleInsuranceFrame.new()
    g_gui:loadGui(self.modDirectory .. "gui/VehicleInsuranceFrame.xml", "VehicleInsuranceFrame", template, true)
    local xml = loadXMLFile("VehicleInsuranceFrameRefXML", self.modDirectory .. "gui/VehicleInsuranceFrameRef.xml")
    if xml == nil or xml == 0 then
        Logging.error("[VehicleInsurance] ESC frame reference could not be loaded")
        return
    end
    inGameMenu.controlIDs.pageVehicleInsurance = nil
    g_gui:loadGuiRec(xml, "FrameReferences", inGameMenu.pagingElement, inGameMenu)
    for _, element in ipairs(inGameMenu.pagingElement.elements) do
        if element.id == "pageVehicleInsurance" then
            inGameMenu.pageVehicleInsurance = element
            inGameMenu.controlIDs.pageVehicleInsurance = true
            break
        end
    end
    inGameMenu.pagingElement:updatePageMapping()
    delete(xml)
    if inGameMenu.pageVehicleInsurance == nil then
        Logging.error("[VehicleInsurance] ESC frame reference missing")
        return
    end
    local frame = g_gui:resolveFrameReference(inGameMenu.pageVehicleInsurance)
    if frame == nil or frame.elements == nil or frame.elements[1] == nil then
        Logging.error("[VehicleInsurance] ESC frame could not be resolved")
        return
    end
    frame.elements[1].title = "Schadensversicherung"
    inGameMenu.pageVehicleInsurance = frame
    inGameMenu.pagingElement:removePageByElement(frame)
    local position = #(inGameMenu.pageFrames or {}) + 1
    for i, page in ipairs(inGameMenu.pageFrames or {}) do
        if page == inGameMenu.pageStatistics then position = i break end
    end
    local _, actualPosition = inGameMenu:registerPage(frame, position, function() return true end)
    inGameMenu:addPageTab(frame, self.modDirectory .. "gui/insuranceTab.dds", {0, 0, 0, 1, 1, 0, 1, 1}, nil)
    inGameMenu.pagingElement:addPage("PAGEVEHICLEINSURANCE", frame, "Schadensversicherung", actualPosition)
    frame:onGuiSetupFinished()
    frame:initialize()
    inGameMenu.pagingElement:updateAbsolutePosition()
    inGameMenu.pagingElement:updatePageMapping()
    if inGameMenu.rebuildTabList ~= nil then inGameMenu:rebuildTabList() end
    self.inGameMenu = inGameMenu
    self.frame = frame
    print("[VehicleInsurance] ESC menu page added")
end

function VehicleInsuranceMenu:ensurePage()
    if g_gui == nil or g_gui.screenControllers == nil or InGameMenu == nil then return end
    local menu = g_gui.screenControllers[InGameMenu]
    if menu == nil or menu.pageFrames == nil or #menu.pageFrames == 0 then return end
    self:addPage(menu)
end
