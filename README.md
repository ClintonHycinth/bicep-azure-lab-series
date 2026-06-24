# Bicep Azure Lab Series

A structured 8-lab series deploying real Azure infrastructure using Bicep.
Each lab builds on the previous one, culminating in a single modular
deployment that provisions a complete Azure environment from scratch.

Built as hands-on AZ-104 exam preparation and portfolio evidence for cloud
engineering roles.

## The series

| Lab | Title                                                | AZ-104 Domain                    |
| --- | ---------------------------------------------------- | -------------------------------- |
| 01  | Resource Groups and Tagging Governance               | Manage identities and governance |
| 02  | Virtual Network with Subnets and NSGs                | Configure virtual networking     |
| 03  | Storage Account with Lifecycle and Diagnostics       | Implement and manage storage     |
| 04  | Linux VM with Availability Zone and Boot Diagnostics | Deploy and manage compute        |
| 05  | Load Balancer with Backend Pool and Health Probe     | Deploy compute / networking      |
| 06  | RBAC Role Assignments via Bicep                      | Manage identities and governance |
| 07  | Azure Monitor Alerts and Action Group                | Monitor and maintain resources   |
| 08  | Full Environment Deployment with What-If             | All domains                      |

## What this series builds

Starting from nothing, each lab deploys into the same Azure environment:

- Two resource groups with mandatory tags enforced at subscription scope
- A three-tier Virtual Network with NSGs enforcing least privilege between tiers
- A storage account with lifecycle management, soft delete, and diagnostic logs
- A Linux VM in availability zone 1 with boot diagnostics
- A Standard Load Balancer with two VMs across two availability zones
- RBAC role assignments scoped to individual resource groups
- Azure Monitor metric and log alerts with email notifications
- A root orchestrator that deploys everything in one command

## Architecture

Subscription

├── rg-networking-dev

│ ├── vnet-lab-dev

│ │ ├── snet-web (nsg-web-dev: allows HTTP/HTTPS)

│ │ ├── snet-app (nsg-app-dev: allows web tier only)

│ │ └── snet-data (nsg-data-dev: allows app tier only)

│ ├── clintonbiceplab08dev (storage account)

│ │ ├── raw-data

│ │ ├── processed-data

│ │ └── archived-data

│ ├── law-lab-dev (Log Analytics workspace)

│ ├── ag-lab-dev (action group)

│ ├── alert-cpu-dev (metric alert)

│ └── alert-storage-delete-dev (query alert)

└── rg-compute-dev

├── vm-web-dev (zone 1)

├── vm-lb1-dev (zone 1)

├── vm-lb2-dev (zone 2)

└── lb-web-dev (Standard Load Balancer)

## Key engineering decisions

**Governance before deployment.** Resource groups and tags are established
at subscription scope before any workload resources are deployed. Every
resource carries environment, owner, and cost centre tags from the start.

**Network segmentation.** Three subnets with independent NSGs enforce the
principle of least privilege at the network level. The web tier accepts
public traffic. The app tier only accepts traffic from the web tier. The
data tier only accepts traffic from the app tier.

**Cost-optimised storage.** Lifecycle management automatically moves blobs
from Hot to Cool after 30 days, to Archive after 90 days, and deletes them
after 365 days. Storage costs are controlled by the infrastructure, not by
manual intervention.

**Availability by design.** VMs are placed across availability zones. The
load balancer distributes traffic and removes unhealthy VMs from rotation
automatically. Resiliency is built in at deployment time.

**Access control as code.** RBAC role assignments are deployed via Bicep
modules. Every access decision is version-controlled and repeatable. Reader
on networking, Contributor on compute, scoped to resource groups.

**Proactive monitoring.** CPU metric alerts and storage delete query alerts
notify the operations team before issues affect users. The Log Analytics
workspace is the central destination for all diagnostic logs.

**Modular architecture.** Lab 08 orchestrates all previous labs as modules
in a single deployment. Environment separation is handled through parameter
files. What-if validation runs before every deployment.

## Deployment

### Prerequisites

- Azure subscription
- Azure CLI
- Bicep CLI

### Deploy the full environment

```bash
cd lab-08-full-environment

az deployment sub create \
  --name lab08-full-environment \
  --location southafricanorth \
  --template-file main.bicep \
  --parameters @dev.parameters.json
```

### Run what-if first

```bash
az deployment sub what-if \
  --name lab08-whatif \
  --location southafricanorth \
  --template-file main.bicep \
  --parameters @dev.parameters.json
```

### Teardown

```bash
bash teardown.sh dev
```

## Tools and technologies

- Microsoft Azure
- Bicep
- Azure CLI
- Azure Cloud Shell
- Git and GitHub

## Author

Clinton Hycinth  
Junior Cloud Engineer, Xenrex Technologies  
[GitHub](https://github.com/ClintonHycinth) | [LinkedIn](https://www.linkedin.com/in/clinton-hycinth)
