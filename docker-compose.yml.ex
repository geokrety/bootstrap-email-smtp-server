---
version: '2.4'
services:
  bootstrap-email:
    image: geokrety-postfix-bootstrap:latest
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ./src:/app
    ports:
      - "25:25"
    environment:
      - POSTFIX_HOSTNAME=kumy.net
      - BOOTSTRAP_EMAIL_RELAY_HOST=smtp.google.com
      - BOOTSTRAP_EMAIL_RELAY_PORT=465
      - BOOTSTRAP_EMAIL_RELAY_USERNAME=username
      - BOOTSTRAP_EMAIL_RELAY_PASSWORD=password
      - BOOTSTRAP_EMAIL_RELAY_TLS=true
      - BOOTSTRAP_EMAIL_GW_HOSTS=0.0.0.0
      - BOOTSTRAP_EMAIL_GW_PORTS=25
      - BOOTSTRAP_EMAIL_GW_INTERNATIONALIZATION=true
      - BOOTSTRAP_EMAIL_GW_DEBUG=true
    # command:
    #   - /usr/local/bin/ruby
    #   - server.rb
    # command:
    #   - sh
    #   - -c
    #   - "sleep 10000"
