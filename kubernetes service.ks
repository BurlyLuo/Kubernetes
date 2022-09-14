kubernetes service
Flannel 网络：
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubernetes repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0

CentOS / RHEL / Fedora

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
setenforce 0
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet
为了弄清楚在流量进入service后是怎么重定向到后端的pod上。现在以通过helm部署的nginx来分析一下：
[root@k8s-1 ~]# helm list
NAME    REVISION        UPDATED                         STATUS          CHART           APP VERSION     NAMESPACE
ngnix   1               Wed Feb 13 19:45:15 2019        DEPLOYED        nginx-2.1.3     1.14.2          default 
[root@k8s-1 ~]#
[root@k8s-1 ~]# helm get ngnix
REVISION: 1
RELEASED: Wed Feb 13 19:45:15 2019
CHART: nginx-2.1.3
USER-SUPPLIED VALUES:
{}

COMPUTED VALUES:
image:
  pullPolicy: IfNotPresent
  registry: docker.io
  repository: bitnami/nginx
  tag: 1.14.2
metrics:
  enabled: false
  image:
    pullPolicy: IfNotPresent
    registry: docker.io
    repository: nginx/nginx-prometheus-exporter
    tag: 0.1.0
  podAnnotations:
    prometheus.io/port: "9113"
    prometheus.io/scrape: "true"
podAnnotations: {}
service:
  externalTrafficPolicy: Cluster
  nodePorts:
    http: ""
  port: 80
  type: LoadBalancer   默认使用的是LB，后边为了演示效果，patch为NodePoert的type。kubectl patch svc  ngnix-nginx  -p '{"spec":{"type":"NodePort"}}'

HOOKS:
MANIFEST:

---
# Source: nginx/templates/svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: ngnix-nginx     #kubectl patch svc  ngnix-nginx  -p '{"spec":{"type":"NodePort"}}'
  labels:
    app: ngnix-nginx
    chart: "nginx-2.1.3"
    release: "ngnix"
    heritage: "Tiller"
spec:
  type: LoadBalancer
  externalTrafficPolicy: "Cluster"
  ports:
    - name: http
      port: 80
      targetPort: http
  selector:
    app: ngnix-nginx
---
# Source: nginx/templates/deployment.yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: ngnix-nginx
  labels:
    app: ngnix-nginx
    chart: "nginx-2.1.3"
    release: "ngnix"
    heritage: "Tiller"
spec:
  selector:
    matchLabels:
      app: ngnix-nginx
      release: "ngnix"
  replicas: 1
  template:
    metadata:
      labels:
        app: ngnix-nginx
        chart: "nginx-2.1.3"
        release: "ngnix"
        heritage: "Tiller"
    spec:
      containers:
      - name: ngnix-nginx
        image: "docker.io/bitnami/nginx:1.14.2"
        imagePullPolicy: "IfNotPresent"
        ports:
        - name: http
          containerPort: 8080
        livenessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 30
          timeoutSeconds: 5
          failureThreshold: 6
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          timeoutSeconds: 3
          periodSeconds: 5
        volumeMounts:
      volumes:
[root@k8s-1 ~]#  
现在说说上边的yaml文件中label：这个需要特殊说明：
1.先说明Deployment：
[root@k8s-1 ~]# kubectl get deploy --show-labels | grep "ngnix-nginx"
ngnix-nginx       2/2     2            2           4d15h   app=ngnix-nginx,chart=nginx-2.1.3,heritage=Tiller,release=ngnix
[root@k8s-1 ~]#
而对应到yaml文件中为：
  name: ngnix-nginx
  labels:
  app: ngnix-nginx
  chart: "nginx-2.1.3"
  release: "ngnix"
  heritage: "Tiller"
Deploy类型的Controller通过该Label来控制RS来间接的控制Pods。
2.service通过label来选择后端pod来相应前端的Request请求。
[root@k8s-1 ~]# kubectl get svc -o wide --show-labels  | grep "ngnix-nginx"
ngnix-nginx   NodePort    10.107.44.153    <none>        80:30281/TCP        4d17h   app=ngnix-nginx   app=ngnix-nginx,chart=nginx-2.1.3,heritage=Tiller,release=ngnix
[root@k8s-1 ~]#
[root@k8s-1 ~]# kubectl get pods -o wide | grep ngnix
ngnix-nginx-d898cbd68-2r9bk        1/1     Running   0          3h30m   10.244.0.104   k8s-1   <none>           <none>
ngnix-nginx-d898cbd68-tlhc7        1/1     Running   5          4d17h   10.244.1.80    k8s-2   <none>           <none>
[root@k8s-1 ~]#
#######################
[root@k8s-1 ~]# kubectl exec -it ngnix-nginx-d898cbd68-2r9bk bash
I have no name!@ngnix-nginx-d898cbd68-2r9bk:/opt/bitnami/nginx/html$ more index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

</body>
</html>
I have no name!@ngnix-nginx-d898cbd68-2r9bk:/opt/bitnami/nginx/html$
#######################
[root@k8s-1 ~]# kubectl exec -it ngnix-nginx-d898cbd68-tlhc7 bash
I have no name!@ngnix-nginx-d898cbd68-tlhc7:/opt/bitnami/nginx/html$ more index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
I have no name!@ngnix-nginx-d898cbd68-tlhc7:/opt/bitnami/nginx/html$
#######################
[root@k8s-1 ~]# curl 172.10.1.20:30281 | grep For
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   513  100   513    0     0   240k      0 --:--:-- --:--:-- --:--:--  500k
[root@k8s-1 ~]# curl 172.10.1.20:30281 | grep For
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0   138k      0 --:--:-- --:--:-- --:--:--  199k
<p>For online documentation and support please refer to
[root@k8s-1 ~]# curl 172.10.1.20:30281 | grep For
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   612  100   612    0     0   120k      0 --:--:-- --:--:-- --:--:--  149k
<p>For online documentation and support please refer to
[root@k8s-1 ~]# curl 172.10.1.20:30281 | grep For
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   513  100   513    0     0   118k      0 --:--:-- --:--:-- --:--:--  166k















