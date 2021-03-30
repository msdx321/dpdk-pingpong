# DPDK Ping-Pong

A simple program to evaluate raw DPDK latency.

The client sends a packet to server as a `ping`, then the server returns it back to client as a `pong`. 
The client records such ping-pong round trip time.

`Note` that the following steps have been evaluated on:

- 2 Ubuntu 18.04 virtual machines (KVM) with DPDK 19.05 
- Fedora 33 with DPDK 20.11 on baremetal Intel x86_64

### Setup DPDK

With Ubuntu (from zylan29's work):

```shell
sudo apt-get install make gcc libnuma-dev pkgconf python
```

With Fedora 33:

```shell
sudo dnf install -y make gcc pkgconf python3 dpdk
```

and then edit Makefile to point to /usr/include/dpdk for include files and add -L/usr/lib64/dpdk to the link options,
or if you want to custom-build your DPDK from source, do something more like the above.

```shell
echo "export RTE_SDK=/root/dpdk-20.11" >> ~/.profile
```

for all distros:

```shell
echo "export RTE_TARGET=build" >> ~/.profile
. ~/.profile
make config T=x86_64-native-linuxapp-gcc
make
```


### Setup huge memory pages

1. Enable huge memory page by default.

``` shell
vim /etc/default/grub
# Append "default_hugepagesz=1GB hugepagesz=1G hugepages=8" to the end of line GRUB_CMDLINE_LINUX_DEFAULT.
```

For Debian/Ubuntu:
```
update-grub
```

For Fedora 33:
```
grub2-mkconfig
```

and reboot.

For all distros:

Check that this worked by looking at **/proc/cmdline** (kernel boot params) and **/dev/meminfo** for hugepage info

```
echo "nodev /mnt/huge hugetlbfs defaults 0 0" >> /etc/fstab
mount -v /mnt/huge
```

### Install user space NIC driver

For older machines that do not support VT-d virtualization:

```
modprobe uio
cd $RTE_SDK/build/kmod
insmod igb_uio.ko
```

For Fedora 33 with Intel x86_64 modern CPUs like Skylake that support VT-d virtualization:

add the options "intel_iommu=on iommu=pt" to the grub command line in the same way you did above for hugepages, then reboot.
BEFORE YOU DO THIS, make sure that you have enabled VT-d virtualization in the BIOS (under CPU options).  For example,

```
cat /proc/cpuinfo |grep -E "vmx|svm"
...
vmx flags	: vnmi preemption_timer posted_intr invvpid ept_x_only ept_ad ept_1gb flexpriority apicv tsc_offset vtpr mtf vapic ept vpid unrestricted_guest vapic_reg vid ple shadow_vmcs pml ept_mode_based_exec
```

### Bind NIC to userspace driver

For Ubuntu:

```
cd $RTE_SDK/usertools
./dpdk-devbind.py -s
./dpdk-devbind.py -b igb_uio $YOUR_NIC
```

For Fedora 33 on Intel x86_64 architecture, 
use these commands to enable the example interface "yourinterface" for DPDK on PCI slot ID xx:yy.z

```
ifdown yourinterface
dpdk-devbind.py --status
dpdk-devbind.py -u xx:yy.z
modprobe -v vfio-pci
dpdk-devbind.py --bind=vfio-pci xx:yy.z
dpdk-devbind.py --status
```

## Run
The valid parameters come after the "--" in the command line options, and are: 

- `-p` to specify the id of  which port to use, 0 by default (both sides), 
- `-n` to customize how many ping-pong rounds, 100 by default (client side), 
- `-s` to enable server mode (server side).
- `--client_mac` to specify the MAC address used by the client side
- `--client_ip` to specify the IP address used by the client side
- `--server_mac` to specify the MAC address used by the server side
- `--server_ip` to specify the IP address used by the server side

1. Make sure that NIC is properly binded to the DPDK-compible driver and huge memory page is configured on both client and server.

2. On the server side, ignoring the mac and IP addresses, this is how to run it:

```shell
sudo ./build/pingpong -l 1,2 -- -p 0 -s
```

3. On the client side, ignoring the mac and IP addresses, this is how to run it:

```shell
sudo ./build/pingpong -l 1,2 -- -p 0 -n 200
```

`Note` that >= 2 lcores are needed.

The output shoud be like this
```
====== ping-pong statistics =====
tx 200 ping packets
rx 200 pong packets
dopped 0 packets
min rtt: 50 us
max rtt: 15808 us
average rtt: 427 us
=================================
```
Note that this test is run on virtual machines, ignore the numbers.

## Issues

1. The 1st ping-pong round is very slow.
2. Only support directly connectted client and server NICs.
