VERSION ?= $(shell cat VERSION)

.PHONY: build
build:
	docker build --build-arg VERSION=$(VERSION) -t davidcollom/vcc-cal:$(VERSION)  .

.PHONY: local
local: build
	docker run --rm -ti -v $(PWD)/.cache:/app/cache -p 3000:3000 davidcollom/vcc-cal:$(VERSION)

.PHONY: debug
debug: build
	docker run --rm -ti -v $(PWD):/app/ -v $(PWD)/.cache:/app/cache davidcollom/vcc-cal:$(VERSION) bash

.PHONY: publish
publish: build
	docker push davidcollom/vcc-cal:$(VERSION)
