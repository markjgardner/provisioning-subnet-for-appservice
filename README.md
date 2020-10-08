# Automated provisiong of subnets for app services
This repo illustrates two methods of automatically provisioning a subet for an app service during deployment using Azure DevOps Pipelines.  
Ideally, keeping track of subnet assignments is a job best solved by a configuration management database (CMDB). However, it has been my experience that lots of organizations lack this fundamental capability. So this examples offers options for solving a specific problem in the absence of other tools for managing stateful representations of your physical architecture.

## Prerequisites
* existing vnet with preallocated subnets (/27's is this example)
  * subnets should already be delegated for app service integration
* pipeline service principal has contributor access on vnet
* pipeline service principal has reader on all app services integrated to the target vnet
* target resource group to contain deployed resources
* Azure CLI

## Solution requirements
* if app service does not already exist
  * allocate a subnet 
  * provision a new app service and assign the allocated subnet
* if app service already exists but does not have an associated subnet
  * allocate a subnet 
  * update the app service and assign the subnet
* if app service already exists and has an assigned subnet
  * NoOp
* a subnet may only be allocated to exactly one app service
* if no subnets are available (vnet fully allocated), pipeline should fail and app service should not be provisioned/configured

## Assumptions
### Tagged based method
* all subnets within the vnet are available for allocation
  * the powershell script, as written, has no mechanism for holding back reserved subnets (e.g. gateway subnets)