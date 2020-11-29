# ZoomMuteMonitor

A [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) spoon (plugin) that displays a monitor of the current Zoom mute status in the menu bar and in a colored overlay dot on the screen.

## Installation

1. [Install and run Hammerspoon](https://www.hammerspoon.org/go/) if it isn't already installed.
2. [Download `Hammerspoon.spoon.zip`](https://github.com/mferber/ZoomMuteMonitor-Hammerspoon/raw/release/dist/ZoomMuteMonitor.spoon.zip) and double-click it to unzip it.
3. Double-click on the unzipped `./Hammerspoon.spoon` to install it into Hammerspoon.
4. In `~/.hammerspoon/init.lua`, add the following:

 ```
 zoomMuteMonitor = hs.loadSpoon('ZoomMuteMonitor')
 zoomMuteMonitor:start()
 ```
5. Reload the Hammerspoon settings, using "Reload config" in the Hammerspoon menu bar or console window. The widgets should appear.

## Options

Edit `~/.hammerspoon/Spoons/ZoomMuteMonitor.spoon/displaySettings.lua` as desired to change many details of the display, including fonts, colors, and timing.
 