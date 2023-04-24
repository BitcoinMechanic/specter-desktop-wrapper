ARG USER=specter
ARG DIR=/data/

FROM python:3.10-slim-bullseye AS builder

ARG VERSION
ARG REPO

RUN apt update && apt install -y git build-essential libusb-1.0-0-dev libudev-dev libffi-dev libssl-dev rustc cargo libpq-dev

WORKDIR /build

COPY specter-desktop/ ./specter-desktop
COPY ./.git ./.git

WORKDIR specter-desktop

#RUN ls -al && sleep 30

RUN pip3 install --upgrade pip
RUN pip3 install babel cryptography
RUN pip3 install .

FROM python:3.10-slim-bullseye AS final

# arm64 or amd64
ARG PLATFORM
ARG USER
ARG DIR
RUN apt update && apt install -y libusb-1.0-0-dev libudev-dev wget
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_${PLATFORM}.tar.gz -O - |\
    tar xz && mv yq_linux_${PLATFORM} /usr/bin/yq
# NOTE: Default GID == UID == 1000
RUN adduser --disabled-password \
            --home "$DIR" \
            --gecos "" \
            "$USER"
# Set user
USER $USER
# Make config directory
RUN mkdir -p "$DIR/.specter/"
# Copy over python stuff
COPY --from=builder /usr/local/lib/python3.10 /usr/local/lib/python3.10
COPY --from=builder /usr/local/bin /usr/local/bin

USER root

# Import Entrypoint and give permissions
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh

EXPOSE 25441 25442 25443

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
