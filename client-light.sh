sudo ./build/pingpong --file-prefix=client \
    --socket-mem=1024 \
    --no-pci \
    --lcores '0@(0-5)' \
    --vdev 'net_virtio_user2,mac=00:00:00:00:00:02,path=/var/run/openvswitch/vhost-user2' \
    -- \
    -p 0 -n 20000 --client_mac=00:00:00:00:00:02 --server_mac=00:00:00:00:00:01
