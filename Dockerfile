# Use node 18 on Alpine Linux
FROM node:18-alpine

# Creates a non-root user
RUN addgroup -S fd && adduser -S -g fd fd
ENV APP=/home/fd

# Install required packages
RUN apk add --no-cache openssh-client git bash ca-certificates lz4-dev musl-dev cyrus-sasl-dev openssl-dev \
    && apk add --no-cache --virtual .build-deps gcc zlib-dev libc-dev bsd-compat-headers py-setuptools bash \
    && apk add --update python3 make g++ curl \
    && rm -rf /var/cache/apk/*

# Install glibc
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
    && apk add glibc-2.35-r1.apk

ARG SSH_PRIVATE_KEY

# Create .ssh directory for fd and add gitrepossh.rapidops.com to known_hosts
RUN mkdir -p -m 0700 /home/fd/.ssh && \
    touch /home/fd/.ssh/id_rsa && \
    chmod 0600 /home/fd/.ssh/id_rsa && \
    ssh-keyscan gitrepossh.rapidops.com >> /home/fd/.ssh/known_hosts

WORKDIR $APP

ENV PATH /$APP/node_modules/.bin:$PATH

# Copy package.json file and install node modules
COPY ./package.json .
RUN --mount=type=ssh npm install

# Copy other files from src
COPY ./src ./src

# Expose port 8080
EXPOSE 8080

# Command to start the application
CMD ["npm", "run", "prod-start"]
