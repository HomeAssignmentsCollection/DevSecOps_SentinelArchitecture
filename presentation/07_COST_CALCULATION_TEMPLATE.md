# Universal Cost Calculation Template for Infrastructure Projects

## Template Overview

This template provides a standardized approach to cost calculation for infrastructure projects across different cloud providers and technologies. It can be customized for any project type and scale.

## 1. Project Information Template

### Basic Project Details
```yaml
project_info:
  name: "[PROJECT_NAME]"
  description: "[PROJECT_DESCRIPTION]"
  cloud_provider: "[AWS/AZURE/GCP]"
  region: "[REGION]"
  environment: "[dev/staging/prod]"
  duration_months: "[DURATION]"
  team_size: "[TEAM_SIZE]"
  expected_users: "[USER_COUNT]"
  compliance_requirements: "[COMPLIANCE_LEVEL]"
```

### Architecture Components
```yaml
architecture_components:
  compute:
    - service: "[SERVICE_NAME]"
      instance_type: "[INSTANCE_TYPE]"
      count: "[INSTANCE_COUNT]"
      purpose: "[PURPOSE]"
      availability: "[AVAILABILITY_REQUIREMENT]"
  
  storage:
    - service: "[SERVICE_NAME]"
      storage_type: "[STORAGE_TYPE]"
      size_gb: "[SIZE_GB]"
      purpose: "[PURPOSE]"
      retention_policy: "[RETENTION_DAYS]"
  
  networking:
    - service: "[SERVICE_NAME]"
      bandwidth: "[BANDWIDTH]"
      data_transfer: "[ESTIMATED_GB_MONTH]"
      purpose: "[PURPOSE]"
  
  security:
    - service: "[SERVICE_NAME]"
      features: "[FEATURES]"
      compliance: "[COMPLIANCE_LEVEL]"
      purpose: "[PURPOSE]"
  
  monitoring:
    - service: "[SERVICE_NAME]"
      metrics: "[METRICS_COUNT]"
      retention_days: "[RETENTION_DAYS]"
      purpose: "[PURPOSE]"
```

## 2. Cost Calculation Framework

### Resource Cost Calculation Template
```yaml
cost_calculation:
  compute_costs:
    - resource: "[RESOURCE_NAME]"
      unit_cost: "[COST_PER_UNIT]"
      units: "[NUMBER_OF_UNITS]"
      monthly_cost: "[UNIT_COST * UNITS]"
      annual_cost: "[MONTHLY_COST * 12]"
      optimization_potential: "[SAVINGS_PERCENTAGE]"
  
  storage_costs:
    - resource: "[RESOURCE_NAME]"
      unit_cost: "[COST_PER_GB_MONTH]"
      size_gb: "[SIZE_GB]"
      monthly_cost: "[UNIT_COST * SIZE_GB]"
      annual_cost: "[MONTHLY_COST * 12]"
      optimization_potential: "[SAVINGS_PERCENTAGE]"
  
  networking_costs:
    - resource: "[RESOURCE_NAME]"
      unit_cost: "[COST_PER_GB]"
      data_transfer_gb: "[ESTIMATED_GB_MONTH]"
      monthly_cost: "[UNIT_COST * DATA_TRANSFER_GB]"
      annual_cost: "[MONTHLY_COST * 12]"
      optimization_potential: "[SAVINGS_PERCENTAGE]"
  
  management_costs:
    - resource: "[RESOURCE_NAME]"
      unit_cost: "[COST_PER_MONTH]"
      monthly_cost: "[UNIT_COST]"
      annual_cost: "[MONTHLY_COST * 12]"
      optimization_potential: "[SAVINGS_PERCENTAGE]"
```

### Cost Aggregation Template
```yaml
cost_summary:
  monthly_costs:
    compute: "[SUM_OF_COMPUTE_COSTS]"
    storage: "[SUM_OF_STORAGE_COSTS]"
    networking: "[SUM_OF_NETWORKING_COSTS]"
    management: "[SUM_OF_MANAGEMENT_COSTS]"
    total_monthly: "[SUM_OF_ALL_MONTHLY_COSTS]"
  
  annual_costs:
    compute: "[SUM_OF_COMPUTE_COSTS * 12]"
    storage: "[SUM_OF_STORAGE_COSTS * 12]"
    networking: "[SUM_OF_NETWORKING_COSTS * 12]"
    management: "[SUM_OF_MANAGEMENT_COSTS * 12]"
    total_annual: "[SUM_OF_ALL_ANNUAL_COSTS]"
  
  cost_per_user:
    monthly: "[TOTAL_MONTHLY / USER_COUNT]"
    annual: "[TOTAL_ANNUAL / USER_COUNT]"
```

## 3. Cloud Provider Specific Templates

### AWS Cost Template
```yaml
aws_cost_template:
  compute:
    ec2:
      pricing_model: "On-Demand/Reserved/Spot"
      instance_types:
        - type: "t3.micro"
          on_demand: "$8.47/month"
          reserved_1yr: "$5.08/month"
          reserved_3yr: "$3.39/month"
          spot: "$2.54/month"
        - type: "t3.small"
          on_demand: "$16.94/month"
          reserved_1yr: "$10.16/month"
          reserved_3yr: "$6.78/month"
          spot: "$5.08/month"
        - type: "t3.medium"
          on_demand: "$33.88/month"
          reserved_1yr: "$20.32/month"
          reserved_3yr: "$13.56/month"
          spot: "$10.16/month"
    
    eks:
      cluster_cost: "$0.10/hour"
      node_cost: "Based on EC2 instance types"
      data_processing: "$0.10 per GB"
  
  storage:
    ebs:
      gp3: "$0.08/GB/month"
      gp2: "$0.10/GB/month"
      io1: "$0.125/GB/month"
      st1: "$0.045/GB/month"
      sc1: "$0.015/GB/month"
    
    s3:
      standard: "$0.023/GB/month"
      ia: "$0.0125/GB/month"
      glacier: "$0.004/GB/month"
      glacier_deep_archive: "$0.00099/GB/month"
  
  networking:
    nat_gateway: "$0.045/hour"
    load_balancer: "$0.0225/hour"
    data_transfer: "$0.09/GB"
    vpc_peering: "$0.01/GB"
  
  management:
    cloudwatch: "$0.30 per metric"
    aws_config: "$0.003 per configuration item"
    cloudtrail: "$2.00 per million events"
```

### Azure Cost Template
```yaml
azure_cost_template:
  compute:
    vm:
      pricing_model: "Pay-as-you-go/Reserved/Spot"
      instance_types:
        - type: "B1s"
          pay_as_you_go: "$8.76/month"
          reserved_1yr: "$5.26/month"
          reserved_3yr: "$3.51/month"
          spot: "$2.63/month"
        - type: "B2s"
          pay_as_you_go: "$17.52/month"
          reserved_1yr: "$10.52/month"
          reserved_3yr: "$7.02/month"
          spot: "$5.26/month"
    
    aks:
      cluster_cost: "$0.10/hour"
      node_cost: "Based on VM instance types"
  
  storage:
    managed_disks:
      p4: "$0.08/GB/month"
      p6: "$0.10/GB/month"
      p10: "$0.125/GB/month"
      p15: "$0.15/GB/month"
    
    blob_storage:
      hot: "$0.0184/GB/month"
      cool: "$0.01/GB/month"
      archive: "$0.00099/GB/month"
  
  networking:
    load_balancer: "$0.025/hour"
    application_gateway: "$0.025/hour"
    data_transfer: "$0.087/GB"
```

### GCP Cost Template
```yaml
gcp_cost_template:
  compute:
    compute_engine:
      pricing_model: "On-demand/Committed use/Spot"
      instance_types:
        - type: "e2-micro"
          on_demand: "$6.28/month"
          committed_1yr: "$3.77/month"
          committed_3yr: "$2.51/month"
          spot: "$1.88/month"
        - type: "e2-small"
          on_demand: "$12.56/month"
          committed_1yr: "$7.54/month"
          committed_3yr: "$5.02/month"
          spot: "$3.77/month"
    
    gke:
      cluster_cost: "$0.10/hour"
      node_cost: "Based on Compute Engine instance types"
  
  storage:
    persistent_disks:
      standard: "$0.04/GB/month"
      ssd: "$0.17/GB/month"
      extreme: "$0.64/GB/month"
    
    cloud_storage:
      standard: "$0.020/GB/month"
      nearline: "$0.010/GB/month"
      coldline: "$0.004/GB/month"
      archive: "$0.0012/GB/month"
  
  networking:
    load_balancer: "$0.025/hour"
    data_transfer: "$0.12/GB"
```

## 4. Cost Optimization Template

### Optimization Strategies Template
```yaml
optimization_strategies:
  compute_optimization:
    - strategy: "Right-sizing"
      potential_savings: "20-40%"
      implementation: "Monitor resource utilization and adjust instance sizes"
      tools: ["CloudWatch", "Azure Monitor", "Stackdriver"]
    
    - strategy: "Reserved Instances"
      potential_savings: "30-60%"
      implementation: "Commit to 1-3 year terms for stable workloads"
      tools: ["AWS Cost Explorer", "Azure Cost Management", "GCP Billing"]
    
    - strategy: "Spot Instances"
      potential_savings: "60-90%"
      implementation: "Use spot instances for fault-tolerant workloads"
      tools: ["AWS Spot Fleet", "Azure Spot VMs", "GCP Preemptible VMs"]
    
    - strategy: "Auto Scaling"
      potential_savings: "20-40%"
      implementation: "Scale down during low usage periods"
      tools: ["AWS Auto Scaling", "Azure VM Scale Sets", "GCP Managed Instance Groups"]
  
  storage_optimization:
    - strategy: "Lifecycle Policies"
      potential_savings: "50-80%"
      implementation: "Move infrequently accessed data to cheaper storage"
      tools: ["S3 Lifecycle", "Azure Blob Lifecycle", "GCP Object Lifecycle"]
    
    - strategy: "Compression"
      potential_savings: "30-50%"
      implementation: "Compress data before storage"
      tools: ["gzip", "bzip2", "lz4"]
    
    - strategy: "Deduplication"
      potential_savings: "20-40%"
      implementation: "Remove duplicate data"
      tools: ["AWS DataSync", "Azure Data Box", "GCP Transfer Service"]
  
  networking_optimization:
    - strategy: "CDN Usage"
      potential_savings: "30-60%"
      implementation: "Use CDN for static content delivery"
      tools: ["CloudFront", "Azure CDN", "Cloud CDN"]
    
    - strategy: "Data Transfer Optimization"
      potential_savings: "20-40%"
      implementation: "Minimize cross-region data transfer"
      tools: ["AWS Direct Connect", "Azure ExpressRoute", "GCP Cloud Interconnect"]
```

## 5. Cost Monitoring Template

### Monitoring Configuration Template
```yaml
cost_monitoring:
  alerts:
    - name: "Budget Threshold Alert"
      condition: "Cost > 80% of budget"
      action: "Email notification"
      frequency: "Daily"
    
    - name: "Cost Anomaly Alert"
      condition: "Cost > 20% above average"
      action: "Slack notification"
      frequency: "Real-time"
    
    - name: "Resource Utilization Alert"
      condition: "CPU/Memory < 20% for 7 days"
      action: "Right-sizing recommendation"
      frequency: "Weekly"
  
  reports:
    - name: "Weekly Cost Report"
      frequency: "Weekly"
      recipients: ["devops@company.com", "finance@company.com"]
      content: ["Cost by service", "Cost by team", "Optimization recommendations"]
    
    - name: "Monthly Cost Analysis"
      frequency: "Monthly"
      recipients: ["management@company.com"]
      content: ["TCO analysis", "ROI calculation", "Budget vs actual"]
    
    - name: "Quarterly Cost Review"
      frequency: "Quarterly"
      recipients: ["executives@company.com"]
      content: ["Strategic cost analysis", "Long-term planning", "Investment decisions"]
```

## 6. Cost Calculation Script Template

### Python Cost Calculator Template
```python
#!/usr/bin/env python3
"""
Universal Cost Calculator for Infrastructure Projects
"""

import yaml
import json
from datetime import datetime
from typing import Dict, List, Any

class CostCalculator:
    def __init__(self, config_file: str):
        """Initialize cost calculator with configuration file"""
        self.config = self.load_config(config_file)
        self.results = {}
    
    def load_config(self, config_file: str) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        with open(config_file, 'r') as file:
            return yaml.safe_load(file)
    
    def calculate_compute_costs(self) -> Dict[str, float]:
        """Calculate compute costs based on configuration"""
        compute_costs = {}
        
        for resource in self.config['architecture_components']['compute']:
            service = resource['service']
            instance_type = resource['instance_type']
            count = resource['count']
            
            # Get pricing from provider template
            pricing = self.get_pricing(service, instance_type)
            
            # Calculate costs
            monthly_cost = pricing['on_demand'] * count
            annual_cost = monthly_cost * 12
            
            compute_costs[service] = {
                'monthly': monthly_cost,
                'annual': annual_cost,
                'optimization_potential': pricing.get('optimization_potential', 0)
            }
        
        return compute_costs
    
    def calculate_storage_costs(self) -> Dict[str, float]:
        """Calculate storage costs based on configuration"""
        storage_costs = {}
        
        for resource in self.config['architecture_components']['storage']:
            service = resource['service']
            size_gb = resource['size_gb']
            
            # Get pricing from provider template
            pricing = self.get_pricing(service, 'standard')
            
            # Calculate costs
            monthly_cost = pricing['per_gb'] * size_gb
            annual_cost = monthly_cost * 12
            
            storage_costs[service] = {
                'monthly': monthly_cost,
                'annual': annual_cost,
                'optimization_potential': pricing.get('optimization_potential', 0)
            }
        
        return storage_costs
    
    def calculate_networking_costs(self) -> Dict[str, float]:
        """Calculate networking costs based on configuration"""
        networking_costs = {}
        
        for resource in self.config['architecture_components']['networking']:
            service = resource['service']
            data_transfer = resource.get('data_transfer', 0)
            
            # Get pricing from provider template
            pricing = self.get_pricing(service, 'standard')
            
            # Calculate costs
            monthly_cost = pricing['base_cost'] + (pricing['per_gb'] * data_transfer)
            annual_cost = monthly_cost * 12
            
            networking_costs[service] = {
                'monthly': monthly_cost,
                'annual': annual_cost,
                'optimization_potential': pricing.get('optimization_potential', 0)
            }
        
        return networking_costs
    
    def get_pricing(self, service: str, instance_type: str) -> Dict[str, float]:
        """Get pricing information from provider template"""
        provider = self.config['project_info']['cloud_provider'].lower()
        
        if provider == 'aws':
            return self.get_aws_pricing(service, instance_type)
        elif provider == 'azure':
            return self.get_azure_pricing(service, instance_type)
        elif provider == 'gcp':
            return self.get_gcp_pricing(service, instance_type)
        else:
            raise ValueError(f"Unsupported cloud provider: {provider}")
    
    def get_aws_pricing(self, service: str, instance_type: str) -> Dict[str, float]:
        """Get AWS pricing information"""
        # AWS pricing data (simplified)
        aws_pricing = {
            'ec2': {
                't3.micro': {'on_demand': 8.47, 'reserved_1yr': 5.08, 'spot': 2.54},
                't3.small': {'on_demand': 16.94, 'reserved_1yr': 10.16, 'spot': 5.08},
                't3.medium': {'on_demand': 33.88, 'reserved_1yr': 20.32, 'spot': 10.16}
            },
            'ebs': {'per_gb': 0.08},
            's3': {'per_gb': 0.023},
            'nat_gateway': {'base_cost': 32.40, 'per_gb': 0.045},
            'load_balancer': {'base_cost': 16.20, 'per_gb': 0.006}
        }
        
        return aws_pricing.get(service, {}).get(instance_type, {'on_demand': 0})
    
    def calculate_total_costs(self) -> Dict[str, Any]:
        """Calculate total project costs"""
        compute_costs = self.calculate_compute_costs()
        storage_costs = self.calculate_storage_costs()
        networking_costs = self.calculate_networking_costs()
        
        # Calculate totals
        total_monthly = sum(cost['monthly'] for cost in compute_costs.values())
        total_monthly += sum(cost['monthly'] for cost in storage_costs.values())
        total_monthly += sum(cost['monthly'] for cost in networking_costs.values())
        
        total_annual = total_monthly * 12
        
        # Calculate cost per user
        user_count = self.config['project_info']['expected_users']
        cost_per_user_monthly = total_monthly / user_count if user_count > 0 else 0
        cost_per_user_annual = total_annual / user_count if user_count > 0 else 0
        
        return {
            'compute_costs': compute_costs,
            'storage_costs': storage_costs,
            'networking_costs': networking_costs,
            'total_monthly': total_monthly,
            'total_annual': total_annual,
            'cost_per_user_monthly': cost_per_user_monthly,
            'cost_per_user_annual': cost_per_user_annual
        }
    
    def generate_report(self) -> str:
        """Generate cost analysis report"""
        costs = self.calculate_total_costs()
        
        report = f"""
# Cost Analysis Report for {self.config['project_info']['name']}

## Project Information
- **Project**: {self.config['project_info']['name']}
- **Cloud Provider**: {self.config['project_info']['cloud_provider']}
- **Environment**: {self.config['project_info']['environment']}
- **Duration**: {self.config['project_info']['duration_months']} months
- **Expected Users**: {self.config['project_info']['expected_users']}

## Cost Breakdown

### Compute Costs
"""
        
        for service, cost in costs['compute_costs'].items():
            report += f"- **{service}**: ${cost['monthly']:.2f}/month (${cost['annual']:.2f}/year)\n"
        
        report += f"""
### Storage Costs
"""
        
        for service, cost in costs['storage_costs'].items():
            report += f"- **{service}**: ${cost['monthly']:.2f}/month (${cost['annual']:.2f}/year)\n"
        
        report += f"""
### Networking Costs
"""
        
        for service, cost in costs['networking_costs'].items():
            report += f"- **{service}**: ${cost['monthly']:.2f}/month (${cost['annual']:.2f}/year)\n"
        
        report += f"""
## Total Costs
- **Monthly Total**: ${costs['total_monthly']:.2f}
- **Annual Total**: ${costs['total_annual']:.2f}
- **Cost per User (Monthly)**: ${costs['cost_per_user_monthly']:.2f}
- **Cost per User (Annual)**: ${costs['cost_per_user_annual']:.2f}

## Optimization Recommendations
- Consider Reserved Instances for stable workloads (30-60% savings)
- Use Spot Instances for fault-tolerant workloads (60-90% savings)
- Implement auto-scaling to reduce costs during low usage (20-40% savings)
- Apply storage lifecycle policies (50-80% savings)

Generated on: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
"""
        
        return report

def main():
    """Main function to run cost calculation"""
    calculator = CostCalculator('project_config.yaml')
    report = calculator.generate_report()
    
    # Save report to file
    with open('cost_analysis_report.md', 'w') as file:
        file.write(report)
    
    print("Cost analysis report generated: cost_analysis_report.md")

if __name__ == "__main__":
    main()
```

## 7. Usage Instructions

### How to Use This Template

1. **Configure Project Information**: Fill in the project details in the template
2. **Define Architecture Components**: List all resources needed for the project
3. **Select Cloud Provider**: Choose the appropriate pricing template
4. **Run Cost Calculation**: Use the provided script or manual calculation
5. **Review and Optimize**: Analyze costs and identify optimization opportunities
6. **Monitor and Adjust**: Set up monitoring and adjust costs as needed

### Customization Guidelines

1. **Project-Specific Requirements**: Modify templates for specific project needs
2. **Regional Pricing**: Adjust pricing for different regions
3. **Compliance Requirements**: Add compliance-related costs
4. **Team Constraints**: Consider team size and expertise in cost planning

This template provides a comprehensive framework for cost calculation that can be applied to any infrastructure project, ensuring accurate cost estimation and effective cost management. 