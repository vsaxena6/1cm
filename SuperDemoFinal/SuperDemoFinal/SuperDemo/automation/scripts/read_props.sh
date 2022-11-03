#!/usr/bin/bash
if [ $# -ne 3 ]; then
	echo "Error: Number of arguments not equal to 3"
	#echo "Info: Expecting 1 arguments, arg1 = application properties path"
	exit 1
fi
WORK_DIR=$1
PROP_FILE=$2
DOCK_TEMP=$3
#PROPS=$(mktemp -d)
while IFS='=' read -r k v; do
	#echo "Replacing variable in docker template" $k " With value " $v
	sed -i "s/$k/$v/g" $WORK_DIR/$DOCK_TEMP
	#echo $v > $PROPS/$k
	if [ "$k" = "%%GKE_ACCOUNT_ID%%" ]; then
		GKE_ACCOUNT_ID=$v
	elif [ "$k" = "%%CLUSTERNAME%%" ]; then
		CLUSTER_NAME=$v
	elif [ "$k" = "%%REPOSITORY_NAME%%" ]; then
		REPOSITORY_NAME=$v
	elif [ "$k" = "%%EXPOSE%%" ]; then
		PORT_NUM=$v
	elif [ "$k" = "%%CSPROJPATH%%" ]; then
		PROJ_PATH=$v
	elif [ "$k" = "%%COPY1%%" ]; then
		DEST_PATH=$v
	elif [ "$k" = "%%WORKDIR3%%" ]; then
		DEST_WORKDIR=$v
	elif [ "$k" = "%%AZURE_REGION%%" ]; then
		AZURE_REGION=$v
	elif [ "$k" = "%%AZURE_RES_GROUP%%" ]; then
		AZURE_RES_GROUP=$v
	elif [ "$k" = "%%LAUNCH_PORT%%" ]; then
		LAUNCH_PORT=$v
	elif [ "$k" = "%%CLOUD_FLAG_AZGCAW%%" ]; then
		CLOUD_FLAG_AZGCAW=$v
	elif [ "$k" = "%%AWS_ACCOUNT_ID%%" ]; then
		AWS_ACCOUNT_ID=$v
	elif [ "$k" = "%%AWS_REGION%%" ]; then
		AWS_REGION=$v
	fi

done < $WORK_DIR/$PROP_FILE

echo "DOCKER FILE CREATED SUCCCESSFULLY AND PLACED AT - " $WORK_DIR " - AND FILE NAME IS - " $DOCK_TEMP
echo "Cloud Flag value is: " $CLOUD_FLAG_AZGCAW

# This is for GKE
# if [ "$CLOUD_FLAG_AZGCAW" == "010" ]
# then
#	echo "STARTING GCP PROVISIONING & BUILD..."
#	echo "You selected Google Cloud Platform with Account: $GKE_ACCOUNT_ID."
#	sleep 5s
#	AZURE_RES_GROUP=0
#	AZURE_REGION=0
	
#	GKE_IMAGE="gcr.io/$GKE_ACCOUNT_ID/$REPOSITORY_NAME:latest"
#	sh build_docker_image.sh CLUSTER_NAME=$CLUSTER_NAME GKE_ACCOUNT_ID=$GKE_ACCOUNT_ID DOCKER_FILE_PATH=$WORK_DIR REPOSITORY_NAME=$REPOSITORY_NAME CLOUD_FLAG_AZGCAW=$CLOUD_FLAG_AZGCAW
#	IMG_NAME=$GKE_IMAGE
#fi

# This is for AZURE
#if [[ "$CLOUD_FLAG_AZGCAW" == "100" ]]
#then
	echo "STARTING AZURE PROVISIONING & BUILD..."
	echo "You selected Azure cloud with Azure resource group: $AZURE_RES_GROUP & Region: $AZURE_REGION."
	sleep 5s
	GKE_ACCOUNT_ID=0
	if [ -z "$CLUSTER_NAME" ]; then
		CLUSTER_NAME=0;
	fi
	AZ_IMAGE="1cmregistry.azurecr.io/$REPOSITORY_NAME:latest"
	sh build_docker_image.sh CLUSTER_NAME=$CLUSTER_NAME DOCKER_FILE_PATH=$WORK_DIR REPOSITORY_NAME=$REPOSITORY_NAME AZURE_RES_GROUP=$AZURE_RES_GROUP AZURE_REGION=$AZURE_REGION CLOUD_FLAG_AZGCAW=$CLOUD_FLAG_AZGCAW
	IMG_NAME=$AZ_IMAGE
#fi

# This is for AWS
#if [ "$CLOUD_FLAG_AZGCAW" == "001" ]
#then
#	echo "STARTING AWS PROVISIONING & BUILD..."
#	echo "You selected Amazon Web Services cloud with Account: $AWS_ACCOUNT_ID & Region: $AWS_REGION."
#	sleep 5s
#	if [ -z "$CLUSTER_NAME" ]; then
#		CLUSTER_NAME=0;
#	fi
#	AWS_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:latest"
#	sh build_docker_image.sh CLUSTER_NAME=$CLUSTER_NAME DOCKER_FILE_PATH=$WORK_DIR REPOSITORY_NAME=$REPOSITORY_NAME  CLOUD_FLAG_AZGCAW=$CLOUD_FLAG_AZGCAW AWS_ACCOUNT_ID=$AWS_ACCOUNT_ID AWS_REGION=$AWS_REGION
#	IMG_NAME=$AWS_IMAGE
#fi
# Create Kubernetes Objects dynamically and deploy
echo "DOCKER IMAGE GENERATED SUCCESSFULLY AND NAME IS: " $IMG_NAME 
sleep 10s
if [ ! -z "$IMG_NAME" ]; then
	if [ $? -eq 0 ]; then
		sh create_deployment_yaml.sh $WORK_DIR $REPOSITORY_NAME $IMG_NAME $PORT_NUM
		echo "DEPLOYMENT YAML CREATED DYNAMICALLY"
		sleep 10s
		sh create_service_yaml.sh $WORK_DIR $REPOSITORY_NAME $PORT_NUM $LAUNCH_PORT
		echo "SERVICE YAML CREATED DYNAMICALLY"
		sleep 10s
	fi
	kubectl apply -f $WORK_DIR/$REPOSITORY_NAME'_''deployment.yaml'
	kubectl apply -f $WORK_DIR/$REPOSITORY_NAME'_''service.yaml'
	echo "KUBERNETES OBJECTS CREATED SUCCESSFULLY"
	sleep 10s
	#Check whether LoadBalancer assigned to the new service
	count=0
	total=30
	start=`date +%s`
	echo "WAITING FOR LOADBALANCER TO BE LAUNCHED..."
	while [ $count -lt $total ]; do
		sleep 2 # this is work
		cur=`date +%s`
		count=$(( $count + 1 ))
		pd=$(( $count * 73 / $total ))
		runtime=$(( $cur-$start ))
		estremain=$(( ($runtime * $total / $count)-$runtime ))
		printf "\r%d.%d%% complete - est %d:%0.2d remaining\e[K" $(( $count*100/$total )) $(( ($count*1000/$total)%10)) $(( $estremain/60 )) $(( $estremain%60 ))
	done

	EXTERNAL_IP=0
	while true
	do
	    kubectl get svc $REPOSITORY_NAME >  $WORK_DIR/svclog.txt
	    EXTERNAL_IP=$(cat $WORK_DIR/svclog.txt | grep -w $REPOSITORY_NAME | awk '{print $4}')
		#kubectl get svc $REPOSITORY_NAME -o custom-columns=EXTERNALIP:.status.loadBalancer.ingress[0].ip > $WORK_DIR/svclog.txt
		#EXTERNAL_IP=$(cat $WORK_DIR/svclog.txt | awk "NR==2")grep
		
		if [[ "$EXTERNAL_IP" != "<none>" ]]; then
			echo "-------------------------------------------------------------------------------------------"
			echo "YOUR APPLICATION IS SUCCESSFULLY DEPLOYED AND CAN BE ACCESSIBLE WITH FOLLOWING LINK"
			echo "http://${EXTERNAL_IP}:${LAUNCH_PORT}"
			echo "-------------------------------------------------------------------------------------------"
			sleep 10s
			echo "PRESS ANY KEY TO LAUNCH THE APP FROM HERE..."
			read tmp
			chrome http://${EXTERNAL_IP}:${LAUNCH_PORT}
			if [ $? -eq 0 ]; then
				sleep 10s
		    	exit 0
	          fi
		fi
	done
fi

