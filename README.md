<p align="center" style="margin-bottom: 2em">
  <img src="https://v1.bootstrapemail.com/img/icons/logo.png" alt="Bootstrap Email Logo" width="40%"/>
</p>

<br>

## Bootstrap Email Mail Gateway Service

This is a cookbook recipe that makes use of [midi-smtp-server](https://github.com/4commerce-technologies-AG/midi-smtp-server) and
[Bootstrap Email](https://v1.bootstrapemail.com/) to process incoming E-Mails through Bootstrap Email to finally transfer the mail to some relay host.

### Settings

The service may be adjusted by some ENV variables:

##### BOOTSTRAP_EMAIL_RELAY_HOST

The relay host to forward the mail. It must be provided.

##### BOOTSTRAP_EMAIL_RELAY_PORT="465"

The relay host port.

##### BOOTSTRAP_EMAIL_RELAY_USERNAME=""

The relay host username.

##### BOOTSTRAP_EMAIL_RELAY_PASSWORD=""

The relay host password.

##### BOOTSTRAP_EMAIL_RELAY_TLS="false"

Set to true if relay host require `STARTTLS`.

##### BOOTSTRAP_EMAIL_RELAY_SSL=""

Set to true if relay host require `SSL`.

##### BOOTSTRAP_EMAIL_GW_HOSTS="0.0.0.0"

The ip-address(es) the mail gateway is listen on.

##### BOOTSTRAP_EMAIL_GW_PORTS="25"

The port(s) the mail gateway is listen on.

##### BOOTSTRAP_EMAIL_GW_MAX_PROCESSINGS="4"

The number of simultaneously processes.

##### BOOTSTRAP_EMAIL_GW_MAX_CONNECTIONS="100"

The number of simultaneously connections.

##### BOOTSTRAP_EMAIL_GW_INTERNATIONALIZATION=""

Enable internationalization smtp extension.

##### BOOTSTRAP_EMAIL_GW_DEBUG=""

Enable SMTP session debug logs.

### Usage

```sh
export BOOTSTRAP_EMAIL_RELAY_HOST="some.smtp.server"
export BOOTSTRAP_EMAIL_GW_DEBUG="true"
ruby service/bootstrap-email-smtp-server.rb
```

### Usage with Docker

```sh
docker build --tag bootstrap-email-smtp-server .
docker run -it --name bootstrap-email-smtp-server --publish 25:25 \
  --env BOOTSTRAP_EMAIL_RELAY_HOST="some.smtp.server." \
  --env BOOTSTRAP_EMAIL_GW_DEBUG=1 bootstrap-email-smtp-server
```

### Author & Credits

Author: [Kumy](http://github.com/kumy)

Based on Slack recipe from [Tom Freudenberg, 4commerce technologies AG](https://github.com/4commerce-technologies-AG/midi-smtp-server/tree/master/cookbook/recipe-slack), released under the MIT license
