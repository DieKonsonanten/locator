FROM ruby:2.3.4
MAINTAINER Die Konsonanten <dev@diekonsonanten.de>

ENV APP_HOME /opt/locator
ENV RACK_ENV production
ENV MAIN_APP_FILE locator.rb

RUN apt-get update && \
    apt-get upgrade -y 
RUN apt-get install -q -y vim libsasl2-modules 
# Install Postfix.
run echo "postfix postfix/main_mailer_type string Internet site" > preseed.txt
run echo "postfix postfix/mailname string locator.essig.one" >> preseed.txt
# Use Mailbox format.
run debconf-set-selections preseed.txt
run DEBIAN_FRONTEND=noninteractive apt-get install -q -y postfix

RUN mkdir -p $APP_HOME

WORKDIR $APP_HOME
COPY . $APP_HOME/

RUN cp $APP_HOME/postfix/* /etc/postfix
RUN postmap /etc/postfix/sasl_passwd
RUN chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

RUN bundle && bundle exec rake install

EXPOSE 4567

CMD ["sh", "-c", "service postfix start ; locator"]
