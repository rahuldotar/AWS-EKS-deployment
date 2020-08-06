
![alt text <>](https://accubits-image-assets.s3-ap-southeast-1.amazonaws.com/kubernetes.png "")
# AWS EKS Deployment 

## Prerequisite on workstation

- Ubuntu 18.04
- eksctl 
- AWS CLI

- Docker


#### clone the repo 
```
 git  clone <url>   eks-deployment
```

### Building Docker image 

- Here the application backend is a sample NodeJS Express App and frontend is a sample Angular App.

 - Run build.sh to build the image , modify build.sh commands if you get any errors (modify the tag name)
   ```
    chmod +x build.sh
    ./build.sh
   ```

- Create a container and check everything is working , run run.sh (modify run.sh depending upon you needs)
    ```
    chmod +x build.sh
    ./run.sh
   ```

- Checkin the image to you docker registry .
```
	docker login
	docker tag <imageid> <username>/<image-name>:<tag>
	docker push <username>/<image-name>:<tag>
```

#### Create docker registry secret

-  Since we need to use the private images , we need to create secrets for the kubrentes , which can be used to pull the image 
 ```
  docker login
 ```
  ```
	kubectl create secret generic docker-reg-cred \
    --from-file=.dockerconfigjson=/home/user/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
  ```

**OR**
```shell
kubectl create secret docker-registry docker-reg-cred --docker-server=<your-registry-server> --docker-username=<your-name> --docker-password=<your-pword> --docker-email=<your-email>

```

- Get the secret in YAML format  and save it to a file docker-reg-cred.yaml

```
	 kubectl get secret docker-reg-cred  --output=yaml```
```

- Replace  **/home/user/.docker/config.json** with your docker config and  **docker-reg-cred ** with desired name, Here in all the config files the registry secret name is **docker-reg-cred**, if its changed , change it in the **eks/deployment.yaml**


### Setup the Cluster

- Create ssh key pairs for the EC2 instances and place them in **eks/ssh** directory
- Generate  ssh key by
	 ```
	  ssh-keygen
	 ```
- Rename the files as **eks** and **eks.pub** 

- create the Cluster using the eks/cluster-config.yaml 
	```
	 kubectl apply -f eks/cluster-config.yaml 
	```

#### create a service acount 

-Create a policy in AWS IAM with EC2 , S3, EKS full access,
- Update the policy ARN in the annotation section in the eks/service-account.yaml
- Create service account
	```
	   kubectl apply -f eks/service-account.yaml
	```

#### Deployment

- Create the secrets for the docker registry (file created using previous step) and SSL files
	  ```
	  kubectl apply -f eks/docker-reg-cred.yaml
	  ```

- convert the SSL files into Base64 string  and update them in eks/TLS-secret-domain.com.yaml
- Convert SSL files to base 64
	 ```
	 cat certificate.crt | base64 |  tr -d '\n' 
	 ```
	 ```
	 cat private.key | base64 |  tr -d '\n' 
	 ```

- Create the domain secret after updating the secret YAML file.
	 ```
	  kubectl -f  eks/TLS-secret-domain.com.yaml
	 ```

- Create the deployment 
	 ```
    kubectl -f  eks/deployment.yaml
	 ```

- Create a service to expose the PORTS in the conatiner

	```
  kubectl apply -f eks/services.yaml
	```

- Create an Ingress controller to expose the service PORTS
	```
	 kubectl apply -f eks/ingresss-nginx.yaml
	```

### Scaling 
#### Auto Scale the Pods, horizontally
 ##### Check metric server Installed in your cluster
 ```
 kubectl -n kube-system get deployment/metrics-server
 ```
- If this returns none , add metric server by 
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml
```

- check status of the metric server
```
kubectl get deployment metrics-server -n kube-system
```
- create pod auto scaling 
  ```
  kubectl -f eks/pod-autosacling.yaml
  ```

#### Auto scale the Cluster

- Add ecessary resources by 
	```
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
	```
- Add the cluster-autoscaler.kubernetes.io/safe-to-evict annotation to the deployment with the following command.
	```
	kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"
	```
- Edit the Cluster Autoscaler deployment and modify , the cluster name
	```
	KUBE_EDITOR="nano" kubectl -n kube-system edit deployment.apps/cluster-autoscaler
	```

### Attach Network Load balacer (NLB) to expose the APPs in the cluster
 ```
 kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml
 ```
- This will create a network load balancer will will be connected to your EKS cluster .

To delete the loadbalancer and associated resources 
```
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml
```

![](https://quip-amazon.com/blob/bGA9AAmviCK/11tDfN7IqiC8qv7bZS50qw?a=Uf6IToPAN5W87b0DphRwhQxMafnFU1WYA0ya6pLXR0Ua)


- Add Load balancer endpoint as CNAME for the domains

  



