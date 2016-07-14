#!/usr/bin/env bats

setup() {
  docker history "$REGISTRY/$REPOSITORY:$TAG" >/dev/null 2>&1
  export IMG="$REGISTRY/$REPOSITORY:$TAG"
  export MAX_SIZE=2000000
}

teardown() {
  service nginx stop
  rm /etc/nginx/conf.d/kibana.htpasswd || true
  rm /etc/nginx/sites-enabled/kibana || true
  rm /var/log/nginx/access.log || true
  rm /var/log/nginx/error.log || true
  pkill tcpserver || true
  pkill nc || true
  rm -f "/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
  rm -f "/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
}

@test "checking image size" {
  run docker run --rm --entrypoint=/bin/sh $IMG -c "[[ \"\$(du -d0 / 2>/dev/null | awk '{print \$1; print > \"/dev/stderr\"}')\" -lt \"$MAX_SIZE\" ]]"
  [ $status -eq 0 ]
}

@test "Kibana requires the AUTH_CREDENTIALS environment variable to be set" {
  export DATABASE_URL=foobar
  run timeout 1 /bin/bash kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "AUTH_CREDENTIALS" ]]
}

@test "Kibana requires the DATABASE_URL environment variable to be set" {
  export AUTH_CREDENTIALS=foobar
  run timeout 1 /bin/bash kibana.sh
  [ "$status" -eq 1 ]
  [[ "$output" =~ "DATABASE_URL" ]]
}

@test "Kibana redirects any http requests permanently to https" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost timeout 1 /bin/bash kibana.sh || true
  REDIRECT_301="301 Moved Permanently"
  run bash -c 'curl http://localhost | grep "$REDIRECT_301" && \
               curl http://localhost/_aliases | grep "$REDIRECT_301" && \
               curl http://localhost/foo/_aliases | grep "$REDIRECT_301" && \
               curl http://localhost/_nodes | grep "$REDIRECT_301" && \
               curl http://localhost/foobar/_search | grep "$REDIRECT_301" && \
               curl http://localhost/foobar/_mapping | grep "$REDIRECT_301" && \
               curl http://localhost/kibana-int/dashboard/foo | grep "$REDIRECT_301" && \
               curl http://localhost/kibana-int/tempfoo | grep "$REDIRECT_301"'
  [ "$status" -eq 0 ]
}

@test "Kibana protects all pages with basic auth" {
  XFP="X-Forwarded-Proto: https"
  ERROR_401="401 Authorization Required"
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost timeout 1 /bin/bash kibana.sh || true
  run bash -c 'curl -H "$XFP" http://localhost | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/_aliases | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foo/_aliases | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/_nodes | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foobar/_search | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/foobar/_mapping | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/kibana-int/dashboard/foo | grep "$ERROR_401" && \
               curl -H "$XFP" http://localhost/kibana-int/tempfoo | grep "$ERROR_401"'
  [ "$status" -eq 0 ]
}

@test "Kibana sets the elasticsearch url correctly for Kibana 4.1.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=41 timeout 1 /bin/bash kibana.sh || true
  run grep "elasticsearch_url: \"http://root:admin123@localhost:1234\"" "/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "Kibana sets the elasticsearch username correctly for Kibana 4.1.x" {
 AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=41 timeout 1 /bin/bash kibana.sh || true
 run grep "Kibana_elasticsearch_username: \"root\"" "/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
 [ "$status" -eq 0 ]
}

@test "Kibana sets the elasticsearch password correctly for Kibana 4.1.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=41 timeout 1 /bin/bash kibana.sh || true
  run grep "Kibana_elasticsearch_password: \"admin123\"" "/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "Kibana sets the elasticsearch url correctly for Kibana 4.4.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=44 timeout 1 /bin/bash kibana.sh || true
  run grep "elasticsearch.url: \"http://root:admin123@localhost:1234\"" "/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

@test "Kibana sets the elasticsearch username correctly for Kibana 4.4.x" {
 AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=44 timeout 1 /bin/bash kibana.sh || true
 run grep "elasticsearch.username: \"root\"" "/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
 [ "$status" -eq 0 ]
}

@test "Kibana sets the elasticsearch password correctly for Kibana 4.4.x" {
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://root:admin123@localhost:1234 KIBANA_ACTIVE_VERSION=44 timeout 1 /bin/bash kibana.sh || true
  run grep "elasticsearch.password: \"admin123\"" "/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml"
  [ "$status" -eq 0 ]
}

HTTP_RESPONSE_HEAD="HTTP/1.1 200 OK

"

@test "Kibana detects Elasticsearch 1.x" {
  # Kibana will actually fail to start here, because "Elasticsearch" will go
  # down after the initial request, but it doesn't really matter: we're only
  # checking which configuration files get created.
  echo "$HTTP_RESPONSE_HEAD" '{"version": {"number": "1.5.2"}}' | nc -l 456 &
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost:456 run timeout 1 /bin/bash kibana.sh
  [[ ! -f "/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml" ]]
  [[ -f "/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml" ]]
}

@test "Kibana detects Elasticsearch 2.x" {
  # Same notes as above.
  echo "$HTTP_RESPONSE_HEAD" '{"version": {"number": "2.2.0"}}' | nc -l 456 &
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://localhost:456 run timeout 1 /bin/bash kibana.sh
  [[ -f "/kibana-${KIBANA_44_VERSION}-linux-x64/config/kibana.yml" ]]
  [[ ! -f "/kibana-${KIBANA_41_VERSION}-linux-x64/config/kibana.yml" ]]
}

@test "Kibana proxies with credentials to Elasticsearch 2.x" {
  web_log="${BATS_TEST_DIRNAME}/web.log"
  ( while echo "$HTTP_RESPONSE_HEAD" '{"version": {"number": "2.2.0"}}' | nc -l 456; do : ; done ) > "$web_log" &
  AUTH_CREDENTIALS=root:admin123 DATABASE_URL=http://user:pass@localhost:456 /bin/bash kibana.sh &
  # Hit Kibana directly on port 5601
  until curl "localhost:5601/elasticsearch/.kibana/visualization/_search"; do
    echo "Waiting for Kibana to come online"
    sleep 1
  done

  pkill node
  pkill nc

  # Check that a authorization header was sent to "Elasticsearch"
  grep -A8 ".kibana/" "$web_log" | grep -i "Authorization: Basic"
}
