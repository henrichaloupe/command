#!/bin/bash

if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: aws is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

profile=default
while getopts p: flag
do
    case "${flag}" in
        p) profile=${OPTARG};;
    esac
done

clusters=`aws ecs list-clusters --profile $profile --output json | jq -r '.clusterArns[]' | sed 's/.*\///g' | grep cluster`

options=($clusters)
if [ ${#options[@]} -eq 1 ] 
then
    cluster=${options[0]}
else
    PS3='Choose your cluster, please enter your choice: '
    select opt in "${options[@]}"
    do
        cluster=$opt
        break;
    done
fi

services=`aws ecs list-services --profile $profile --cluster $cluster --output json | jq -r '.serviceArns[]' | sed 's/.*\///g'`
options=($services)
if [ ${#options[@]} -eq 1 ] 
then
    service=${options[0]}
else
    PS3='Choose your service, please enter your choice: '
    select opt in "${options[@]}"
    do
        service=$opt
        break;
    done
fi

tasks=`aws ecs list-tasks --profile $profile --cluster $cluster --service-name $service --output json | jq -r '.taskArns[]' | sed 's/.*\///g'`

options=($tasks)

if [ ${#options[@]} -eq 1 ] 
then
    task=${options[0]}
else
    PS3='Choose your task, please enter your choice: '
    select opt in "${options[@]}"
    do
        task=$opt
        break;
    done
fi

container=`aws ecs  describe-tasks --profile $profile --tasks $task --cluster $cluster | jq '.tasks[].overrides.containerOverrides[].name' | grep -v log_router | grep -v datadog | sed 's/"//g'`

echo --------------------
echo  Cluster : $cluster
echo  Service : $service
echo  Task : $task
echo  container : $container
echo --------------------


aws ecs execute-command \
    --profile $profile  \
    --cluster $cluster   \
    --task $task   \
    --container $container   \
    --command "/bin/bash"   \
    --interactive
