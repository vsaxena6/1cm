#!/bin/bash
## Script to create Service yaml file ##

if [ $# -ne 4 ]; then
        echo "Error: Number of arguments not equal to 3"
        echo "Info: Expecting 3 arguments, arg1 = project working directory, arg2 = repository name, arg3 = port number, arg4 = External Port Number"
        exit 1
fi

WORK_DIR=$1
REPOSITORY_NAME=$2
PORT_NUM=$3
LAUNCH_PORT=$4
SERV_FL_NAME=$WORK_DIR/$REPOSITORY_NAME'_''service.yaml'
#echo $SERV_FL_NAME

if [ -f "$SERV_FL_NAME" ]; then
	rm -f  $SERV_FL_NAME
fi

#echo $REPOSITORY_NAME

## YAML file creation ##

echo "apiVersion: v1" >> $SERV_FL_NAME
echo "kind: Service"  >> $SERV_FL_NAME
echo "metadata:" >> $SERV_FL_NAME
echo "  name: ${REPOSITORY_NAME}" >> $SERV_FL_NAME 
echo "spec:" >> $SERV_FL_NAME
echo "  ports:"  >> $SERV_FL_NAME
echo "    - protocol: TCP" >> $SERV_FL_NAME
echo "      port: ${LAUNCH_PORT}" >> $SERV_FL_NAME
echo "      targetPort: ${PORT_NUM}" >> $SERV_FL_NAME 
echo "  selector:" >> $SERV_FL_NAME
echo "    app: ${REPOSITORY_NAME}" >> $SERV_FL_NAME
echo "  type: LoadBalancer" >> $SERV_FL_NAME