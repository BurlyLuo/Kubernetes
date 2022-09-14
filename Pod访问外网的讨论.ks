Pod访问外网的讨论
在https://www.katacoda.com/courses/kubernetes/playground试验台下，我们创建出来两个Pods

master $ kubectl get pods -o wide
NAME                           READY     STATUS    RESTARTS   AGE       IP          NODE      NOMINATED NODE
demo-deploy-7f4dcbdd95-6fkzl   1/1       Running   0          54s       10.32.0.2   node01    <none>
demo-deploy-7f4dcbdd95-t76t2   1/1       Running   0          54s       10.32.0.3   node01    <none>
可以看出两个pod都是落在node01上的，所以我们查看对应节点上的iptables。如下：

node01 $ iptables -t nat -S
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-N DOCKER
-N KUBE-MARK-DROP
-N KUBE-MARK-MASQ
-N KUBE-NODEPORTS
-N KUBE-POSTROUTING
-N KUBE-SEP-2LZPYBS4HUAJKDFL
-N KUBE-SEP-3E4LNQKKWZF7G6SH
-N KUBE-SEP-JZWS2VPNIEMNMNB2
-N KUBE-SEP-OEY6JJQSBCQPRKHS
-N KUBE-SEP-U3DQP4T476Z362UG
-N KUBE-SERVICES
-N KUBE-SVC-ERIFXISQEP7F7OF4
-N KUBE-SVC-NPX46M4PTMTKRN6Y
-N KUBE-SVC-TCOU7JCQXEZGVUNU
-N WEAVE
-A PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING
-A POSTROUTING -s 172.18.0.0/24 ! -o docker0 -j MASQUERADE
-A POSTROUTING -j WEAVE
-A DOCKER -i docker0 -j RETURN
-A KUBE-MARK-DROP -j MARK --set-xmark 0x8000/0x8000
-A KUBE-MARK-MASQ -j MARK --set-xmark 0x4000/0x4000
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4000/0x4000 -j MASQUERADE
-A KUBE-SEP-2LZPYBS4HUAJKDFL -s 10.40.0.2/32 -m comment --comment "kube-system/kube-dns:dns-tcp" -j KUBE-MARK-MASQ
-A KUBE-SEP-2LZPYBS4HUAJKDFL -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp" -m tcp -j DNAT --to-destination 10.40.0.2:53
-A KUBE-SEP-3E4LNQKKWZF7G6SH -s 10.40.0.1/32 -m comment --comment "kube-system/kube-dns:dns-tcp" -j KUBE-MARK-MASQ
-A KUBE-SEP-3E4LNQKKWZF7G6SH -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp" -m tcp -j DNAT --to-destination 10.40.0.1:53
-A KUBE-SEP-JZWS2VPNIEMNMNB2 -s 10.40.0.2/32 -m comment --comment "kube-system/kube-dns:dns" -j KUBE-MARK-MASQ
-A KUBE-SEP-JZWS2VPNIEMNMNB2 -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 10.40.0.2:53
-A KUBE-SEP-OEY6JJQSBCQPRKHS -s 10.40.0.1/32 -m comment --comment "kube-system/kube-dns:dns" -j KUBE-MARK-MASQ
-A KUBE-SEP-OEY6JJQSBCQPRKHS -p udp -m comment --comment "kube-system/kube-dns:dns" -m udp -j DNAT --to-destination 10.40.0.1:53
-A KUBE-SEP-U3DQP4T476Z362UG -s 172.17.0.10/32 -m comment --comment "default/kubernetes:https" -j KUBE-MARK-MASQ
-A KUBE-SEP-U3DQP4T476Z362UG -p tcp -m comment --comment "default/kubernetes:https" -m tcp -j DNAT --to-destination 172.17.0.10:6443
-A KUBE-SERVICES -d 10.96.0.10/32 -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp cluster IP" -m tcp --dport 53 -j KUBE-SVC-ERIFXISQEP7F7OF4
-A KUBE-SERVICES -d 10.96.0.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-SVC-TCOU7JCQXEZGVUNU
-A KUBE-SERVICES -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -m tcp --dport 443 -j KUBE-SVC-NPX46M4PTMTKRN6Y
-A KUBE-SERVICES -m comment --comment "kubernetes service nodeports; NOTE: this must be the last rule in this chain" -m addrtype --dst-type LOCAL -j KUBE-NODEPORTS
-A KUBE-SVC-ERIFXISQEP7F7OF4 -m comment --comment "kube-system/kube-dns:dns-tcp" -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-3E4LNQKKWZF7G6SH
-A KUBE-SVC-ERIFXISQEP7F7OF4 -m comment --comment "kube-system/kube-dns:dns-tcp" -j KUBE-SEP-2LZPYBS4HUAJKDFL
-A KUBE-SVC-NPX46M4PTMTKRN6Y -m comment --comment "default/kubernetes:https" -j KUBE-SEP-U3DQP4T476Z362UG
-A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns" -m statistic --mode random --probability 0.50000000000 -jKUBE-SEP-OEY6JJQSBCQPRKHS
-A KUBE-SVC-TCOU7JCQXEZGVUNU -m comment --comment "kube-system/kube-dns:dns" -j KUBE-SEP-JZWS2VPNIEMNMNB2
-A WEAVE -s 10.32.0.0/12 -d 224.0.0.0/4 -j RETURN
-A WEAVE ! -s 10.32.0.0/12 -d 10.32.0.0/12 -j MASQUERADE
-A WEAVE -s 10.32.0.0/12 ! -d 10.32.0.0/12 -j MASQUERADE

对应着我自己的平台如下：
[root@k8s-1 ~]# kubectl get pods -o wide
NAME                           READY   STATUS    RESTARTS   AGE     IP            NODE    NOMINATED NODE   READINESS GATES
demo-deploy-78fdcf4547-cbhvq   1/1     Running   1          4d18h   10.244.1.23   k8s-2   <none>           <none>
[root@k8s-1 ~]#

[root@k8s-2 ~]# iptables -t nat -S
-P PREROUTING ACCEPT
-P INPUT ACCEPT
-P OUTPUT ACCEPT
-P POSTROUTING ACCEPT
-N DOCKER
-N KUBE-MARK-DROP
-N KUBE-MARK-MASQ
-N KUBE-NODEPORTS
-N KUBE-POSTROUTING
-N KUBE-SEP-2LQGWWW752DWZO5Z
-N KUBE-SEP-AV2WC22A3HJZ4BFH
-N KUBE-SEP-DBIXWRLYPXAFHH7Z
-N KUBE-SEP-QBYOR3DG3C3TY5L4
-N KUBE-SEP-QJ6PUN42T5XB236N
-N KUBE-SEP-TV7AWNMREAQBTUP4
-N KUBE-SERVICES
-N KUBE-SVC-ERIFXISQEP7F7OF4
-N KUBE-SVC-K7J76NXP7AUZVFGS
-N KUBE-SVC-NPX46M4PTMTKRN6Y
-N KUBE-SVC-TCOU7JCQXEZGVUNU
-A PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER
-A OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES
-A OUTPUT ! -d 127.0.0.0/8 -m addrtype --dst-type LOCAL -j DOCKER
-A POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING
-A POSTROUTING -s 172.17.0.0/16 ! -o docker0 -j MASQUERADE
-A POSTROUTING -s 10.244.0.0/16 -d 10.244.0.0/16 -j RETURN
-A POSTROUTING -s 10.244.0.0/16 ! -d 224.0.0.0/4 -j MASQUERADE
-A POSTROUTING ! -s 10.244.0.0/16 -d 10.244.1.0/24 -j RETURN
-A POSTROUTING ! -s 10.244.0.0/16 -d 10.244.0.0/16 -j MASQUERADE
-A DOCKER -i docker0 -j RETURN
-A KUBE-MARK-DROP -j MARK --set-xmark 0x8000/0x8000
-A KUBE-MARK-MASQ -j MARK --set-xmark 0x4000/0x4000
-A KUBE-POSTROUTING -m comment --comment "kubernetes service traffic requiring SNAT" -m mark --mark 0x4000/0x4000 -j MASQUERADE
-A KUBE-SEP-2LQGWWW752DWZO5Z -s 10.244.0.26/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-2LQGWWW752DWZO5Z -p tcp -m tcp -j DNAT --to-destination 10.244.0.26:53
-A KUBE-SEP-AV2WC22A3HJZ4BFH -s 10.244.0.26/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-AV2WC22A3HJZ4BFH -p udp -m udp -j DNAT --to-destination 10.244.0.26:53
-A KUBE-SEP-DBIXWRLYPXAFHH7Z -s 10.244.0.21/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-DBIXWRLYPXAFHH7Z -p tcp -m tcp -j DNAT --to-destination 10.244.0.21:53
-A KUBE-SEP-QBYOR3DG3C3TY5L4 -s 10.244.0.23/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-QBYOR3DG3C3TY5L4 -p tcp -m tcp -j DNAT --to-destination 10.244.0.23:44134
-A KUBE-SEP-QJ6PUN42T5XB236N -s 172.12.1.10/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-QJ6PUN42T5XB236N -p tcp -m tcp -j DNAT --to-destination 172.12.1.10:6443
-A KUBE-SEP-TV7AWNMREAQBTUP4 -s 10.244.0.21/32 -j KUBE-MARK-MASQ
-A KUBE-SEP-TV7AWNMREAQBTUP4 -p udp -m udp -j DNAT --to-destination 10.244.0.21:53
-A KUBE-SERVICES ! -s 10.244.0.0/16 -d 10.103.212.10/32 -p tcp -m comment --comment "kube-system/tiller-deploy:tiller cluster IP" -m tcp --dport 44134 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 10.103.212.10/32 -p tcp -m comment --comment "kube-system/tiller-deploy:tiller cluster IP" -m tcp --dport 44134 -j KUBE-SVC-K7J76NXP7AUZVFGS
-A KUBE-SERVICES ! -s 10.244.0.0/16 -d 10.96.0.10/32 -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp cluster IP" -m tcp --dport 53 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 10.96.0.10/32 -p tcp -m comment --comment "kube-system/kube-dns:dns-tcp cluster IP" -m tcp --dport 53 -j KUBE-SVC-ERIFXISQEP7F7OF4
-A KUBE-SERVICES ! -s 10.244.0.0/16 -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -m tcp --dport 443 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 10.96.0.1/32 -p tcp -m comment --comment "default/kubernetes:https cluster IP" -m tcp --dport 443 -j KUBE-SVC-NPX46M4PTMTKRN6Y
-A KUBE-SERVICES ! -s 10.244.0.0/16 -d 10.96.0.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-MARK-MASQ
-A KUBE-SERVICES -d 10.96.0.10/32 -p udp -m comment --comment "kube-system/kube-dns:dns cluster IP" -m udp --dport 53 -j KUBE-SVC-TCOU7JCQXEZGVUNU
-A KUBE-SERVICES -m comment --comment "kubernetes service nodeports; NOTE: this must be the last rule in this chain" -m addrtype --dst-type LOCAL -j KUBE-NODEPORTS
-A KUBE-SVC-ERIFXISQEP7F7OF4 -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-DBIXWRLYPXAFHH7Z
-A KUBE-SVC-ERIFXISQEP7F7OF4 -j KUBE-SEP-2LQGWWW752DWZO5Z
-A KUBE-SVC-K7J76NXP7AUZVFGS -j KUBE-SEP-QBYOR3DG3C3TY5L4
-A KUBE-SVC-NPX46M4PTMTKRN6Y -j KUBE-SEP-QJ6PUN42T5XB236N
-A KUBE-SVC-TCOU7JCQXEZGVUNU -m statistic --mode random --probability 0.50000000000 -j KUBE-SEP-TV7AWNMREAQBTUP4
-A KUBE-SVC-TCOU7JCQXEZGVUNU -j KUBE-SEP-AV2WC22A3HJZ4BFH
[root@k8s-2 ~]#

bash-4.4# ping 114.114.114.114
PING 114.114.114.114 (114.114.114.114): 56 data bytes
64 bytes from 114.114.114.114: seq=0 ttl=127 time=69.913 ms
^C
--- 114.114.114.114 ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 69.913/69.913/69.913 ms
bash-4.4# ping baidu.com
PING baidu.com (220.181.57.216): 56 data bytes
64 bytes from 220.181.57.216: seq=0 ttl=127 time=70.984 ms
^C
--- baidu.com ping statistics ---
1 packets transmitted, 1 packets received, 0% packet loss
round-trip min/avg/max = 70.984/70.984/70.984 ms
bash-4.4# nslookup baidu.com
nslookup: can't resolve '(null)': Name does not resolve

Name:      baidu.com
Address 1: 220.181.57.216
Address 2: 123.125.115.110
bash-4.4# 





##########
For More Information:BurlyLuo:<olaf.luo@foxmail.com>




