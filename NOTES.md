# Terraform

## [Getting Started with Terraform for Azure](https://www.youtube.com/playlist?list=PLD7svyKaquTlE9dErhMazFhWbSSCfMP_4)

### Key Terraform Features

- Infrastructure as Code - blueprint of datacentre in version control to be shared and reused
- Execution Plans - planning step which generates an execution plan which shows what Terraform will do when applying changes
- Resource Graph - allows parallelisation and modification of non-dependent resources
- Change Automation - complex change sets applied with minimal human intervention 

### Terraform and Configuration Management

There is some overlap between tools, however the key areas of focus for each are:

| Terraform                                       | Configuration Management (Chef/Puppet) |
| ----------------------------------------------- | -------------------------------------- |
| Infrastructure Automation                       | OS configuration                       |
| VM and Cloud provisioning                       | Application installation               |
| Declarative like configuration management tools | Declarative                            |
| Limited OS configuration management             | Limited infrastructure automaton       |

### Terraform Use Cases

- Infrastructure Deploy - network, storage, compute, etc.
- Multi-tier Application Install 
- Self-Service - perhaps part of a service request workflow
- Disposable Environments - demo, test, etc.
- Multi-cloud

### Terraform Execution Lifecycle

#### Plan

*What things will Terraform do*

#### Apply

*Create the things*

#### Destroy

*Remove the things*