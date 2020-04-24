# Use CTFd official image as base
FROM ctfd/ctfd:latest as ctfd

FROM alpine:3.11
USER root
WORKDIR /opt/CTFd

COPY --from=ctfd /opt/CTFd/requirements.txt .

# Install build deps, then run `pip install`, then remove unneeded build deps all in a single step. Correct the path to your production requirements fil
RUN apk add --no-cache \
        python3 \
        py3-yaml \
        py3-requests \
        py3-bcrypt \
        py3-cffi \
        py3-hiredis \
        py3-gevent \
        py3-pyrsistent \
        py3-greenlet \
        py3-markupsafe \
        py3-attrs \
        py3-dateutil \
        py3-boto \
        py3-sqlalchemy \
        py3-psycopg2 \
    && \
        apk add --no-cache --virtual .build-deps  \
            git \
            build-base \
            python3-dev \
            libffi-dev \
            openssl-dev \
    && \
        pip3 install -r requirements.txt \
    && \
        for d in CTFd/plugins/*; do \
         if [ -f "$d/requirements.txt" ]; then \
             pip install -r $d/requirements.txt --no-cache-dir; \
         fi; \
        done; \
        apk del .build-deps --force-broken-world \
    && \
        find /usr/local -depth \
            \( \
                \( -type d -a \( -name test -o -name tests \) \) \
                -o \
                \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
            \) -exec rm -rf '{}' + \
        && rm -rf /usr/src/python \
        && rm -rf /root/.cache

# Show package versions
RUN pip3 freeze

COPY --from=ctfd /opt/CTFd .

# Replace docker-entrypoint for the postgres compatible one
ADD docker-entrypoint.sh .

RUN mkdir -p /var/log/CTFd /var/uploads

RUN adduser -D -u 1001 -s /bin/sh ctfd
RUN chown -R 1001:1001 /opt/CTFd /var/log/CTFd /var/uploads

USER 1001

EXPOSE 8000

CMD ["/opt/CTFd/docker-entrypoint.sh"]