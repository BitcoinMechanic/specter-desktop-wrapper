ASSETS := $(shell yq e '.assets.[].src' manifest.yaml)
ASSET_PATHS := $(addprefix assets/,$(ASSETS))
VERSION := $(shell yq e ".version" manifest.yaml)
S9PK_PATH=$(shell find . -name specter-desktop.s9pk -print)

# delete the target of a rule if it has changed and its recipe exits with a nonzero exit status
.DELETE_ON_ERROR:

all: verify

verify: specter-desktop.s9pk $(S9PK_PATH)
	embassy-sdk verify s9pk $(S9PK_PATH)

clean:
	rm -f image.tar
	rm -f specter-desktop.s9pk

specter-desktop.s9pk: manifest.yaml assets/compat/* image.tar icon.png docs/instructions.md $(ASSET_PATHS)
	embassy-sdk pack

image.tar: Dockerfile docker_entrypoint.sh assets/utils/*
	DOCKER_CLI_EXPERIMENTAL=enabled docker buildx build --tag start9/specter-desktop/main:$(VERSION) --platform=linux/arm64/v8 -o type=docker,dest=image.tar -f ./Dockerfile .