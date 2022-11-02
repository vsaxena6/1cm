#!/usr/bin/bash

if [ $# -ne 1 ]; then
	echo "Error: Number of arguments not equal to 1"
	echo "Info: Expecting 1 argument, arg1 = project working directory"
	exit 1
fi

dir_name="$1"
docker_temp_dir="/c/automation/superdemo/automation/template"
#extn="$2"
#search_extn="*.""$extn"

segregate_files() {

	find "$dir_name" -type f | sed -n 's/..*\.//p' | sort | uniq -c > seg_file.txt
	echo "Details of file extensions inside directory "$dir_name" and corresponding counts are written to file "seg_file.txt""
}

find_files() {
	find "$dir_name" -type f -name "$search_extn" > file_details.txt
	echo "Details of files with extension "$search_extn" inside "$dir_name" are written to file "file_details.txt""
}

wait_function() {
    count=0
    total=34
    pstr="[=======================================================================]"
    echo "Analyzing the app..."
    while [ $count -lt $total ]; do
        sleep 0.2 # this is work
        count=$(( $count + 1 ))
        pd=$(( $count * 73 / $total ))
        printf "\r%3d.%1d%% %.${pd}s" $(( $count * 100 / $total )) $(( ($count * 1000 / $total) % 10 )) $pstr
    done
}

if [ -d "$dir_name" ]; then
    wait_function
	segregate_files
    echo "THIS IS A .NET WEB APPLICATION BUILT USING .NET CORE v3.1"
    sleep 10s
	#find_files
	if [ $? -eq 0 ]; then
        echo "CREATING THE BUILD FILE FOR THIS APPLICATION..."
        sleep 10s
		sh ./create_docker_file.sh $dir_name $docker_temp_dir
	fi
else
	echo "Error: Directory $dir_name does not exists!!"
	exit 1
fi

