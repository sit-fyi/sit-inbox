FROM alpine:edge

RUN apk update
RUN apk add getmail daemontools ansible~=2.6 --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted
# maildrop
RUN wget -c https://downloads.sourceforge.net/project/courier/maildrop/2.9.3/maildrop-2.9.3.tar.bz2 && \
    wget -c https://downloads.sourceforge.net/project/courier/courier-unicode/2.0/courier-unicode-2.0.tar.bz2 && \
    apk add g++ make pcre-dev perl file && \
    tar xjvfp courier-unicode-2.0.tar.bz2 && rm -f courier-unicode-2.0.tar.bz2 && \
    cd courier-unicode-2.0 && ./configure && make && make install && \
    cd .. && rm -rf courier-unicode-2.0 && \
    tar xjvfp maildrop-2.9.3.tar.bz2 && rm -f maildrop-2.9.3.tar.bz2 && \
    cd maildrop-2.9.3 && mkdir /var/spool/mail && ./configure && make && make install-strip && \
    cd .. && rm -rf maildrop-2.9.3 && \
    apk del g++ make perl
RUN apk add git
RUN apk add py-pip && pip install -e git+https://github.com/dbohdan/remarshal@v0.8.0#egg=Remarshal 
RUN apk add bash coreutils msmtp dovecot shadow dialog ncurses util-linux
RUN git clone https://github.com/bats-core/bats-core && \
    cd bats-core && git checkout v1.1.0 && ./install.sh /usr/local && cd .. && rm -rf bats-core
RUN apk add curl && curl -s https://sit.fyi/install.sh | sh
RUN apk add nodejs npm && npm install -g ajv-cli
RUN ln -sf /usr/bin/msmtp /usr/sbin/sendmail
RUN echo "export PATH=/root/.sit-install:\$PATH" >> /root/.bashrc

VOLUME [ "/etc/sit-inbox", "/var/lib/repositories", "/var/run/oldmail" ]

ADD startup.sh /usr/bin/startup
ADD email-ingress /usr/bin/email-ingress
ADD playbook /playbook
ADD ansible /etc/ansible
ADD dovecot.conf /etc/dovecot/dovecot.conf
ADD schema.yaml /

CMD [ "startup" ]
