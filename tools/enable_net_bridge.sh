ip=`ifconfig eth0 | grep "inet addr" | cut -d':' -f2 | cut -d' ' -f1`
route=`route -n | head -3 | tail -1 | tr -s ' ' | cut -d' ' -f2`

echo $ip $route

brctl addbr br0
brctl addif br0 eth0
ifconfig eth0 down
ifconfig eth0 0.0.0.0 up
ifconfig br0 $ip up
route add default gw $route br0
