# syntax=docker/dockerfile:experimental
# Build: DOCKER_BUILDKIT=1 docker build --ssh default -t object-service .

FROM mhart/alpine-node:14.17.3 AS base

# Use Alpine 3.18 as the base image
FROM alpine:3.18

# Creates a non-root-user.
RUN addgroup -S dd && adduser -S -g dd dd

ENV APP=/home/dd

# Install required packages and build dependencies with specific versions to resolve vulnerabilities
RUN apk update \
    && apk add --no-cache openssh-client git bash ca-certificates lz4-dev musl-dev cyrus-sasl-dev openssl=1.1.1u-r0 \
    && apk add --no-cache --virtual .build-deps gcc zlib=1.2.13-r0 libc-dev bsd-compat-headers py-setuptools \
    && apk add python2 python3 make g++ curl \
    && curl -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && curl -LO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r0/glibc-2.35-r0.apk \
    && apk add glibc-2.35-r0.apk \
    && apk add openjdk8 \
    && apk add busybox=1.36.1-r0 ssl_client=1.36.1-r0 apk-tools=2.12.12-r0 \
    && rm -rf /var/cache/apk/*

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

# Create .ssh directory and add gitssh.rapidops.com to known_hosts
RUN mkdir -p /home/dd/.ssh \
    && ssh-keyscan -p 6611 gitrepossh.rapidops.com >> /home/dd/.ssh/known_hosts \
    && chown -R dd:dd /home/dd/.ssh

WORKDIR $APP

# Copy package.json file
COPY --from=base --chown=dd:dd /package.json .

# Install node modules
RUN --mount=type=ssh npm install

# Copy other files from src
COPY --from=base --chown=dd:dd /src ./src

# Expose port
EXPOSE 8080

# Commands to be fired from CMD as the user
USER dd
CMD ["npm", "run", "start-dev"]


