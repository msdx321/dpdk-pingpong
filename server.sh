sudo ./build/pingpong --file-prefix=server  \
    --no-huge \
    --no-pci \
    --lcores '0@(0-5)' \
    --vdev 'net_virtio_user1,mac=00:00:00:00:00:01,path=/var/run/openvswitch/vhost-user1' \
    -- \
    -p 0 -s --server_mac=00:00:00:00:00:01 --server_ip=10.10.1.2
