FROM ubuntu:latest AS base

ENV DEBIAN_FRONTEND noninteractive
ENV PKGS="git curl"

# updates and some stuff
RUN apt-get update && apt-get -y full-upgrade && apt-get install -y sudo apt-utils software-properties-common $PKGS

FROM base AS dotfiles

ENV DEBIAN_FRONTEND noninteractive
ENV PKGS=""

# updates and some stuff
RUN apt-get update && apt-get -y full-upgrade && apt-get install -y $PKGS

# Add a test user
# add dev user
RUN adduser dev --disabled-password --gecos ""                          && \
    echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers     && \
    chown -R dev:dev /home/dev     

USER dev
WORKDIR /home/dev
VOLUME ["/home/dev/.dotfiles"]

CMD ["/home/dev/.dotfiles/install"]