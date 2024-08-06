# syntax=docker/dockerfile:experimental
# Build: DOCKER_BUILDKIT=1 docker build --ssh default -t object-service .

FROM mhart/alpine-node:14.21.3
#FROM gcr.io/c-and-b-2019/c-and-b-base:latest

# Creates a non-root-user.
RUN addgroup -S dd && adduser -S -g dd dd

ENV APP=/home/dd

# Install openssh-client and git (Require because we are using private repo)
RUN apk add --no-cache openssh-client git bash ca-certificates lz4-dev musl-dev cyrus-sasl-dev openssl-dev
RUN apk add --no-cache --virtual .build-deps gcc zlib-dev libc-dev bsd-compat-headers py-setuptools bash

RUN apk add --update python2 python3 make g++ curl\
   && rm -rf /var/cache/apk/*

RUN curl -o /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
&& curl -LO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.32-r0/glibc-2.32-r0.apk \
&& apk add glibc-2.32-r0.apk

#RUN wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" \
#        http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz \
#  && tar xvf jdk-8u131-linux-x64.tar.gz -C /opt \
#  && rm jdk-8u131-linux-x64.tar.gz \
#  && ln -s /opt/jdk1.8.0_131 /opt/jdk
#
#ENV JAVA_HOME /opt/jdk
#ENV PATH $PATH:/opt/jdk/bin

RUN apk add openjdk8

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin


# Create .ssh directory and add gitssh.rapidops.com to known_hosts
RUN mkdir -p ~/.ssh && ssh-keyscan -p 6611 gitrepossh.rapidops.com >> ~/.ssh/known_hosts

WORKDIR $APP

# copy package.json file
COPY ./package.json .

# Intall node modules
RUN --mount=type=ssh npm install


# Copy other files from src
COPY ./src ./src

# EXPOSE
EXPOSE 8080

# Commands to be fired from CMD as the user
CMD ["npm", "run", "start-dev"]
