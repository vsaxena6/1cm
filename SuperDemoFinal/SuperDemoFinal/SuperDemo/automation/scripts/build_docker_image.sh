#!/usr/bin/bash

#app_input: Port#, Entrypoint, K8s cluster name, Namespace, AWS Region, AWS Account ID
#Reading from app-input.properties and we are getting the value of AWS Region and AWS Account ID

#Get the repository name while reading the file extensions. For .NET, if there is any file with .csproj extension, 
#then it will be the repository name. Repo name should be updated into app-input.properties (from program) 

# CLUSTER_NAME=$1
# GKE_ACCOUNT_ID=$2
# DOCKER_FILE_PATH=$3
# REPOSITORY_NAME=$4
# AZURE_RES_GROUP=$5 
# AZURE_REGION=$6
# CLOUD_FLAG_AZGCAW=$7
# AWS_ACCOUNT_ID=$8
# AWS_REGION=$9

## This will help to use arguments only for specific cloud environment.
##i.e., for AWS user have to only pass in information AWS_ACCOUNT_ID & AWS_REGION.

for ARGUMENT in "$@"
do

KEY=$(echo $ARGUMENT | cut -f1 -d=)
VALUE=$(echo $ARGUMENT | cut -f2 -d=)

            case "$KEY" in
               CLOUD_FLAG_AZGCAW)   CLOUD_FLAG_AZGCAW=${VALUE} ;;
               CLUSTER_NAME)       CLUSTER_NAME=${VALUE} ;;
               REPOSITORY_NAME)    REPOSITORY_NAME=${VALUE} ;;
               AZURE_REGION)       AZURE_REGION=${VALUE} ;;
               AZURE_RES_GROUP)    AZURE_RES_GROUP=${VALUE} ;;
               GKE_ACCOUNT_ID)     GKE_ACCOUNT_ID=${VALUE} ;;
               AWS_ACCOUNT_ID)     AWS_ACCOUNT_ID=${VALUE} ;;
               AWS_REGION)         AWS_REGION=${VALUE} ;;
               DOCKER_FILE_PATH)   DOCKER_FILE_PATH=${VALUE} ;;
                *)
            esac

done
date=`date +"%Y-%m-%d-%H-%M-%S"`


# Case of GCP
if [[ "$CLOUD_FLAG_AZGCAW" == "010" ]]; then
    IMG_NAME="gcr.io/$GKE_ACCOUNT_ID/$REPOSITORY_NAME:latest"
    #Authenticate yourself to GKE
    # gcloud auth login
    # Provide Creds to your service Account (Hardcoded currently)
    gcloud auth activate-service-account mysva-163@mytrial-323408.iam.gserviceaccount.com --key-file=mytrial-key.json
    #Configure Local Docker
    gcloud auth configure-docker
    #Enable Google Docker Registry
    gcloud services enable containerregistry.googleapis.com
    #Get GKE Creds for you to operate
    gcloud container clusters get-credentials $CLUSTER_NAME
    if [ $? -eq 0 ]; then
        echo 'Docker log-in successful' $date > log.txt
    else
        echo 'Docker log-in failed' $date  > log.txt
    fi
fi
# Case of Azure
if [[ "$CLOUD_FLAG_AZGCAW" == "100" ]]; then
    
    az login
    az group create --name $AZURE_RES_GROUP --location $AZURE_REGION
    az acr login --name 1cmregistry
    if [ $CLUSTER_NAME==0 ]; then
        #Create new AKS cluster with the same name as RES Group
        CLUSTER_NAME=$AZURE_RES_GROUP
        echo "CREATING A NEW AZURE CLUSTER WITH THE NAME: " $CLUSTER_NAME ". IT MAY TAKE SOME TIME..."
        az aks create --resource-group $AZURE_RES_GROUP --name $CLUSTER_NAME --node-count 2 --generate-ssh-keys
    fi
    echo "CLUSTER CREATED. AUTHENTICATING WITH THE CURRENT USER..." 
    az aks get-credentials --resource-group $AZURE_RES_GROUP --name $CLUSTER_NAME
    IMG_NAME="1cmregistry.azurecr.io/$REPOSITORY_NAME:latest"
fi

# Case of AWS
if [[ "$CLOUD_FLAG_AZGCAW" == "001" ]]; then
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
    #Creating repository to push image to repo
    aws ecr create-repository --repository-name $REPOSITORY_NAME --region $AWS_REGION
    #Authenticating with AWS Cluster which is already present
    aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME
    IMG_NAME="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPOSITORY_NAME:latest"
fi
#Build the image and push to the repo
if [ ! -z "$IMG_NAME" ]; then
    # Perform a local Docker build
    docker build -t $IMG_NAME $DOCKER_FILE_PATH
    if [ $? -eq 0 ]; then
        echo 'Docker local build successful' $date  > log.txt
    else
        echo 'Docker local build failed' $date > log.txt
    fi
    # Push into GCR (for GKE) and Docker Hub (for AKS)
    docker push $IMG_NAME
    if [ $? -eq 0 ]; then
        echo 'Image push successful' $date > log.txt
    else
        echo 'Image push failed' $date > log.txt
    fi
fi
