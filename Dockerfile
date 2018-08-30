FROM alpine

ENV http_proxy http://proxy.dmz.mdc1.mozilla.com:3128/
ENV https_proxy http://proxy.dmz.mdc1.mozilla.com:3128/

RUN apk add ca-certificates
RUN update-ca-certificates

# build-base and python3-dev might be required by honeycomb plugins
RUN apk add --no-cache build-base python3-dev tini bash curl && \
    curl https://bootstrap.pypa.io/get-pip.py | python3 && \ 
    pip install virtualenv

# ensure honeycomb user exists
RUN set -x && \
    addgroup -g 1000 -S honeycomb && \
    adduser -u 1000 -D -S -G honeycomb honeycomb

# set default home and permissions
RUN mkdir /usr/share/honeycomb && chown -vR honeycomb:honeycomb /usr/share/honeycomb

# install honeycomb
COPY requirements.txt /app/requirements.txt
WORKDIR /app
RUN virtualenv /app/venv && \
    /app/venv/bin/pip install -r requirements.txt
ENV PATH /app/venv/bin:${PATH}

COPY . /app/
RUN pip install --editable .

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN cap_net_bind_service=+ep' $(which honeycomb)'

# fix permissions and drop privileges
RUN chown honeycomb:honeycomb -R /app
#USER honeycomb

ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /usr/share/honeycomb
CMD ["honeycomb", "-v", "--iamroot", "--config", "/usr/share/honeycomb/honeycomb.yml"]
