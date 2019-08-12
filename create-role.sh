#!/bin/sh 

if [ $# -lt 1 ] ; then
  echo -e "Usage: $0 role_name\n"
  exit 1
fi
   
role_name=$1
managed_policy="arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"

aws iam create-role --role-name $role_name \
    --assume-role-policy-document file://ec2-role-trust-policy.json \
    --description "Allows EC2 instances to call AWS services on your behalf"

aws iam attach-role-policy --role-name $role_name \
                           --policy-arn $managed_policy

aws iam create-instance-profile --instance-profile-name $role_name
aws iam add-role-to-instance-profile --instance-profile-name $role_name \
                                     --role-name $role_name
