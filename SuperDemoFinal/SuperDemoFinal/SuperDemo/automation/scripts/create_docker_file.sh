#!/bin/bash

if [ $# -ne 2 ]; then
	echo "Error: Number of arguments not equal to 2"
	echo "Info: Expecting 1 argument, arg1 = project working directory, arg2 = Docker file template directory"
	exit 1
fi

extn_details=seg_file.txt
work_dir=$1
dock_temp_dir=$2
dotnet_template=Dockerfile
java_tempate=Dockerfile_java
python_template=Dockerfile_python
docker_file=Dockerfile
#java_template=Dockerfile
python_props=python_apps.properties
java_props=java_apps.properties
dotnet_props=cspdotnet_apps.properties

check_extension() {
	if [ $2 = "python" ]; then
		#echo "Python - Building Docker File for "  $2
		cp $dock_temp_dir/$python_template $work_dir/$docker_file
		sh ./read_props.sh $work_dir $python_props $docker_file
	elif [ $2 = "java" ]; then
		#echo "Building Docker File for" $2
		cp $dock_temp_dir/$java_template $work_dir/$docker_file
		echo "Java"
		sh ./read_props.sh $work_dir $java_props $docker_file
	elif [ $2 = "csproj" ]; then
		echo "Building Docker File for" $2
		cp $dock_temp_dir/$dotnet_template $work_dir/$docker_file
		sh ./read_props.sh $work_dir $dotnet_props $docker_file
	elif [ $2 = "asp" ]; then
	      echo $2	
	fi
        
}


while IFS='' read -r line; do
	#echo "Text read from file: $line"	
	check_extension $line
done < $extn_details

