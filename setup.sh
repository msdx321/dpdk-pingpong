echo 1 | sudo tee /sys/module/vfio/parameters/enable_unsafe_noiommu_mode
sudo dpdk-devbind.py -b vfio-pci 0b:00.0 13:00.0 1b:00.0
