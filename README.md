# Multi-Region AWS VPC & Server Provisioning

Infrastructure as Code with Terraform. Provisions a secure VPC with public/private subnets, NAT gateway, and a load-balanced Linux EC2 fleet in **two AWS regions** from the same reusable modules.

## Architecture

Per region (identical, driven by the same modules):

```
                    Internet
                       |
                 [ Internet GW ]
                       |
        +--------------+---------------+
        |   Public subnets (2 AZ)      |
        |   - Application Load Balancer|
        |   - NAT Gateway              |
        +--------------+---------------+
                       |
        +--------------+---------------+
        |   Private subnets (2 AZ)     |
        |   - Auto Scaling Group       |
        |     Amazon Linux 2023 + nginx|
        +------------------------------+
```

| Region | Role | VPC CIDR |
|---|---|---|
| `eu-north-1` | primary | `10.0.0.0/16` |
| `us-east-1` | secondary | `10.1.0.0/16` |

## Features

- **Modular**: `vpc` and `compute` modules, called once per region via provider aliases.
- **Multi-AZ**: 2 public + 2 private subnets per VPC.
- **Secure by default**
  - EC2 instances live in private subnets, no public IPs.
  - Instance security group only accepts HTTP from the ALB security group.
  - IMDSv2 required on instances.
  - Outbound internet via NAT gateway.
- **Load balanced**: ALB with health checks, targets managed by an Auto Scaling Group (2 to 3 instances).
- **Always-current AMI**: latest Amazon Linux 2023 resolved from SSM Parameter Store.

## Project layout

```
.
├── main.tf          # providers (primary/secondary) and module calls
├── variables.tf     # region variables
├── outputs.tf       # ALB URLs and VPC IDs
└── modules/
    ├── vpc/         # VPC, subnets, IGW, NAT, route tables
    └── compute/     # security groups, launch template, ALB, ASG
```

## Prerequisites

- Terraform >= 1.5
- AWS credentials configured (`aws login`, `aws configure`, or environment variables)
- Permissions to create VPC, EC2, ELB, and Auto Scaling resources

## Usage

```bash
terraform init
terraform plan
terraform apply
```

Outputs:

```
primary_alb_url   = "http://<alb>.eu-north-1.elb.amazonaws.com"
secondary_alb_url = "http://<alb>.us-east-1.elb.amazonaws.com"
```

Wait ~2 minutes after apply for nginx to start, then open the URLs. Each page shows the region, instance ID and AZ. Refresh to watch the load balancer alternate between instances.

### Change regions

```bash
terraform apply -var="primary_region=eu-west-1" -var="secondary_region=ap-south-1"
```

## Verified deployment

Live check: `terraform plan` shows no drift, all 4 targets (2 per region) are healthy, and repeated requests alternate between instances in different AZs. Full output in [docs/verification.md](docs/verification.md).

More documentation: [docs index](docs/README.md), [architecture and workflow diagrams](docs/architecture.md), [raw evidence](docs/evidence/), [screenshot checklist](docs/screenshots/LINKS.md).

```
iaac-pri Region: eu-north-1 Instance: i-0ddc08e1eea2d6d06 (eu-north-1b)
iaac-pri Region: eu-north-1 Instance: i-011c0cf5dbcc7a96b (eu-north-1a)
```

## Accessing instances

Instances have no public IP and no key pair. There is no SSH path today. To get a shell (for example to ping from inside the VPC), add an instance profile with `AmazonSSMManagedInstanceCore` and use Session Manager. See "Possible improvements".

## Cost

NAT gateways and ALBs bill hourly. Running both regions costs roughly **$130/month**. Tear down when finished:

```bash
terraform destroy
```

## Possible improvements

- One NAT gateway per AZ for high availability.
- HTTPS listener with ACM certificate.
- Route 53 latency or failover routing across the two regions.
- Remote state in S3 with DynamoDB locking.
- Replace SSH-less access with SSM Session Manager (instance profile).
