# Buildroot for TinyEMU

This repo is a quick getting started guide on how to build kernel and rootfs using Buildroot for TinyEMU

The current configuration is a minimal kernel with no networking, though it should be easy to change.

If you're not ready to build your own, you can start get a ready made kernel, rootfs and bbl from [TinyEMU](https://bellard.org/tinyemu/), at the bottom there's [diskimage-linux-riscv-2018-09-23.tar.gz](https://bellard.org/tinyemu/diskimage-linux-riscv-2018-09-23.tar.gz).

# BBL - Berkely boot loader
To build BBL, you'll find the patches needed for [RISC-V Proxy Kernel](https://github.com/riscv-software-src/riscv-pk) in [diskimage-linux-riscv-2018-09-23.tar.gz](https://bellard.org/tinyemu/diskimage-linux-riscv-2018-09-23.tar.gz).

# Getting Started

## Building the docker image
```
docker build -t buildroot .
```

## Running the docker image
```
docker run -it buildroot
```

At this point you have a ready made machine to start building your rootfs and kernel:
```
make -j 5
```

Once its done, you'll find 2 files in output/images:
```
~/buildroot-2022.05# ls -l output/images
total 10252
-rw-r--r-- 1 root root  2172016 Jul 12 11:36 Image
-rw-r--r-- 1 root root 20971520 Jul 12 11:36 rootfs.ext2
```

Now we want to copy them into our virtual riscv machine:
```
docker cp <container id>:/root/buildroot-2022.05/output/images/Image kernel32.bin
docker cp <container id>:/root/buildroot-2022.05/output/images/rootfs.ext2 rootfs32.bin
```

Make sure you have bbl32.bin and TinyEMU configuration file:
```
/* VM configuration file */
{
    version: 1,
    machine: "riscv32",
    memory_size: 12,
    bios: "bbl32.bin",
    kernel: "kernel32.bin",
    cmdline: "console=hvc0 debug ignore_loglevel earlycon=sbi root=/dev/vda rw",
    drive0: { file: "rootfs32.bin" }
}
```

And you're ready to go, either copy it to your SD card under /emu or run tinyemu from the command line
```
<tinyemu executable> riscv32.cfg
```

If you choose to run it on ESP32 through my [esp32-tinyemu](https://github.com/drorgl/esp32-tinyemu), you'll see something very similar to this:
[![IMAGE ALT TEXT HERE](https://img.youtube.com/vi/f3a3xeTRj_A/0.jpg)](https://www.youtube.com/watch?v=f3a3xeTRj_A)

# Quick Cheat Sheet for Buildroot
configure buildroot:
```
make menuconfig
```

configure busybox:
```
make busybox-menuconfig
```

configure kernel:
```
make linux-menuconfig
```

rebuild whole system:
```
make clean all -j 5
```

persist your buildroot configuration:
```
make savedefconfig
docker cp <container id>:/root/buildroot-2022.05/buildroot_rv32_config buildroot_config/buildroot_rv32_config
```

persist your kernel configuration:
```
make linux-update-defconfig
docker cp <container id>:/root/buildroot-2022.05/linux_rv32_config buildroot_config/linux_rv32_config
```

persist your busybox configuration:
```
make busybox-update-config
docker cp <container id>:/root/buildroot-2022.05/busybox_config buildroot_config/busybox_config
```

# Notes
* This docker image was customized to use axel for downloading dependencies with multiple connections, you might not need it on your network.
* The configured overlay skips init and goes straight to bash, you'll need to remove it to work with getty (BR2_ROOTFS_OVERLAY and BR2_TARGET_GENERIC_GETTY_OPTIONS)
