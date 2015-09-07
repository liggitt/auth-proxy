NAME = liggitt/auth-proxy
VERSION = 0.1.0

.PHONY: all build test tag_latest release

all: build tag_latest

build:
	docker build -t $(NAME):$(VERSION) --rm .

test:
	env NAME=$(NAME) VERSION=$(VERSION) ./test/runner.sh

run:
ifndef BACKEND
	@echo '$$(BACKEND) must be defined (e.g. BACKEND=https://1.2.3.4:8443 make run)'
	@exit 1
endif
ifndef PROXY_HOST
	@echo '$$(PROXY_HOST) is not defined, using mydomain.com'
	docker run -p 80:80 -p 88:88 -h mydomain.com -e BACKEND=$(BACKEND) -ti $(NAME)
else
	docker run -p 80:80 -p 88:88 -h $(PROXY_HOST) -e BACKEND=$(BACKEND) -ti $(NAME)
endif

tag_latest:
	docker tag -f $(NAME):$(VERSION) $(NAME):latest

release: test tag_latest
	@if ! docker images $(NAME) | awk '{ print $$2 }' | grep -q -F $(VERSION); then echo "$(NAME) version $(VERSION) is not yet built. Please run 'make build'"; false; fi
	@if ! head -n 1 Changelog.md | grep -q 'release date'; then echo 'Please note the release date in Changelog.md.' && false; fi
	docker push $(NAME)
	@echo "*** Don't forget to create a tag. git tag rel-$(VERSION) && git push origin rel-$(VERSION)"
