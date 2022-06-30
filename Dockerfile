ARG USER=specter
ARG DIR=/data/
ARG VERSION=v1.10.3
ARG REPO=https://github.com/cryptoadvance/specter-desktop
FROM python:3.9-slim-bullseye AS builder
RUN apt update && apt install -y git build-essential libusb-1.0-0-dev libudev-dev libffi-dev libssl-dev
ARG VERSION
ARG REPO
WORKDIR /
RUN git clone $REPO 
WORKDIR /specter-desktop
#RUN git pull
#COPY specter-desktop/ .
RUN git checkout $VERSION
RUN sed -i "s/vx.y.z-get-replaced-by-release-script/${VERSION}/g; " setup.py
RUN pip3 install --upgrade pip
RUN pip3 install babel cryptography
RUN pip3 install .

FROM python:3.9-slim-bullseye AS final
ARG USER
ARG DIR
RUN apt update && apt install -y libusb-1.0-0-dev libudev-dev wget
RUN wget https://github.com/mikefarah/yq/releases/download/v4.12.2/yq_linux_arm.tar.gz -O - |\
    tar xz && mv yq_linux_arm /usr/bin/yq
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
COPY --from=builder /usr/local/lib/python3.9 /usr/local/lib/python3.9
COPY --from=builder /usr/local/bin /usr/local/bin

USER root

# Import Entrypoint and give permissions
ADD ./docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
RUN chmod a+x /usr/local/bin/docker_entrypoint.sh
ADD assets/utils/check-web.sh /usr/local/bin/check-web.sh
RUN chmod +x /usr/local/bin/check-web.sh

EXPOSE 25441 25442 25443

ENTRYPOINT ["/usr/local/bin/docker_entrypoint.sh"]
