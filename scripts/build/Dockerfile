FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i -e s@//archive.ubuntu.com@//mirrors.ustc.edu.cn@g \
           -e s@//security.ubuntu.com@//mirrors.ustc.edu.cn@g \
           /etc/apt/sources.list
RUN apt-get update && apt-get install -y --no-install-recommends \
      libstdc++-12-dev binutils binutils-dev git gnupg flex bison gperf \
      build-essential zip curl zlib1g-dev gcc-multilib libc6-dev-i386 \
      libx11-dev ccache libgl1-mesa-dev libxml2-utils xsltproc unzip \
      m4 bc gnutls-bin ruby genext2fs device-tree-compiler make \
      libffi-dev e2fsprogs pkg-config perl openssl libssl-dev libelf-dev \
      libdwarf-dev u-boot-tools mtd-utils cpio liblz4-tool gcc g++ \
      texinfo dosfstools mtools apt-utils wget scons tar rsync git-core \
      libxml2-dev grsync xxd libglib2.0-dev libpixman-1-dev kmod jfsutils \
      reiserfsprogs xfsprogs squashfs-tools pcmciautils quota ppp \
      libtinfo-dev libstdc++6 gcc-arm-none-eabi vim ssh locales \
      libxinerama-dev libxcursor-dev libxrandr-dev libxi-dev python3 \
      python3-requests && \
    (apt-get install -y --no-install-recommends git-lfs libncurses5 libtinfo5 \
      openjdk-8-jre-headless doxygen || true) && \
    rm -rf /var/lib/apt/lists/*
RUN git lfs install --system || true
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3-pip python3-venv python3-setuptools && \
    rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      autoconf automake libtool libtool-bin openjdk-8-jdk-headless libfl-dev gawk gettext autopoint && \
    rm -rf /var/lib/apt/lists/*
RUN groupadd -g 1005 ohos && useradd -u 1005 -g 1005 -d /home/ohos -s /bin/bash ohos && \
    mkdir -p /home/ohos/openharmony_prebuilts /ccache && \
    chown -R 1005:1005 /home/ohos /ccache
WORKDIR /home/ohos
