# syntax=docker/dockerfile:experimental
# Build: DOCKER_BUILDKIT=1 docker build --ssh default -t object-service .

FROM node:22.5.0-bookworm-slim 

# Creates a non-root user
RUN addgroup -S dd && adduser -S -g dd dd

ENV APP=/home/dd

# Install openssh-client and git (required because we are using a private repo)
RUN apt-get update && apt-get install -y \
    openssh-client git bash ca-certificates lz4-dev musl-dev cyrus-sasl-dev openssl-dev \
    gcc zlib1g-dev libc-dev bsd-compat-headers python-setuptools bash \
    python2 python3 make g++ curl \
    && rm -rf /var/lib/apt/lists/*

# Install OpenJDK 8
RUN apt-get update && apt-get install -y openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH $PATH:/usr/lib/jvm/java-8-openjdk-amd64/jre/bin:/usr/lib/jvm/java-8-openjdk-amd64/bin

# Create .ssh directory and add gitrepossh.rapidops.com to known_hosts
RUN mkdir -p /home/dd/.ssh && ssh-keyscan -p 6611 gitrepossh.rapidops.com >> /home/dd/.ssh/known_hosts

WORKDIR $APP

# Copy package.json file
COPY ./package.json .

# Install node modules using SSH for private repositories
RUN --mount=type=ssh npm install

# Copy other files from src
COPY ./src ./src

# Expose port 8080
EXPOSE 8080

# Commands to be fired from CMD as the user
CMD ["npm", "run", "start-dev"]
