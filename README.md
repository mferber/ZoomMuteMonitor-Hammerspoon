# ZoomMuteMonitor

A [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) spoon (plugin) that displays a monitor of the current Zoom mute status in the menu bar and in a colored overlay dot on the screen.

## Installation

(TODO: add direct download path from GitHub)

1. [Install and run Hammerspoon](https://www.hammerspoon.org/go/) if it isn't already installed.
2. In the project root, double-click on the `./Hammerspoon.spoon` package to install it in Hammerspoon.
3. In `~/.hammerspoon/init.lua`, add the following:

 ```
 zoomMuteMonitor = hs.loadSpoon('ZoomMuteMonitor')
 zoomMuteMonitor:start()
 ```

4. Reload the Hammerspoon settings, using "Reload config" in the Hammerspoon menu bar or console window.
5. Widgets should appear in the menu bar and the screen bottom left indicating the current mute status, or a "waiting" status if Zoom isn't running.

## Options

Edit `displaySettings.lua` to change many details of the display, including fonts, colors, and timing.
 