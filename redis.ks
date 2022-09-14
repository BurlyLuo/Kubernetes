为了快速搭建一个符合版本要求的redis集群，一开始由于找不到合适的redis slave docker image 而费神。后来准备自己做一个符合特定版本的redis slave 的image。
具体参考：https://github.com/BurlyLuo/Docker/blob/master/Dockerfile     https://github.com/BurlyLuo/Docker/blob/master/run.sh
根据修改Dockerfile中内容来实现想对应的redis slave 版本。
具体image如下：
[root@k8s-1 redis]# docker image ls 
REPOSITORY                                                       TAG                 IMAGE ID            CREATED             SIZE
redis-slave                                                      4.0.8               a8cc09832666        About an hour ago   107MB
而对于master节点的image，只需要在yaml文件中指定相应的版本即可，docker hub中有相应的版本。

Clone https://github.com/BurlyLuo/Docker/tree/master/install-redis/example
该目录下的文件。然后到对饮的kubernetes平台上部署即可。
效果如下：
[root@k8s-1 redis]# kubectl get pods -o wide 
NAME                           READY   STATUS    RESTARTS   AGE   IP             NODE    NOMINATED NODE   READINESS GATES
demo-deploy-78fdcf4547-hc7mx   1/1     Running   0          21h   10.244.1.179   k8s-2   <none>           <none>
demo-deploy-78fdcf4547-wfblf   1/1     Running   0          21h   10.244.1.178   k8s-2   <none>           <none>
frontend-98wn2                 1/1     Running   0          27m   10.244.1.182   k8s-2   <none>           <none>
frontend-fvnwb                 1/1     Running   0          27m   10.244.0.88    k8s-1   <none>           <none>
frontend-sp24m                 1/1     Running   0          27m   10.244.1.181   k8s-2   <none>           <none>
redis-master-b56c68cd8-nf86b   1/1     Running   0          27m   10.244.0.89    k8s-1   <none>           <none>
redis-slave-6c689b6bff-pjmbx   1/1     Running   0          27m   10.244.0.90    k8s-1   <none>           <none>
redis-slave-6c689b6bff-xtntp   1/1     Running   0          27m   10.244.1.180   k8s-2   <none>           <none>
然后分别在redis master和redis slave上查看：
先看redis  master
root@redis-master-b56c68cd8-nf86b:/data# redis-server  --version
Redis server v=4.0.8 sha=00000000:0 malloc=jemalloc-4.0.3 bits=64 build=51ec49f06079b708
[root@k8s-1 ~]# kubectl exec -it redis-master-b56c68cd8-nf86b  bash 
root@redis-master-b56c68cd8-nf86b:/data# redis-cli -h 10.244.0.89 
10.244.0.89:6379> 
10.244.0.89:6379> INFO replication
\# Replication
role:master
connected_slaves:2
slave0:ip=10.244.0.90,port=6379,state=online,offset=98,lag=1
slave1:ip=10.244.1.180,port=6379,state=online,offset=112,lag=1
master_replid:25169f9ba875f0048690cabbbc00d65ffd168d79
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:112
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:112
10.244.0.89:6379> exitt
(error) ERR unknown command 'exitt'
10.244.0.89:6379> exit
在看redis slave：
root@redis-slave-6c689b6bff-pjmbx:/data# redis-cli -h  10.244.0.90
10.244.0.90:6379> 
10.244.0.90:6379> 
10.244.0.90:6379> 
10.244.0.90:6379> INFO replication
# Replication
role:slave
master_host:10.109.255.111
master_port:6379
master_link_status:up
master_last_io_seconds_ago:5
master_sync_in_progress:0
slave_repl_offset:56
slave_priority:100
slave_read_only:1
connected_slaves:0
master_replid:25169f9ba875f0048690cabbbc00d65ffd168d79
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:56
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:1
repl_backlog_histlen:56
10.244.0.90:6379> exit
root@redis-slave-6c689b6bff-pjmbx:/data# 
root@redis-slave-6c689b6bff-pjmbx:/data# 
root@redis-slave-6c689b6bff-pjmbx:/data# redis-server --version
Redis server v=4.0.8 sha=00000000:0 malloc=jemalloc-4.0.3 bits=64 build=51ec49f06079b708

通过frontend  pod向redis master节点写数据可得。
先是redis maser节点：
root@redis-master-b56c68cd8-nf86b:/data# redis-cli -h 10.244.0.89 
10.244.0.89:6379> keys *
(empty list or set)
10.244.0.89:6379> keys *
1) "messages"
10.244.0.89:6379> get messages
",this is a test"
10.244.0.89:6379> 
然后是redis slave节点：
root@redis-slave-6c689b6bff-pjmbx:/data# redis-cli -h  10.244.0.90
10.244.0.90:6379> 
10.244.0.90:6379> 
10.244.0.90:6379> 
10.244.0.90:6379> keys *
(empty list or set)
10.244.0.90:6379> keys *
1) "messages"
10.244.0.90:6379> get messages
",this is a test"
10.244.0.90:6379> 


可以看到数据同步ok！

For More information:BurlyLuo <olaf.luo@foxmail.com>
