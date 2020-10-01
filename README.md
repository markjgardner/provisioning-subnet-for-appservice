# Automated provisiong of subnets for app services
This repo illustrates one method of automatically provisioning a subet for an app service during deployment using Azure DevOps Pipelines.

## Prerequisites
* existing vnet with preallocated subnets (/27's is this example)
* pipeline service principal has contributor access on vnet
* target resource group to contain app service

## Solution requirements
* if app service does not already exist
  * allocate a subnet by tagging it with the appname
  * provision a new app service and assign the allocated subnet
* if app service already exists but does not have an associated subnet
  * allocate a subnet by tagging it with the appname
  * update the app service and assign the subnet
* if app service already exists and has an assigned subnet
  * NoOp
* a subnet may only be allocated to exactly one app service
* if no subnets are available, pipeline should fail and app service should not be provisioned/configured
