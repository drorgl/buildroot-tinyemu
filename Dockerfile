FROM ubuntu:20.04

RUN apt-get update
RUN apt install -y software-properties-common
RUN add-apt-repository ppa:apt-fast/stable
RUN apt-get update
RUN apt-get -y install apt-fast

WORKDIR /root

# Install dependencies.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive\
    apt-get install -y build-essential libncurses5-dev rsync cpio python unzip bc wget axel aria2

# Install Buildroot.
RUN axel -n 10 https://buildroot.org/downloads/buildroot-2022.05.tar.gz &&\
    tar xf buildroot-*.tar* &&\
    rm buildroot-*.tar* &&\
    ln -s buildroot-* buildroot &&\
    mkdir -v buildroot/patches

# Create rootfs overlay.
RUN mkdir -vpm775 buildroot/rootfs_overlay
COPY ./overlay buildroot/rootfs_overlay

WORKDIR /root/buildroot

# Patch wget so it will work with axel and aria2c
COPY wget-o.patch ./
RUN patch -p1 < wget-o.patch

ENV ARCH=riscv

RUN make qemu_riscv32_virt_defconfig
RUN sed -i -e '/BR2_WGET=/ s/=.*/="axel -n 10  "/' .config

COPY buildroot_config/linux_rv32_config ./linux_rv32_config
COPY buildroot_config/buildroot_rv32_config ./
COPY buildroot_config/busybox_config ./

RUN make defconfig BR2_DEFCONFIG=buildroot_rv32_config
