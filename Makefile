APP_NAME := Crop Guide Overlay
APP_PATH := .build/$(APP_NAME).app

.PHONY: app package run install-agent uninstall-agent clean

app:
	@Scripts/build-app.sh

package:
	@Scripts/package.sh

run: app
	@open "$(APP_PATH)"

install-agent: app
	@Scripts/install-launch-agent.sh "$(CURDIR)/$(APP_PATH)"

uninstall-agent:
	@Scripts/uninstall-launch-agent.sh

clean:
	@rm -rf .build
