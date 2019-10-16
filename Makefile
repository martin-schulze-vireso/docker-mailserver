NAME = tvial/docker-mailserver:testing

all: build-no-cache backup generate-accounts tests clean
all-fast: build backup generate-accounts tests clean
no-build: backup generate-accounts tests clean

build-no-cache:
	export DOCKER_MAIL_DOCKER_BUILD_NO_CACHE=--no-cache
	docker build --no-cache -t $(NAME) .

build:
	docker build -t $(NAME) .

backup:
	# if backup directories exist, clean hasn't been called, therefore we shouldn't overwrite it. It still contains the original content.
	@if [ ! -d config.bak ]; then\
  	cp -rp config config.bak; \
	fi
	@if [ ! -d testconfig.bak ]; then\
		cp -rp test/config testconfig.bak ;\
	fi

generate-accounts:
	docker run --rm -e MAIL_USER=user1@localhost.localdomain -e MAIL_PASS=mypassword -t $(NAME) /bin/sh -c 'echo "$$MAIL_USER|$$(doveadm pw -s SHA512-CRYPT -u $$MAIL_USER -p $$MAIL_PASS)"' > test/config/postfix-accounts.cf
	docker run --rm -e MAIL_USER=user2@otherdomain.tld -e MAIL_PASS=mypassword -t $(NAME) /bin/sh -c 'echo "$$MAIL_USER|$$(doveadm pw -s SHA512-CRYPT -u $$MAIL_USER -p $$MAIL_PASS)"' >> test/config/postfix-accounts.cf

tests:
	# Start tests
	./test/bats/bin/bats test/*.bats

.PHONY: ALWAYS_RUN

test/%.bats: ALWAYS_RUN
		./test/bats/bin/bats $@

lint:
	# List files which name starts with 'Dockerfile'
	# eg. Dockerfile, Dockerfile.build, etc.
	git ls-files --exclude='Dockerfile*' --ignored | xargs --max-lines=1 hadolint

clean:
	# Remove running and stopped test containers
	-docker ps -a | grep -E "docker-mailserver:testing|ldap_for_mail" | cut -f 1-1 -d ' ' | xargs --no-run-if-empty docker rm -f

	@if [ -d config.bak ]; then\
		rm -rf config ;\
		mv config.bak config ;\
	fi
	@if [ -d testconfig.bak ]; then\
		sudo rm -rf test/config ;\
		mv testconfig.bak test/config ;\
	fi
	-sudo rm -rf test/onedir test/alias test/relay test/config/dovecot-lmtp/userdb test/config/key* test/config/opendkim/keys/domain.tld/ test/config/opendkim/keys/example.com/ test/config/opendkim/keys/localdomain2.com/ test/config/postfix-aliases.cf test/config/postfix-receive-access.cf test/config/postfix-receive-access.cfe test/config/postfix-send-access.cf test/config/postfix-send-access.cfe test/config/relay-hosts/chksum test/config/relay-hosts/postfix-aliases.cf
