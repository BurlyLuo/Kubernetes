kubernetes service的滚动更新[RollingUpdate]
背景：传统的升级更新，是先将服务全部下线，业务停止后再更新版本和配置，然后重新启动并提供服务。这样的模式已经完全不能满足“时代的需要”了。在并发化、高可用系统普及的今天，服务的升级更新至少要做到“业务不中断”。而滚动更新(Rolling-update)恰是满足这一需求的一种系统更新升级方案。
简单来说，滚动更新就是针对多实例服务的一种不中断服务的更新升级方式。一般情况，对于多实例服务，滚动更新采用对各个实例逐个进行单独更新而非同一时刻对所有实例进行全部更新的方式。“滚动更新”的先进之处在于“滚动”这个概念的引入，笔者觉得它至少有以下两点含义：
a) “滚动”给人一种“圆”的映像，表意：持续，不中断。“滚动”的理念是一种趋势，我们常见的“滚动发布”、“持续交付”都是“滚动”理念的应用。与传统的大版本周期性发布/更新相比，”滚动”可以让用户更快、更及时地使用上新Feature，缩短市场反馈周期，同时滚动式的发布和更新又会将对用户体验的影响降到最小化。
b) “滚动”可向前，也可向后。我们可以在更新过程中及时发现“更新”存在的问题，并“向后滚动”，实现更新的回退，可以最大程度上降低每次更新升级的风险。
对于在Kubernetes集群部署的Service来说，Rolling update就是指一次仅更新一个Pod，并逐个进行更新，而不是在同一时刻将该Service下面的所有Pod shutdown，避免将业务中断的尴尬。

Service、Deployment、Replica Set、Replication Controllers和Pod之间的关系
对于我们要部署的Application来说，一般是由多个抽象的Service组成。在Kubernetes中，一个Service通过label selectormatch出一个Pods集合，这些Pods作为Service的endpoint，是真正承载业务的实体。而Pod在集群内的部署、调度、副本数保持则是通过Deployment或ReplicationControllers这些高level的抽象来管理的。
[root@k8s-1 ~]#  kubectl rolling-update --help
Help provides help for any command in the application.
    Simply type kubectl help [path to command] for full details.

Usage:
  kubectl help [command] [options]

Use "kubectl options" for a list of global command-line options (applies to all commands).
[root@k8s-1 ~]#
得益于 一个deploy可以控制多个replicaset。



#https://github.com/BurlyLuo/Kubernetes/blob/master/Image/Rolling%20Update.png

现在给一个例子：
背景：以nginx这个deploy为例：
[该镜像的verison为1.7.9]     ------>    修改为：[由于hub中没有镜像verison为1.7.3的，所以会拉去失败！]
原则：[pod的rolling update过程中的原则：]
desired pods number - maxUnavailable≤ Available(Ready) Pods ≤desired pods number + maxSurge
maxSurge: 1
      maxUnavailable: 1
DESIRED = 2  //定义的//
maxUnavailable = 1
Available = 1  //实际的pod的个数//
maxSurge = 1
desired pods number - maxUnavailable = 2 - 1 =1
desired pods number + maxSurge = 2 + 1 = 3
desired pods number - maxUnavailable = 1≤ Available(Ready) Pods ≤desired pods number + maxSurge = 3    [1=< Availble(Ready) <= 3]
[root@k8s-1 ~]# kubectl get pods -o wide
NAME                                READY     STATUS             RESTARTS   AGE       IP                NODE
nginx-deployment-1260880958-9t817   1/1       Running            18         255d      192.168.200.231   k8s-2
nginx-deployment-664613708-50kcp    0/1       ImagePullBackOff   0          4m        192.168.200.202   k8s-2
nginx-deployment-664613708-jjtkp    0/1       ImagePullBackOff   0          4m        <none>            k8s-2
此时在deploy的Controller下Replicaset形成了另外一个rs出来。
[root@k8s-1 ~]# kubectl get rs -o wide
NAME                          DESIRED   CURRENT   READY     AGE       CONTAINER(S)       IMAGE(S)      SELECTOR
nginx-deployment-1260880958   1         1         1         255d      nginx-deployment   nginx:1.7.9   pod-template-hash=1260880958,run=nginx-deployment
nginx-deployment-664613708    2         2         0         12m       nginx-deployment   nginx:1.7.3   pod-template-hash=664613708,run=nginx-deployment    //这就是新的rs//
[root@k8s-1 ~]#
[root@k8s-1 ~]# kubectl rollout history deploy  nginx-deployment   //这里做过一次Rolligout了，所以ID会变成3//
deployments "nginx-deployment"
REVISION        CHANGE-CAUSE
3               <none>
4               <none>
[root@k8s-1 ~]#

//现在执行回滚//
[root@k8s-1 ~]# kubectl rollout undo deploy nginx-deployment   //回滚到上一个版本//
deployment "nginx-deployment" rolled back
[root@k8s-1 ~]# kubectl get rs -o wide
NAME                          DESIRED   CURRENT   READY     AGE       CONTAINER(S)       IMAGE(S)      SELECTOR
demo-deployment-2163034595    1         1         1         229d      demo               mritd/demo    app=demo,pod-template-hash=2163034595
nginx-deployment-1260880958   2         2         2         255d      nginx-deployment   nginx:1.7.9   pod-template-hash=1260880958,run=nginx-deployment
nginx-deployment-664613708    0         0         0         16m       nginx-deployment   nginx:1.7.3   pod-template-hash=664613708,run=nginx-deployment   //该RS下已经没有pod了//
[root@k8s-1 ~]#
[root@k8s-1 ~]# kubectl get pods -o wide
NAME                                READY     STATUS    RESTARTS   AGE       IP                NODE
nginx-deployment-1260880958-81z4m   1/1       Running   0          1m        192.168.200.247   k8s-2
nginx-deployment-1260880958-9t817   1/1       Running   18         255d      192.168.200.231   k8s-2

[root@k8s-1 ~]# kubectl describe rs nginx-deployment-1260880958
Name:           nginx-deployment-1260880958
Namespace:      default
Selector:       pod-template-hash=1260880958,run=nginx-deployment
Labels:         pod-template-hash=1260880958
                run=nginx-deployment
Annotations:    deployment.kubernetes.io/desired-replicas=2
                deployment.kubernetes.io/max-replicas=3
                deployment.kubernetes.io/revision=5
                deployment.kubernetes.io/revision-history=1,3
Controlled By:  Deployment/nginx-deployment
Replicas:       2 current / 2 desired
Pods Status:    2 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:       pod-template-hash=1260880958
                run=nginx-deployment
  Containers:
   nginx-deployment:
    Image:              nginx:1.7.9
    Port:               <none>
    Environment:        <none>
    Mounts:             <none>
  Volumes:              <none>
Events:
  FirstSeen     LastSeen        Count   From                    SubObjectPath   Type            Reason                  Message
  ---------     --------        -----   ----                    -------------   --------        ------                  -------
  45m           45m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-2zm4j
  45m           45m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-cb9gv
  45m           45m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-xc9j5
  44m           44m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-fz96h
  44m           44m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-cb9gv
  44m           44m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-2zm4j
  44m           44m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-xc9j5
  39m           39m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-1h44d
  39m           39m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-fc958
  39m           39m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-1h44d
  33m           33m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-896bh
  22m           22m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-t4zgc
  22m           22m             1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-1mdsp
  19m           19m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-1mdsp
  19m           19m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-896bh
  19m           19m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-t4zgc
  19m           19m             1       replicaset-controller                   Normal          SuccessfulDelete        Deleted pod: nginx-deployment-1260880958-fc958
  3m            3m              1       replicaset-controller                   Normal          SuccessfulCreate        Created pod: nginx-deployment-1260880958-81z4m
[root@k8s-1 ~]#  







