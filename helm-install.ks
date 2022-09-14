helm install guide
Refer： https://www.cnblogs.com/xzkzzz/p/9373469.html             https://blog.csdn.net/wenwenxiong/article/details/79067054
安装过程：
Note：
I was able to solve this by reiniting the cluster with a different CIDR (was previously using the same CIDR as the host vm (192.168.0.0/16). I used 172.16.0.0/16 and it worked right away.
1.下载对应包：https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz
2. tar -xzvf helm-v2.10.0-linux-amd64.tar.gz
3.mv linux-amd64/helm /usr/local/bin/helm
4.helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.10.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts 
5. kubectl -n kube-system get pods|grep tiller
6.helm version
7.helm create   myapp
8.helm repo update
9.kubectl create serviceaccount --namespace kube-system tiller
10. kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
11.kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
12.helm list 
具体安装日志：
[root@linux-node1 ~]# tar -xzvf helm-v2.9.1-linux-amd64.tar.gz
linux-amd64/
linux-amd64/README.md
linux-amd64/helm
linux-amd64/LICENSE
[root@linux-node1 ~]# ll
total 174276
-rw-------. 1 root root      1037 Jan 16  2016 anaconda-ks.cfg
-rw-r--r--  1 root root   9160761 Aug 20 20:53 helm-v2.9.1-linux-amd64.tar.gz
-rw-r--r--  1 root root 169291184 Aug 20 00:55 k8s-v1.10.3-auto.zip
drwxr-xr-x  2 root root        47 May 15 02:41 linux-amd64
drwxr-xr-x  8 root root       135 Aug 20 09:53 salt-kubernetes
[root@linux-node1 ~]# cd
[root@linux-node1 ~]# clear
[root@linux-node1 ~]# ll
total 174276
-rw-------. 1 root root      1037 Jan 16  2016 anaconda-ks.cfg
-rw-r--r--  1 root root   9160761 Aug 20 20:53 helm-v2.9.1-linux-amd64.tar.gz
-rw-r--r--  1 root root 169291184 Aug 20 00:55 k8s-v1.10.3-auto.zip
drwxr-xr-x  2 root root        47 May 15 02:41 linux-amd64
drwxr-xr-x  8 root root       135 Aug 20 09:53 salt-kubernetes
[root@linux-node1 ~]# mv linux-amd64/helm /usr/local/bin/helm
[root@linux-node1 ~]# helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
Creating /root/.helm
Creating /root/.helm/repository
Creating /root/.helm/repository/cache
Creating /root/.helm/repository/local
Creating /root/.helm/plugins
Creating /root/.helm/starters
Creating /root/.helm/cache/archive
Creating /root/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /root/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
[root@linux-node1 ~]# kubectl -n kube-system get pods|grep tiller
tiller-deploy-55bc6f6cf6-sqq6w                1/1       Running   0          20s
[root@linux-node1 ~]# helm version
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.9.0", GitCommit:"f6025bb9ee7daf9fee0026541c90a6f557a3e0bc", GitTreeState:"clean"}
[root@linux-node1 ~]# helm create   myapp
Creating myapp
[root@linux-node1 ~]# helm search
NAME                              CHART VERSION    APP VERSION      DESCRIPTION                                       
stable/acs-engine-autoscaler      2.1.3            2.1.1            Scales worker nodes within agent pools           
stable/aerospike                  0.1.7            v3.14.1.2        A Helm chart for Aerospike in Kubernetes         
stable/anchore-engine             0.1.3            0.1.6            Anchore container analysis and policy evaluatio...
stable/artifactory                7.0.3            5.8.4            Universal Repository Manager supporting all maj...
stable/artifactory-ha             0.1.0            5.8.4            Universal Repository Manager supporting all maj...
stable/aws-cluster-autoscaler     0.3.2                             Scales worker nodes within autoscaling groups.   
stable/bitcoind                   0.1.0            0.15.1           Bitcoin is an innovative payment network and a ...
stable/buildkite                  0.2.1            3                Agent for Buildkite                               
stable/centrifugo                 2.0.0            1.7.3            Centrifugo is a real-time messaging server.       
stable/cert-manager               0.2.2            0.2.3            A Helm chart for cert-manager                     
stable/chaoskube                  0.6.2            0.6.1            Chaoskube periodically kills random pods in you...
stable/chronograf                 0.4.2                             Open-source web application written in Go and R...
stable/cluster-autoscaler         0.4.2            1.1.0            Scales worker nodes within autoscaling groups.   
stable/cockroachdb                0.6.5            1.1.5            CockroachDB is a scalable, survivable, strongly...
stable/concourse                  1.0.2            3.9.0            Concourse is a simple and scalable CI system.     
stable/consul                     1.3.1            1.0.0            Highly available and distributed service discov...
stable/coredns                    0.8.0            1.0.1            CoreDNS is a DNS server that chains plugins and...
stable/coscale                    0.2.0            3.9.1            CoScale Agent                                     
stable/dask-distributed           2.0.0                             Distributed computation in Python                 
stable/datadog                    0.10.9                            DataDog Agent                                     
stable/docker-registry            1.0.3            2.6.2            A Helm chart for Docker Registry                 
stable/dokuwiki                   0.2.2                             DokuWiki is a standards-compliant, simple to us...
stable/drupal                     0.11.8           8.4.5            One of the most versatile open source content m...
stable/elastalert                 0.1.1            0.1.21           ElastAlert is a simple framework for alerting o...
stable/elasticsearch-exporter     0.1.2            1.0.2            Elasticsearch stats exporter for Prometheus       
stable/etcd-operator              0.7.0            0.7.0            CoreOS etcd-operator Helm chart for Kubernetes   
stable/external-dns               0.4.9            0.4.8            Configure external DNS servers (AWS Route53, Go...
stable/factorio                   0.3.0                             Factorio dedicated server.                       
stable/fluent-bit                 0.2.11           0.12.11          Fast and Lightweight Log/Data Forwarder for Lin...
stable/g2                         0.3.0            0.5.0            G2 by AppsCode - Gearman in Golang               
stable/gcloud-endpoints           0.1.0                             Develop, deploy, protect and monitor your APIs ...
stable/gcloud-sqlproxy            0.2.3                             Google Cloud SQL Proxy                           
stable/gcp-night-king             1.0.0            1                A Helm chart for GCP Night King                   
stable/ghost                      2.1.13           1.21.3           A simple, powerful publishing platform that all...
stable/gitlab-ce                  0.2.1                             GitLab Community Edition                         
stable/gitlab-ee                  0.2.1                             GitLab Enterprise Edition                         
stable/grafana                    0.7.0                             The leading tool for querying and visualizing t...
stable/hadoop                     1.0.4            2.7.3            The Apache Hadoop software library is a framewo...
stable/heapster                   0.2.7                             Heapster enables Container Cluster Monitoring a...
stable/influxdb                   0.8.2                             Scalable datastore for metrics, events, and rea...
stable/ipfs                       0.2.0            v0.4.9           A Helm chart for the Interplanetary File System   
stable/jasperreports              0.2.5            6.4.2            The JasperReports server can be used as a stand...
stable/jenkins                    0.13.5           2.73             Open source continuous integration server. It s...
stable/joomla                     0.5.7            3.8.5            PHP content management system (CMS) for publish...
stable/kanister-operator          0.2.0            0.2.0            Kanister-operator Helm chart for Kubernetes       
stable/kapacitor                  0.5.0                             InfluxDB's native data processing engine. It ca...
stable/keel                       0.2.1            0.4.2            Open source, tool for automating Kubernetes dep...
stable/kibana                     0.2.2            6.0.0            Kibana is an open source data visualization plu...
stable/kong                       0.1.2            0.12.1           Kong is open-source API Gateway and Microservic...
stable/kube-lego                  0.4.0                             DEPRECATED Automatically requests certificates ...
stable/kube-ops-view              0.4.1                             Kubernetes Operational View - read-only system ...
stable/kube-state-metrics         0.5.3            1.1.0            Install kube-state-metrics to generate and expo...
stable/kube2iam                   0.8.0                             Provide IAM credentials to pods based on annota...
stable/kubed                      0.3.0            0.4.0            Kubed by AppsCode - Kubernetes daemon             
stable/kubernetes-dashboard       0.6.0            1.8.3            General-purpose web UI for Kubernetes clusters   
stable/lamp                       0.1.4                             Modular and transparent LAMP stack chart suppor...
stable/linkerd                    0.4.0                             Service mesh for cloud native apps               
stable/locust                     0.1.2                             A modern load testing framework                   
stable/luigi                      2.7.2                             Luigi is a Python module that helps you build c...
stable/magento                    0.6.3            2.2.3            A feature-rich flexible e-commerce solution. It...
stable/mailhog                    2.2.0            1.0.0            An e-mail testing tool for developers             
stable/mariadb                    2.1.6            10.1.31          Fast, reliable, scalable, and easy to use open-...
stable/mcrouter                   0.1.0            0.36.0           Mcrouter is a memcached protocol router for sca...
stable/mediawiki                  0.6.3            1.30.0           Extremely powerful, scalable software and a fea...
stable/memcached                  2.0.1                             Free & open source, high-performance, distribut...
stable/metabase                   0.3.2            v0.27.2          The easy, open source way for everyone in your ...
stable/minecraft                  0.2.0                             Minecraft server                                 
stable/minio                      0.5.5                             Distributed object storage server built for clo...
stable/mongodb                    0.4.27           3.7.1            NoSQL document-oriented database that stores JS...
stable/mongodb-replicaset         2.3.1            3.6              NoSQL document-oriented database that stores JS...
stable/moodle                     0.4.5            3.4.1            Moodle is a learning platform designed to provi...
stable/msoms                      0.1.2            1.0.0-30         A chart for deploying omsagent as a daemonset K...
stable/mssql-linux                0.1.7                             SQL Server 2017 Linux Helm Chart                 
stable/mysql                      0.3.5                             Fast, reliable, scalable, and easy to use open-...
stable/namerd                     0.2.0                             Service that manages routing for multiple linke...
stable/neo4j                      0.5.0            3.2.3            Neo4j is the world's leading graph database       
stable/newrelic-infrastructure    0.0.4            0.0.12           A Helm chart to deploy the New Relic Infrastruc...
stable/nginx-ingress              0.9.5            0.10.2           An nginx Ingress controller that uses ConfigMap...
stable/nginx-lego                 0.3.1                             Chart for nginx-ingress-controller and kube-lego 
stable/odoo                       0.7.3            11.0.20180115    A suite of web based open source business apps.   
stable/opencart                   0.6.2            3.0.2            A free and open source e-commerce platform for ...
stable/openvpn                    2.0.2                             A Helm chart to install an openvpn server insid...
stable/orangehrm                  0.5.2            4.0.0            OrangeHRM is a free HR management system that o...
stable/osclass                    0.5.2            3.7.4            Osclass is a php script that allows you to quic...
stable/owncloud                   0.5.7            10.0.7           A file sharing server that puts the control and...
stable/pachyderm                  0.1.5            1.6.7            Pachyderm is a large-scale container-based work...
stable/parse                      0.3.6            2.7.2            Parse is a platform that enables users to add a...
stable/percona                    0.3.0                             free, fully compatible, enhanced, open source d...
stable/percona-xtradb-cluster     0.0.2            5.7.19           free, fully compatible, enhanced, open source d...
stable/phabricator                0.5.15           2018.8.0         Collection of open source web applications that...
stable/phpbb                      0.6.4            3.2.2            Community forum that supports the notion of use...
stable/postgresql                 0.9.1                             Object-relational database management system (O...
stable/prestashop                 0.5.3            1.7.2            A popular open source ecommerce solution. Profe...
stable/prometheus                 5.4.0                             Prometheus is a monitoring system and time seri...
stable/prometheus-to-sd           0.1.0            0.2.2            Scrape metrics stored in prometheus format and ...
stable/quassel                    0.2.2            0.12.4           Quassel IRC is a modern, cross-platform, distri...
stable/rabbitmq                   0.6.21           3.7.3            Open source message broker software that implem...
stable/rabbitmq-ha                1.0.0            3.7.3            Highly available RabbitMQ cluster, the open sou...
stable/redis                      1.1.15           4.0.8            Open source, advanced key-value store. It is of...
stable/redis-ha                   2.0.1                             Highly available Redis cluster with multiple se...
stable/redmine                    2.0.4            3.4.4            A flexible project management web application.   
stable/rethinkdb                  0.1.1                             The open-source database for the realtime web     
stable/risk-advisor               2.0.0                             Risk Advisor add-on module for Kubernetes         
stable/rocketchat                 0.1.2                             Prepare to take off with the ultimate chat plat...
stable/sapho                      0.2.1                             A micro application development and integration...
stable/searchlight                0.3.0            5.0.0            Searchlight by AppsCode - Alerts for Kubernetes   
stable/selenium                   0.2.6            3.9.1            Chart for selenium grid                           
stable/sematext-docker-agent      0.1.2                             Sematext Docker Agent                             
stable/sensu                      0.2.0                             Sensu monitoring framework backed by the Redis ...
stable/sentry                     0.1.9            8.17             Sentry is a cross-platform crash reporting and ...
stable/sonarqube                  0.3.6            6.5              Sonarqube is an open sourced code quality scann...
stable/sonatype-nexus             0.1.6            3.5.1            Sonatype Nexus is an open source repository man...
stable/spark                      0.1.10                            Fast and general-purpose cluster computing system.
stable/spartakus                  1.1.3                             Collect information about Kubernetes clusters t...
stable/spinnaker                  0.4.0            1.6.0            Open source, multi-cloud continuous delivery pl...
stable/spotify-docker-gc          0.1.2                             A simple Docker container and image garbage col...
stable/stash                      0.4.0            0.6.2            Stash by AppsCode - Backup your Kubernetes Volumes
stable/sugarcrm                   0.2.4            6.5.26           SugarCRM enables businesses to create extraordi...
stable/suitecrm                   0.3.7            7.9.12           SuiteCRM is a completely open source enterprise...
stable/sumokube                   0.1.2                             Sumologic Log Collector                           
stable/sumologic-fluentd          0.2.1                             Sumologic Log Collector                           
stable/swift                      0.5.0            0.7.2            swift by AppsCode - Ajax friendly Helm Tiller P...
stable/sysdig                     0.4.0                             Sysdig Monitor and Secure agent                   
stable/telegraf                   0.3.2                             Telegraf is an agent written in Go for collecti...
stable/testlink                   0.4.18           1.9.16           Web-based test management system that facilitat...
stable/traefik                    1.24.1           1.5.3            A Traefik based Kubernetes ingress controller w...
stable/uchiwa                     0.2.3                             Dashboard for the Sensu monitoring framework     
stable/verdaccio                  0.2.0            2.7.3            A lightweight private npm proxy registry (sinop...
stable/voyager                    3.1.0            6.0.0-rc.0       Voyager by AppsCode - Secure Ingress Controller...
stable/weave-cloud                0.1.2                             Weave Cloud is a add-on to Kubernetes which pro...
stable/weave-scope                0.9.2            1.6.5            A Helm chart for the Weave Scope cluster visual...
stable/wordpress                  0.8.8            4.9.4            Web publishing platform for building blogs and ...
stable/zeppelin                   1.0.0            0.7.2            Web-based notebook that enables data-driven, in...
stable/zetcd                      0.1.6            0.0.3            CoreOS zetcd Helm chart for Kubernetes           
[root@linux-node1 ~]# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
[root@linux-node1 ~]# helm list
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
[root@linux-node1 ~]# helm list
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
[root@linux-node1 ~]#
[root@linux-node1 ~]#
[root@linux-node1 ~]#
[root@linux-node1 ~]# kubectl get pods -o wide
NAME                        READY     STATUS    RESTARTS   AGE       IP          NODE
net-test-5767cb94df-2xhnl   1/1       Running   0          10h       10.2.34.2   192.168.8.27
net-test-5767cb94df-zst7q   1/1       Running   0          10h       10.2.44.2   192.168.8.26
[root@linux-node1 ~]# kubectl get pods -o wide -n=kube-system
NAME                                          READY     STATUS    RESTARTS   AGE       IP          NODE
coredns-77c989547b-dd4ln                      1/1       Running   0          8h        10.2.34.5   192.168.8.27
coredns-77c989547b-sw4bh                      1/1       Running   0          8h        10.2.44.6   192.168.8.26
heapster-64f4f9f59d-wln9h                     1/1       Running   0          9h        10.2.34.4   192.168.8.27
kubernetes-dashboard-66c9d98865-2g8t4         1/1       Running   0          10h       10.2.34.3   192.168.8.27
monitoring-grafana-844d4fdf8c-94jbc           1/1       Running   0          9h        10.2.44.3   192.168.8.26
monitoring-influxdb-644db5c5b6-b4sp8          1/1       Running   0          9h        10.2.44.4   192.168.8.26
tiller-deploy-55bc6f6cf6-sqq6w                1/1       Running   0          6m        10.2.44.7   192.168.8.26
traefik-ingress-controller-5646f8db47-9qhwf   1/1       Running   0          8h        10.2.44.5   192.168.8.26
[root@linux-node1 ~]# helm list -n=kube-system
Error: unknown shorthand flag: 'n' in -n=kube-system
[root@linux-node1 ~]# helm list
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
[root@linux-node1 ~]# helm
The Kubernetes package manager

To begin working with Helm, run the 'helm init' command:

    $ helm init

This will install Tiller to your running Kubernetes cluster.
It will also set up any necessary local configuration.

Common actions from this point include:

- helm search:    search for charts
- helm fetch:     download a chart to your local directory to view
- helm install:   upload the chart to Kubernetes
- helm list:      list releases of charts

Environment:
  $HELM_HOME          set an alternative location for Helm files. By default, these are stored in ~/.helm
  $HELM_HOST          set an alternative Tiller host. The format is host:port
  $HELM_NO_PLUGINS    disable plugins. Set HELM_NO_PLUGINS=1 to disable plugins.
  $TILLER_NAMESPACE   set an alternative Tiller namespace (default "kube-system")
  $KUBECONFIG         set an alternative Kubernetes configuration file (default "~/.kube/config")

Usage:
  helm [command]

Available Commands:
  completion  Generate autocompletions script for the specified shell (bash or zsh)
  create      create a new chart with the given name
  delete      given a release name, delete the release from Kubernetes
  dependency  manage a chart's dependencies
  fetch       download a chart from a repository and (optionally) unpack it in local directory
  get         download a named release
  history     fetch release history
  home        displays the location of HELM_HOME
  init        initialize Helm on both client and server
  inspect     inspect a chart
  install     install a chart archive
  lint        examines a chart for possible issues
  list        list releases
  package     package a chart directory into a chart archive
  plugin      add, list, or remove Helm plugins
  repo        add, list, remove, update, and index chart repositories
  reset       uninstalls Tiller from a cluster
  rollback    roll back a release to a previous revision
  search      search for a keyword in charts
  serve       start a local http web server
  status      displays the status of the named release
  template    locally render templates
  test        test a release
  upgrade     upgrade a release
  verify      verify that a chart at the given path has been signed and is valid
  version     print the client/server version information

Flags:
      --debug                           enable verbose output
  -h, --help                            help for helm
      --home string                     location of your Helm config. Overrides $HELM_HOME (default "/root/.helm")
      --host string                     address of Tiller. Overrides $HELM_HOST
      --kube-context string             name of the kubeconfig context to use
      --tiller-connection-timeout int   the duration (in seconds) Helm will wait to establish a connection to tiller (default 300)
      --tiller-namespace string         namespace of Tiller (default "kube-system")

Use "helm [command] --help" for more information about a command.
[root@linux-node1 ~]# helm helm repo update
Error: unknown command "helm" for "helm"
Run 'helm --help' for usage.
[root@linux-node1 ~]# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
[root@linux-node1 ~]# kubectl create serviceaccount --namespace kube-system tiller
serviceaccount "tiller" created
[root@linux-node1 ~]# kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
clusterrolebinding.rbac.authorization.k8s.io "tiller-cluster-rule" created
[root@linux-node1 ~]# kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
deployment.extensions "tiller-deploy" patched
[root@linux-node1 ~]# helm list
[root@linux-node1 ~]#
[root@linux-node1 ~]#
[root@linux-node1 ~]# helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.9.0 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
$HELM_HOME has been configured at /root/.helm.

Tiller (the Helm server-side component) has been upgraded to the current version.
Happy Helming!
[root@linux-node1 ~]# helm list
[root@linux-node1 ~]#
[root@linux-node1 ~]#
[root@linux-node1 ~]# helm list
[root@linux-node1 ~]# helm create   myapp
Creating myapp
[root@linux-node1 ~]#
[root@linux-node1 ~]#
[root@linux-node1 ~]# helm list
[root@linux-node1 ~]# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
[root@linux-node1 ~]# history


Note：
I was able to solve this by reiniting the cluster with a different CIDR (was previously using the same CIDR as the host vm (192.168.0.0/16). I used 172.16.0.0/16 and it worked right away.
