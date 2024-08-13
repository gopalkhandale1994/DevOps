FROM node:18-alpine

# Add user and group
RUN addgroup -S dd && adduser -S -g dd dd

# Set environment variable
ENV APP=/home/dd

# Install dependencies and build tools
RUN apk add --no-cache openssh-client git bash ca-certificates lz4-dev musl-dev cyrus-sasl-dev openssl-dev \
    && apk add --no-cache --virtual .build-deps gcc zlib-dev libc-dev bsd-compat-headers py-setuptools bash \
    && apk add --update python3 make g++ curl \
    && rm -rf /var/cache/apk/*

# Install glibc
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk \
    && apk add glibc-2.35-r1.apk

# Install OpenJDK 8
RUN apk add openjdk8
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

# Set up SSH keys
RUN mkdir -p -m 0700 /home/dd/.ssh && \
    touch /home/dd/.ssh/id_rsa && \
    chmod 0600 /home/dd/.ssh/id_rsa && \
    ssh-keyscan -p 6611 gitrepossh.rapidops.com >> /home/dd/.ssh/known_hosts

# Set working directory
WORKDIR $APP

# Set PATH for npm
ENV PATH /$APP/node_modules/.bin:$PATH

# Copy package.json and install npm dependencies
COPY ./package.json .


# Install npm dependencies
RUN --mount=type=ssh npm install

# Install npm-check-updates globally
RUN --mount=type=ssh npm install -g npm-check-updates

# Copy source files
COPY ./src ./src

# Expose port 8080
EXPOSE 8080

# Command to start the application
CMD ["npm", "run", "start-dev"]
