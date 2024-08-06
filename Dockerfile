# syntax=docker/dockerfile:experimental
# Build: DOCKER_BUILDKIT=1 docker build --ssh default -t object-service .

FROM node:16-alpine

# Creates a non-root-user.
RUN addgroup -S dd && adduser -S -g dd dd

ENV APP=/home/dd

# Install required packages and build dependencies with specific versions to resolve vulnerabilities
RUN apk update \
    && apk upgrade \
    && apk add --no-cache openssh-client git bash ca-certificates lz4-dev musl-dev cyrus-sasl-dev openssl=1.1.1l-r0 \
    && apk add --no-cache --virtual .build-deps gcc zlib=1.2.11-r4 libc-dev bsd-compat-headers py-setuptools \
    && apk add --update python2 python3 make g++ curl \
    && curl -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && curl -LO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk \
    && apk add glibc-2.32-r0.apk \
    && apk add openjdk8 \
    && apk add busybox=1.31.1-r11 ssl_client=1.31.1-r11 apk-tools=2.10.7-r0 \
    && rm -rf /var/cache/apk/*

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

# Create .ssh directory and add gitssh.rapidops.com to known_hosts
RUN mkdir -p /home/dd/.ssh \
    && ssh-keyscan -p 6611 gitrepossh.rapidops.com >> /home/dd/.ssh/known_hosts \
    && chown -R dd:dd /home/dd/.ssh

WORKDIR $APP

# Copy package.json file
COPY --chown=dd:dd ./package.json .

# Install node modules
RUN --mount=type=ssh npm install

# Copy other files from src
COPY --chown=dd:dd ./src ./src

# Expose port
EXPOSE 8080

# Commands to be fired from CMD as the user
USER dd
CMD ["npm", "run", "start-dev"]
# Commands to be fired from CMD as the user
USER dd
CMD ["npm", "run", "start-dev"]


