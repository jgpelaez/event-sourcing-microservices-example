.PHONY: help
.DEFAULT_GOAL := help


install-helm: ## install-helm
	kubectl -n kube-system create serviceaccount tiller
	kubectl create clusterrolebinding tiller \
	  --clusterrole cluster-admin \
	  --serviceaccount=kube-system:tiller
	helm init --service-account=tiller
	
update-deps: ## update-deps
	helm dep update deployment/helm/social-network
	helm dep update deployment/helm/friend-service
	helm dep update deployment/helm/user-service
	helm dep update deployment/helm/recommendation-service
	
social-network-main: ## social-network-main
	helm install --namespace social-network --name social-network --set fullNameOverride=social-network \
	  deployment/helm/social-network
	  
social-network: ## social-network
	helm install --namespace social-network --name friend-service --set fullNameOverride=friend-service \
	  deployment/helm/friend-service
	helm install --namespace social-network --name user-service --set fullNameOverride=user-service \
	  deployment/helm/user-service
	helm install --namespace social-network --name recommendation-service --set fullNameOverride=recommendation-service \
	  deployment/helm/recommendation-service
	helm install --namespace social-network --name edge-service --set fullNameOverride=edge-service \
	  deployment/helm/edge-service
	kubectl config set-context minikube --namespace=social-network
	#kubectl expose deployment/recommendation-service-neo4j-replica --name=social-network-neo4j
	kubectl expose pod/recommendation-service-neo4j-core-0 --name=social-network-neo4j

fill-db: ## fill-db	
	sh ./deployment/sbin/generate-serial.sh

port-forward-edge: ## port-forward-edge
	kubectl --namespace social-network port-forward svc/edge-service 9000
	
port-forward-neo: ## port-forward-edge
	kubectl --namespace social-network port-forward svc/social-network-neo4j 7474 7687
	
	
social-network-delete: ## social-network-delete
	helm delete --purge social-network
	helm delete --purge friend-service
	helm delete --purge edge-service
	helm delete --purge user-service
	helm delete --purge recommendation-service
	
scale-down-all:
	kubectl config set-context minikube --namespace=social-network
	kubectl scale --replicas=0 deployment/edge-service
	kubectl scale --replicas=0 deployment/recommendation-service
	kubectl scale --replicas=0 deployment/friend-service
	kubectl scale --replicas=0 deployment/user-service
	kubectl scale --replicas=0 deployment/social-network-prometheus-server
	kubectl scale --replicas=0 deployment/social-network-prometheus-kube-state-metrics	
	kubectl scale --replicas=0 deployment/social-network-grafana
	kubectl scale --replicas=0 statefulset/recommendation-service-neo4j-core
	kubectl scale --replicas=0 statefulset/friend-db
	kubectl scale --replicas=0 statefulset/user-db
	kubectl scale --replicas=0 statefulset/kafka
	kubectl scale --replicas=0 statefulset/social-network-zookeeper
	
scale-up-all:
	kubectl config set-context minikube --namespace=social-network
	kubectl scale --replicas=1 deployment/edge-service
	kubectl scale --replicas=1 deployment/recommendation-service
	kubectl scale --replicas=1 deployment/friend-service
	kubectl scale --replicas=1 deployment/user-service
	kubectl scale --replicas=1 deployment/social-network-prometheus-server
	kubectl scale --replicas=1 deployment/social-network-prometheus-kube-state-metrics
	kubectl scale --replicas=1 deployment/social-network-grafana
	kubectl scale --replicas=1 statefulset/recommendation-service-neo4j-core
	kubectl scale --replicas=1 statefulset/friend-db
	kubectl scale --replicas=1 statefulset/user-db
	kubectl scale --replicas=3 statefulset/kafka
	kubectl scale --replicas=3 statefulset/social-network-zookeeper

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
