# Copyright BurlyLuo <olaf.luo@foxmail.com>.
# Date: 2019-3-17
# encoding: utf-8


import os
import time
from kubernetes import client, config


DEPLOYMENT_NAME = "nginx-deployment"
IMAGE_NAME = "nginx:1.9.1"
NAMESPACE = "default"


def create_deployment_object():
    # In older to avoid the situation that
    # Configure Pod template container
    container = client.V1Container(name="nginx", image="nginx:1.7.9", image_pull_policy="IfNotPresent", ports=[client.V1ContainerPort(container_port=80, protocol="TCP")])
    # Create and config a spec section [Deployment.template]
    template = client.V1PodTemplateSpec(metadata=client.V1ObjectMeta(labels={"app": "nginx"}, namespace=NAMESPACE), spec=client.V1PodSpec(containers=[container]))
    # Create the specification of deployment
    spec = client.ExtensionsV1beta1DeploymentSpec(replicas=3, template=template)
    # Instantiate the deployment object
    deployment = client.ExtensionsV1beta1Deployment(api_version="extensions/v1beta1", kind="Deployment", metadata=client.V1ObjectMeta(name=DEPLOYMENT_NAME), spec=spec)

    return deployment


def create_deployment(api_instance, deployment):
    # Create deployment
    api_response = api_instance.create_namespaced_deployment(body=deployment, namespace=NAMESPACE)
    print("Deployment created. status='%s'" % str(api_response.status))
    out_put = os.system("kubectl get pods -o wide --show-labels -n=%s" %(NAMESPACE))
    print(out_put, time.time())


def update_deployment(api_instance, deployment):
    # Update container image
    deployment.spec.template.spec.containers[0].image = IMAGE_NAME
    # Update the deployment
    api_response = api_instance.patch_namespaced_deployment(name=DEPLOYMENT_NAME, namespace=NAMESPACE, body=deployment)
    print("Deployment updated. status='%s'" % str(api_response.status))


def delete_deployment(api_instance):
    # Delete deployment
    api_response = api_instance.delete_namespaced_deployment(name=DEPLOYMENT_NAME, namespace=NAMESPACE, body=client.V1DeleteOptions(propagation_policy='Foreground', grace_period_seconds=5))
    # print("Deployment deleted. status='%s'" % str(api_response.status))


def get_deployment():
        out_put_k8s = os.system("kubectl get deployment %s" %(DEPLOYMENT_NAME))
        if out_put_k8s != 0:
           out_put_k8s == 1
        return out_put_k8s
        
        
def main():
    # Configs can be set in Configuration class directly or using helper
    # utility. If no argument provided, the config will be loaded from
    # default location.
    config.load_kube_config()
    extensions_v1beta1 = client.ExtensionsV1beta1Api()
    # Create a deployment object with client-python API. The deployment we
    # created is same as the 'nginx-deployment.yaml' in the /examples folder.
    deployment = create_deployment_object()
    # get_deployment()
    if   get_deployment() == 0:
                delete_deployment(extensions_v1beta1)
                time.sleep(30)
                create_deployment(extensions_v1beta1, deployment)
    else:
                print("It is not exits!")
                create_deployment(extensions_v1beta1, deployment)
        # create_deployment(extensions_v1beta1, deployment)
    # update_deployment(extensions_v1beta1, deployment)

    # delete_deployment(extensions_v1beta1)


if __name__ == '__main__':
    main()
