#!/bin/bash
## Script to create deployment yaml file ##

if [ $# -ne 4 ]; then
        echo "Error: Number of arguments not equal to 4"
        echo "Info: Expecting 4 arguments, arg1 = project working directory, arg2 = repository name, arg3 = AWS Image arg4 = port number"
        exit 1
fi

WORK_DIR=$1
REPOSITORY_NAME=$2
IMG_NAME=$3
PORT_NUM=$4
DEPO_FL_NAME=$WORK_DIR/$REPOSITORY_NAME'_''deployment.yaml'

if [ -f "$DEPO_FL_NAME" ]; then
	rm -f  $DEPO_FL_NAME
fi

## YAML file creation ##

echo "apiVersion: apps/v1" >> $DEPO_FL_NAME
echo "kind: Deployment"  >> $DEPO_FL_NAME
echo "metadata:" >> $DEPO_FL_NAME
echo "  name: ${REPOSITORY_NAME}" >> $DEPO_FL_NAME
echo "  labels: " >> $DEPO_FL_NAME
echo "    app: ${REPOSITORY_NAME}" >> $DEPO_FL_NAME 
echo "spec:" >> $DEPO_FL_NAME
echo "  replicas: 1" >> $DEPO_FL_NAME
echo "  selector:" >> $DEPO_FL_NAME
echo "    matchLabels:" >> $DEPO_FL_NAME
echo "      app: ${REPOSITORY_NAME}"  >> $DEPO_FL_NAME
echo "  strategy: {}" >> $DEPO_FL_NAME
echo "  template:" >> $DEPO_FL_NAME
echo "    metadata:" >> $DEPO_FL_NAME
echo "      labels:" >> $DEPO_FL_NAME
echo "        app: ${REPOSITORY_NAME}"  >> $DEPO_FL_NAME
echo "    spec:"  >> $DEPO_FL_NAME
echo "      containers:" >> $DEPO_FL_NAME
echo "      - name: ${REPOSITORY_NAME}" >> $DEPO_FL_NAME
echo "        image: ${IMG_NAME}" >> $DEPO_FL_NAME
echo "        ports:"  >> $DEPO_FL_NAME
echo "        - containerPort: ${PORT_NUM}"  >> $DEPO_FL_NAME
echo "          protocol: TCP"  >> $DEPO_FL_NAME
