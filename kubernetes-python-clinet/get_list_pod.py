# Copyright BurlyLuo <olaf.luo@foxmail.com>.
# Date:2019-3-17
# encoding: utf-8


from kubernetes import client, config


def get_list_pod():
	config.load_kube_config()

	v1 = client.CoreV1Api()
	print("Listing pods with their IPs:")
	ret = v1.list_pod_for_all_namespaces(watch=False)
	for i in ret.items:
		#print(i)
	    print("%s\t%s\t%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name, i.spec.node_name, i.metadata.labels))
	

if __name__ == '__main__':
	get_list_pod()
