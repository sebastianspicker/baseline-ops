FROM mcr.microsoft.com/powershell:7.5-ubuntu-24.04@sha256:042240d57ec9e47e511033b92625a8d95875ee5860af3015992c248b58a8be81

ENV SRC=/src
ENV OUT=/out

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nodejs=18.19.1+dfsg-6ubuntu5 \
        npm=9.2.0~ds1-2 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p "$SRC" "$OUT"

COPY . "$SRC/win-mdm-security-hardening-kit"
WORKDIR "$SRC/win-mdm-security-hardening-kit"

COPY .clusterfuzzlite/build.sh "$SRC/build.sh"
