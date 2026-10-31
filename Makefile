# Every Flutter command needs the env file, otherwise the dart-defines are
# silently empty. Override with `make run ENV_FILE=config/env.pro.json`.
ENV_FILE ?= config/env.dev.json
DEFINES := --dart-define-from-file=$(ENV_FILE)

.PHONY: setup run analyze test test-defines build-apk build-ios

## Creates the local env file from the tracked template when missing.
setup:
	@test -f $(ENV_FILE) || cp config/env.example.json $(ENV_FILE)

## Runs the app on a device with the local configuration.
run: setup
	flutter run $(DEFINES)

analyze:
	flutter analyze

test:
	flutter test

## Proves the --dart-define path end to end (see test/core/config/env_test.dart).
test-defines:
	flutter test --dart-define=API_BASE_URL=https://api.example.test

build-apk: setup
	flutter build apk $(DEFINES)

build-ios: setup
	flutter build ios $(DEFINES) --no-codesign
