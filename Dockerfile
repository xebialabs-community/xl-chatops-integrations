FROM ruby:2.1.10

ADD . /home/lita

RUN apt-get update
RUN apt-get install -y redis-server gcc make supervisor
RUN gem install lita
RUN cd /home/lita/sample-bot && bundle

# CMD cd /home/lita/sample-bot && lita
ADD resources/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD /usr/bin/supervisord

