#!/bin/bash

if test "$BASH" = ""; then
  echo "You must use: bash $0"
  exit 1
fi

apt update

apt -y install default-jre awscli

wget -c https://s3.ap-south-1.amazonaws.com/dynamodb-local-mumbai/dynamodb_local_latest.tar.gz
if [[ "$?" -gt 0 ]]; then
  echo "Cannot download DynamoDb"
  exit 1
fi

mkdir -p /usr/lib/dynamodb
tar xf dynamodb_local_latest.tar.gz -C /usr/lib/dynamodb
rm dynamodb_local_latest.tar.gz

aws configure set aws_access_key_id local
aws configure set aws_secret_access_key local
aws configure set region local

cd /usr/lib/dynamodb
java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -sharedDb >/dev/null 2>&1 &

aws dynamodb create-table --table-name test --attribute-definitions AttributeName=s_partition,AttributeType=S AttributeName=s_sort,AttributeType=S --key-schema AttributeName=s_partition,KeyType=HASH AttributeName=s_sort,KeyType=RANGE --provisioned-throughput ReadCapacityUnits=10,WriteCapacityUnits=5 --endpoint-url http://localhost:8000