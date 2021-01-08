#!/usr/bin/env bash
# Print the names, read units, and write units for all DynamoDB tables in a region
set -o errexit
set -o nounset
aws=${1}
region=${2}

function show_table() {
    ${aws} dynamodb describe-table --table-name ${1} --output text --query "Table.{Name:TableName,Read:ProvisionedThroughput.ReadCapacityUnits,Write:ProvisionedThroughput.WriteCapacityUnits}"
}

for table in $(${aws} dynamodb list-tables --region ${region} --output text --query 'TableNames')
do
  show_table ${table}
done
