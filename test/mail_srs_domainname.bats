load 'test_helper/common'

setup() {
    run_setup_file_if_necessary
}

teardown() {
    run_teardown_file_if_necessary
}

setup_file() {
    docker run -d --name mail_srs_domainname \
		-v "`pwd`/test/config":/tmp/docker-mailserver \
		-v "`pwd`/test/test-files":/tmp/docker-mailserver-test:ro \
		-e PERMIT_DOCKER=network \
		-e DMS_DEBUG=0 \
		-e ENABLE_SRS=1 \
		-e SRS_DOMAINNAME=srs.my-domain.com \
		-e DOMAINNAME=my-domain.com \
		-h unknown.domain.tld \
		-t ${NAME}
    docker run --rm -d --name mail_domainname \
		-v "`pwd`/test/config":/tmp/docker-mailserver \
		-v "`pwd`/test/test-files":/tmp/docker-mailserver-test:ro \
		-e PERMIT_DOCKER=network \
		-e DMS_DEBUG=0 \
		-e ENABLE_SRS=1 \
		-e DOMAINNAME=my-domain.com \
		-h unknown.domain.tld \
		-t ${NAME}
}


teardown_file() {
    docker rm -f mail_srs_domainname mail_domainname
}

@test "first" {
    skip 'only used to call setup_file from setup'
}

#
# postsrsd
#

@test "checking SRS: SRS_DOMAINNAME is used correctly" {
  wait_for_finished_setup_in_container mail_srs_domainname
  run docker exec mail_srs_domainname grep "SRS_DOMAIN=srs.my-domain.com" /etc/default/postsrsd
  assert_success
}

@test "checking SRS: DOMAINNAME is handled correctly" {
  wait_for_finished_setup_in_container mail_domainname
  run docker exec mail_domainname grep "SRS_DOMAIN=my-domain.com" /etc/default/postsrsd
  assert_success
}

@test "last" {
    skip 'only used to call teardown_file from teardown'
}