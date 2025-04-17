FROM ruby:3.4

ENV BOOTSTRAP_EMAIL_GW_HOSTS="0.0.0.0" \
    BOOTSTRAP_EMAIL_GW_PORTS=25

COPY ./src/ /app/
WORKDIR /app

RUN ruby -v \
 && gem update --system | head -n 8 \
 && bundle config set --local path '.ruby/gems' \
 && GEMRC="Gemrc.yml" bundle install

CMD ["bundle", "exec", "ruby", "service/bootstrap-email-smtp-server.rb"]
