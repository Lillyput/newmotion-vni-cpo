_ACCOUNT_ID = ${ACCOUNT_ID}
_ENVIRONMENT = ${ENVIRONMENT}

##INFRASTRUCTURE

PROJECT = vni-backend
BACKEND_MEM = 1024
BACKEND_CPU = 512
SERVER_NUM = 3
BACKEND_PORT = 80
WHITELIST_IP = 95.96.252.213/32

deploy-stack:
	AWS_PROFILE=${AWS_PROFILE} aws cloudformation deploy \
		--stack-name vni-cpo-${_ENVIRONMENT} \
		--template-file cloudformation/vni-cpo.yml \
		--capabilities CAPABILITY_IAM \
		--parameter-overrides \
			Project=${PROJECT} Environment=${_ENVIRONMENT} \
			BackendMem=${BACKEND_MEM} BackendCPU=${BACKEND_CPU} \
			ServerNum=${SERVER_NUM} BackendPort=${BACKEND_PORT} WhitelistIp=${WHITELIST_IP} 

deploy-delivery-pipeline:
	AWS_PROFILE=${AWS_PROFILE} aws cloudformation deploy \
	--template-file cloudformation/deployment-pipeline.yml \
	--stack-name vni-cpo-deployment-pipeline-${ENVIRONMENT} \
	--capabilities CAPABILITY_IAM


##CHARGING POINT BACKEND SERVICE

IMAGE_NAME=${PROJECT}-${_ENVIRONMENT}

build-cp-backend: 
	docker build -t ${_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/$(IMAGE_NAME) charging-point-backend/.

run-cp-backend-local: build-cp-backend
	docker run -p 80:80 -p 5000:5000 ${_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/$(IMAGE_NAME):latest

deploy-cp-backend: build-cp-backend
	$$(AWS_PROFILE=${AWS_PROFILE} aws ecr get-login --no-include-email --region eu-west-1)
	docker push ${_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/$(IMAGE_NAME):latest

##TEST

_BACKEND_HOSTNAME = ${BACKEND_HOSTNAME}

run-test:
	docker build -t vni-cpo-test test/.
	docker run -e BACKEND_URL=${_BACKEND_HOSTNAME} vni-cpo-test