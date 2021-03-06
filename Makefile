ifndef ENVIRONMENT
    $(error ENVIRONMENT has to be passed as a parameter)
endif
ifndef ACCOUNT_ID
    $(error ACCOUNT_ID has to be passed as a parameter)
endif
ifndef AWS_PROFILE
    $(error AWS_PROFILE has to be passed as a parameter)
endif

##INFRASTRUCTURE

##WHITELIST THE IP RANGE OF THE THIRD PARTY HUB
_WHITELIST_IP = ${WHITELIST_IP}

deploy-backend-services:
	AWS_PROFILE=${AWS_PROFILE} aws cloudformation deploy \
		--stack-name vni-cpo-${ENVIRONMENT} \
		--template-file cloudformation/vni-cpo-backend.yml \
		--capabilities CAPABILITY_IAM \
		--parameter-overrides \
			Environment=${ENVIRONMENT} \
			ThirdPartyWhitelistIp=${_WHITELIST_IP} 

deploy-delivery-pipeline:
	AWS_PROFILE=${AWS_PROFILE} aws cloudformation deploy \
	--stack-name vni-cpo-deployment-pipeline-${ENVIRONMENT} \
	--template-file cloudformation/deployment-pipeline.yml \
	--capabilities CAPABILITY_IAM \
	--parameter-overrides \
			Environment=${ENVIRONMENT}

##CHARGING POINT BACKEND SERVICE

CP_IMAGE_NAME=vni-backend-charging-point-${ENVIRONMENT}

build-cp-backend: 
	docker build -t ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${CP_IMAGE_NAME} charging-point-backend/.

run-cp-backend-locally: build-cp-backend
	docker run -p 80:80 -p 5000:5000 ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/$(CP_IMAGE_NAME):latest

deploy-cp-backend: build-cp-backend
	$$(AWS_PROFILE=${AWS_PROFILE} aws ecr get-login --no-include-email --region eu-west-1)
	docker push ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${CP_IMAGE_NAME}:latest


##THIRD PARTY BACKEND SERVICE

TP_IMAGE_NAME=vni-backend-third-party-${ENVIRONMENT}

build-tp-backend: 
	docker build -t ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${TP_IMAGE_NAME} third-party-backend/.

run-tp-backend-local: build-tp-backend
	docker run -p 80:80 ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/$(TP_IMAGE_NAME):latest

deploy-tp-backend: build-tp-backend
	$$(AWS_PROFILE=${AWS_PROFILE} aws ecr get-login --no-include-email --region eu-west-1)
	docker push ${ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com/${TP_IMAGE_NAME}:latest


##RUN CHARGING POINT SIMULATOR LOCALLY

_BACKEND_HOSTNAME = ${BACKEND_HOSTNAME}

run-charging-point-simulator:
	docker run -e BACKEND_URL=${_BACKEND_HOSTNAME} vni-cpo-client
	$(info BACKEND_HOSTNAME should be an IP address of charging-point-backend service)


##EXAMPLE OF CREATING GLOBAL ACCELERATOR
create-global-accelerator:
	AWS_PROFILE=${AWS_PROFILE} aws globalaccelerator create-accelerator \
    	--name third-party-backend-${ENVIRONMENT} \
    	--region us-west-2 --idempotency-token third-party-backend-aswrkfsd

create-globalaccelerator-listener:
	AWS_PROFILE=${AWS_PROFILE} aws globalaccelerator create-listener \
		--accelerator-arn ${ACCELERATOR_ARN} \
		--port-ranges FromPort=443,ToPort=443  \
		--protocol TCP --region us-west-2  --idempotency-token third-party-backend-aswrkfsd 

create-globalaccelerator-endpoint:
	AWS_PROFILE=${AWS_PROFILE} aws globalaccelerator create-endpoint-group \
		--listener-arn ${LISTENER_ARN} \
		--endpoint-group-region eu-west-1 --region us-west-2 \
		--endpoint-configurations \
		EndpointId=${LOADBALANCER_ARN},Weight=128 --idempotency-token third-party-backend-aswrkfsd 