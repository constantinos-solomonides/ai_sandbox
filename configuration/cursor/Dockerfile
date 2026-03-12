FROM ubuntu:latest AS step1
RUN     apt update \
    &&  DEBIAN_FRONTEND=non-interactive apt install -y \
            curl    \
    &&  rm -rf \
            /var/lib/apt/* \
            /var/cache/apt/archives/*

FROM step1 AS cursor
RUN    curl https://cursor.com/install -fsS | bash \
    && echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc
