all: dist/ZoomMuteMonitor.spoon.zip

dist/ZoomMuteMonitor.spoon.zip: ZoomMuteMonitor.spoon/*
	zip -r dist/ZoomMuteMonitor.spoon.zip ZoomMuteMonitor.spoon

