-- TODO: move remaining TODOs elsewhere before first push to github

-- ✓ make build to distributable zip and support direct download of the zip?
-- ✓ extract display settings and use dofile(hs.spoons.resourcePath("displaySettings.lua"))

-- TODO: solve performance problems in Hammerspoon if possible (solved by adding stop()?)
-- TODO: eliminate transient "error" state while Zoom is quitting
-- ✓ complete stop()
-- ✓ review all var and fn names, some need updates - monitorWidget is poor
-- TODO: use --- doc comments to support docs.json
-- TODO: generate docs.json

-- TODO: metadata -- reconsider gmail address in metadata, maybe use alias or set up new account?
-- TODO: metadata -- pick a .license
-- TODO: come up with a better name?
-- TODO: push to github and add .homepage metadata

-- TODO: sort out error/unknown colors
-- TODO: diff colors for dark mode??
-- ✓ bug -- dot widget comes up with full opacity before first blink
-- TODO: add shaded background (rounded?) square behind widget
-- TODO: add settings to deactivate either or both monitors?
-- ✓ menubar: consider removing hardcoded "Zoom:" prefix?

--
-- ZoomMuteMonitor.spoon
-- Monitor to display Zoom mute status in two "monitors": a colored dot at the
-- bottom right of the screen, and a text display in the menu bar.
--
-- Features:
--   * highly customizable display options - edit displaySettings.lua to suit
--   * automatically supports multiple monitors
--

local obj = {}
obj.__index = obj

--
-- Spoon metadata
--

obj.name = "ZoomMuteMonitor"
obj.version = "0.1"
obj.author = "Matthias Ferber"
obj.license = ""

--
-- Vars
--

local menuBarWidget
local dotWidgets = {}
local currentStatus
local blinkTimer

--
-- Spoon lifecycle methods
--

function obj:init()
   self.displaySettings = dofile(hs.spoons.resourcePath("displaySettings.lua"))
end

function obj:start()
   self:createWidgets()
   self:beginPolling()
   self:beginWatchingForScreenUpdates()
end

function obj:stop()
   self:stopWatchingForScreenUpdates()
   self:stopPolling()
   self:disposeWidgets()
end

--
-- Other methods
--

function obj:beginPolling()
   local pollFn = function() self:updateDisplay() end
   -- var must be global to prevent garbage collection, esp during sleep
   pollTimer = hs.timer.doEvery(self.displaySettings.pollIntervalSecs, pollFn,
      true)
end

function obj:stopPolling()
   if pollTimer ~= nil then
      pollTimer:stop()
      pollTimer = nil
   end
end

function obj:beginWatchingForScreenUpdates()
   -- var must be global to prevent garbage collection, esp during sleep
   screenWatcher = hs.screen.watcher.new(function ()
      self:reset()
   end)
   screenWatcher:start()
end

function obj:stopWatchingForScreenUpdates()
   if screenWatcher ~= nil then
      screenWatcher:stop() 
      screenWatcher = nil
   end
end

function obj:disposeWidgets()
   if blinkTimer ~= nil then blinkTimer:stop() end
   if menuBarWidget ~= nil then menuBarWidget:delete() end
   if dotWidgets ~= nil and #dotWidgets > 0 then
      for _, widget in ipairs(dotWidgets) do
         widget:delete()
      end
   end
   
   menuBarWidget = nil
   dotWidgets = {}
   currentStatus = "unknown"
end


function obj:reset()
   self:disposeWidgets()
   self:createWidgets()
end

function obj:createWidgets()
   menuBarWidget = hs.menubar.new()
   for _, screen in ipairs(hs.screen.allScreens()) do
      local widget = self:createDotWidget(screen)
      table.insert(dotWidgets, widget)
      widget:show()
   end
   self:updateDisplay()
end

function obj:createDotWidget(screen)
   local frame = screen:frame()
   local diameter = self.displaySettings.dotWidget.diameter
   local offset = self.displaySettings.dotWidget.edgeOffset
   local strokeWidth = self.displaySettings.dotWidget.strokeWidth
   local widget = hs.canvas.new(
      hs.geometry(
         frame.x + frame.w - diameter - offset.x,
         frame.y + frame.h - diameter - offset.y,
         diameter + strokeWidth * 2,
         diameter + strokeWidth * 2
      )
   )
   local dot = {
      type="circle",
      radius=self.displaySettings.dotWidget.diameter / 2.0,
      fillColor=self.displaySettings.dotWidget.colors.unknown.fill,
      strokeColor=self.displaySettings.dotWidget.colors.unknown.stroke,
      strokeWidth=self.displaySettings.dotWidget.strokeWidth
   }

   -- suppress hairline black border when width is 0
   if dot.strokeWidth == 0 then
      dot.strokeColor = self.displaySettings.colors.transparent
   end

   widget:appendElements(dot)
   widget:alpha(self.displaySettings.dotWidget.alpha)
   widget:behaviorAsLabels({
      hs.canvas.windowBehaviors.canJoinAllSpaces,
      hs.canvas.windowBehaviors.stationary
   })
   return widget
end

-- helper AppleScript to query Zoom's status
-- returns: "muted", "unmuted", "unknown" (if Zoom not running), or "error"
local muteCheckAppleScript = [[
   try
      delay 0.5
      tell application "System Events"
         with timeout of 1 second
            try
               set p to process "zoom.us"
               set meetingMenu to menu 1 of menu bar item "Meeting" of menu bar 1 of p
               set meetingMenuItems to (get name of every menu item of meetingMenu)
            on error msg number errNum
               if errNum is -1712 then -- timeout: zoom probably not running
                  return "unknown"
               else if errNum is -1728 then -- can't get UI obj: probably no meeting
                  return "unknown"
               else
                  return "error"
               end if
            end
         end timeout
         if meetingMenuItems contains "Mute Audio" then
            return "unmuted"
         else if meetingMenuItems contains "Unmute Audio" then
            return "muted"
         else 
            return "unknown"
         end if
      end tell
   on error
      return "error"
   end
]]

-- determine Zoom's status
-- returns: "muted", "unmuted", "unknown" (if Zoom not running), or "error"
function obj:zoomMuteStatus()
   local success, result, raw = hs.osascript.applescript(muteCheckAppleScript)
   return result
end

-- get the font for the menu bar widget; tries to follow configured display
-- settings if possible
function obj:getDisplayFont()
   local font = nil
   local selected, fontName
   for i, fontDescriptor in pairs(self.displaySettings.menuBarWidget.fonts) do
      local fontsData = hs.styledtext.fontsForFamily(fontDescriptor["name"])
      local preferredStyle = fontDescriptor["style"] or defaultFontStyle
      if fontsData ~= nil then
         for j, fontInfo in ipairs(fontsData) do
            local fontName, fontStyles = fontInfo[1], fontInfo[3]
            for k, s in ipairs(fontStyles) do
               if s == preferredStyle then
                  selected = fontDescriptor
                  selectedInternalName = fontName
                  break
               end
               if selected ~= nil then break end
            end
            if selected ~= nil then break end
         end
      end
      if selected ~= nil then break end
   end

   -- if no match, fall back to the platform's menu bar font
   if selected == nil then return hs.styledtext.defaultFonts.menuBarFont end

   local font = {name=selectedInternalName, size=selected["size"] or defaultFontSize}
   return font
end

function obj:blinkMenuBarWidgetOn()
   if menuBarWidget == nil then
      return
   end
   local styledText = menuBarWidget:title(true)
   local color = self.displaySettings.menuBarWidget.colors[currentStatus].text
   local bgColor =
      self.displaySettings.menuBarWidget.colors[currentStatus].backgroundText
   local newText = styledText:setStyle({color=color, backgroundColor=bgColor})
   menuBarWidget:setTitle(newText)
end

function obj:blinkMenuBarWidgetOff()
   if menuBarWidget == nil then return end
   local styledText = menuBarWidget:title(true)
   local info = styledText:asTable()
   local text, style = info[1], info[2]
   if style == nil then style = {attributes={}} end

   local bgColor = style.attributes.backgroundColor
   if bgColor == nil then bgColor = self.displaySettings.colors.transparent end
   local newText = styledText:setStyle({
      color=bgColor
   })
   menuBarWidget:setTitle(newText)
end

function obj:blinkDotWidgetsOn()
   for _, widget in ipairs(dotWidgets) do
      widget:alpha(self.displaySettings.dotWidget.alpha)
   end
end

function obj:blinkDotWidgetsOff()
   for _, widget in ipairs(dotWidgets) do
      widget:alpha(self.displaySettings.dotWidget.alphaWhenBlinkedOff)
   end
end

function obj:blink()
   self:blinkMenuBarWidgetOff()
   self:blinkDotWidgetsOff()
   hs.timer.doAfter(self.displaySettings.blinkDurationSecs, function ()
      self:blinkMenuBarWidgetOn()
      self:blinkDotWidgetsOn()
   end)
end

function obj:updateBlinkIntervalForCurrentStatus(status)
   if blinkTimer ~= nil then
      blinkTimer:stop() 
   end
   local interval = self.displaySettings.blinkIntervalSecs[status]
   if interval > 0 then
      local blinkFn = function() self:blink() end
      blinkTimer = hs.timer.doEvery(interval, blinkFn, true)
   end
end

function obj:updateMenuBarDisplayForCurrentStatus(status)
   local textColor = self.displaySettings.menuBarWidget.colors[status].text
   local backgroundColor =
      self.displaySettings.menuBarWidget.colors[status].textBackground
   local styledTitle = hs.styledtext.new(
      self.displaySettings.menuBarWidget.text[status],
      {
         font=self:getDisplayFont(),
         color=textColor,
         backgroundColor=backgroundColor
      }
   )
   menuBarWidget:setTitle(styledTitle)
end

function obj:updateDotWidgetsForCurrentStatus(status)
   for _, widget in ipairs(dotWidgets) do
      widget:elementAttribute(1, "fillColor",
         self.displaySettings.dotWidget.colors[status].fill)

      -- suppress hairline black border when width is 0
      local strokeColor = self.displaySettings.dotWidget.colors[status].stroke
      if self.displaySettings.dotWidget.strokeWidth == 0 then
         strokeColor = self.displaySettings.colors.transparent
      end
      widget:elementAttribute(1, "strokeColor", strokeColor)
   end
end

function obj:updateDisplay()
   local tempSelf = self
   local updateSucceeded, error = pcall(function()
      local status = tempSelf:zoomMuteStatus()
      if status ~= currentStatus then
         currentStatus = status
         tempSelf:updateMenuBarDisplayForCurrentStatus(status)
         tempSelf:updateDotWidgetsForCurrentStatus(status)
         tempSelf:updateBlinkIntervalForCurrentStatus(status)
      end
   end)
   if not updateSucceeded then 
      self:updateMenuBarDisplayForCurrentStatus("error")
      self:updateDotWidgetsForCurrentStatus("error")
   end
end

return obj
