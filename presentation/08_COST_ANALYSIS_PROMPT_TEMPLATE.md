# AI Prompt Template for Cost Analysis in Infrastructure Projects

## Overview
This template provides structured AI prompts for cost analysis and calculation in infrastructure projects. It can be used with any AI tool to generate accurate cost estimates and optimization recommendations.

## Level 1: Basic Cost Analysis Prompt

### Initial Cost Assessment Prompt
```
You are a senior cloud cost analyst tasked with providing cost analysis for an infrastructure project.

PROJECT CONTEXT:
- Project Name: [PROJECT_NAME]
- Cloud Provider: [AWS/AZURE/GCP]
- Region: [REGION]
- Environment: [dev/staging/prod]
- Expected Duration: [DURATION_MONTHS] months
- Expected Users: [USER_COUNT]
- Team Size: [TEAM_SIZE]

INFRASTRUCTURE REQUIREMENTS:
[LIST_ALL_INFRASTRUCTURE_COMPONENTS]

COST ANALYSIS REQUIREMENTS:
1. Calculate monthly and annual costs for all infrastructure components
2. Provide cost breakdown by service category (compute, storage, networking, management)
3. Calculate cost per user metrics
4. Identify potential cost optimization opportunities
5. Compare with industry benchmarks
6. Provide TCO (Total Cost of Ownership) analysis

CONSTRAINTS:
- Use current pricing for [CLOUD_PROVIDER] in [REGION]
- Consider on-demand pricing for initial estimates
- Include all operational costs (monitoring, backup, security)
- Account for data transfer costs
- Consider compliance and security requirements

Please provide a comprehensive cost analysis with detailed breakdowns and optimization recommendations.
```

### Expected Output Structure
```
# Cost Analysis Report

## Project Overview
- Project: [PROJECT_NAME]
- Cloud Provider: [CLOUD_PROVIDER]
- Region: [REGION]
- Duration: [DURATION] months

## Cost Breakdown
### Compute Costs
- [SERVICE_1]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)
- [SERVICE_2]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)

### Storage Costs
- [SERVICE_1]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)
- [SERVICE_2]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)

### Networking Costs
- [SERVICE_1]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)
- [SERVICE_2]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)

### Management Costs
- [SERVICE_1]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)
- [SERVICE_2]: $[MONTHLY_COST]/month ($[ANNUAL_COST]/year)

## Total Costs
- Monthly Total: $[TOTAL_MONTHLY]
- Annual Total: $[TOTAL_ANNUAL]
- Cost per User (Monthly): $[COST_PER_USER_MONTHLY]
- Cost per User (Annual): $[COST_PER_USER_ANNUAL]

## Optimization Recommendations
- [OPTIMIZATION_1]: Potential savings of [PERCENTAGE]
- [OPTIMIZATION_2]: Potential savings of [PERCENTAGE]
- [OPTIMIZATION_3]: Potential savings of [PERCENTAGE]

## Industry Benchmarks
- [BENCHMARK_1]: [COMPARISON]
- [BENCHMARK_2]: [COMPARISON]
- [BENCHMARK_3]: [COMPARISON]
```

## Level 2: Detailed Cost Analysis Prompt

### Advanced Cost Modeling Prompt
```
Based on the initial cost analysis, provide a detailed cost modeling for the infrastructure project.

DETAILED REQUIREMENTS:
1. **Pricing Model Analysis**:
   - Compare on-demand vs reserved instance pricing
   - Analyze spot instance opportunities
   - Calculate savings from different pricing models

2. **Usage Pattern Analysis**:
   - Estimate peak vs off-peak usage
   - Calculate auto-scaling cost implications
   - Analyze seasonal variations

3. **Optimization Strategy**:
   - Right-sizing recommendations
   - Reserved instance planning
   - Spot instance implementation strategy
   - Storage lifecycle optimization

4. **Risk Assessment**:
   - Cost overrun risks
   - Performance vs cost trade-offs
   - Scalability cost implications

5. **ROI Analysis**:
   - Calculate return on investment
   - Compare with on-premises alternatives
   - Analyze time-to-market benefits

Please provide detailed calculations, scenarios, and recommendations for each requirement.
```

### Cost Optimization Prompt
```
Provide comprehensive cost optimization strategies for the infrastructure project.

OPTIMIZATION AREAS:
1. **Compute Optimization**:
   - Instance right-sizing recommendations
   - Reserved instance planning (1-year vs 3-year terms)
   - Spot instance implementation for fault-tolerant workloads
   - Auto-scaling policies and cost implications

2. **Storage Optimization**:
   - Storage class selection (Standard vs IA vs Glacier)
   - Lifecycle policy recommendations
   - Data compression strategies
   - Backup and retention optimization

3. **Networking Optimization**:
   - Data transfer cost reduction
   - CDN implementation for static content
   - Load balancer optimization
   - VPC peering cost analysis

4. **Management Optimization**:
   - Monitoring and alerting cost optimization
   - Log retention policy optimization
   - Security service cost analysis
   - Compliance cost optimization

5. **Operational Optimization**:
   - Resource scheduling (start/stop non-production resources)
   - Tagging strategy for cost allocation
   - Budget alerts and cost governance
   - Regular cost review processes

Please provide specific recommendations with potential savings percentages and implementation steps.
```

## Level 3: Cloud Provider Specific Prompts

### AWS Cost Analysis Prompt
```
Provide detailed AWS cost analysis for the infrastructure project.

AWS-SPECIFIC REQUIREMENTS:
1. **EC2 Cost Analysis**:
   - Compare t3, t2, m5, c5 instance types
   - Analyze on-demand vs reserved instance pricing
   - Calculate spot instance savings potential
   - Consider savings plans vs reserved instances

2. **EKS Cost Analysis**:
   - Cluster management costs
   - Node group pricing
   - Data processing costs
   - Load balancer costs

3. **Storage Cost Analysis**:
   - EBS volume pricing (gp3 vs gp2 vs io1)
   - S3 storage class selection
   - Data transfer costs
   - Backup storage costs

4. **Networking Cost Analysis**:
   - NAT Gateway costs
   - Load Balancer costs
   - Data transfer pricing
   - VPC peering costs

5. **Management Services**:
   - CloudWatch costs
   - AWS Config costs
   - CloudTrail costs
   - AWS Systems Manager costs

Please provide AWS-specific pricing and optimization recommendations.
```

### Azure Cost Analysis Prompt
```
Provide detailed Azure cost analysis for the infrastructure project.

AZURE-SPECIFIC REQUIREMENTS:
1. **VM Cost Analysis**:
   - Compare B-series, D-series, E-series VMs
   - Analyze pay-as-you-go vs reserved instance pricing
   - Calculate spot VM savings potential
   - Consider Azure Hybrid Benefit

2. **AKS Cost Analysis**:
   - Cluster management costs
   - Node pool pricing
   - Load balancer costs
   - Container registry costs

3. **Storage Cost Analysis**:
   - Managed disk pricing (P4, P6, P10, P15)
   - Blob storage class selection
   - Data transfer costs
   - Backup storage costs

4. **Networking Cost Analysis**:
   - Load balancer costs
   - Application Gateway costs
   - Data transfer pricing
   - VNet peering costs

5. **Management Services**:
   - Azure Monitor costs
   - Azure Policy costs
   - Log Analytics costs
   - Azure Security Center costs

Please provide Azure-specific pricing and optimization recommendations.
```

### GCP Cost Analysis Prompt
```
Provide detailed GCP cost analysis for the infrastructure project.

GCP-SPECIFIC REQUIREMENTS:
1. **Compute Engine Cost Analysis**:
   - Compare e2, n2, c2 instance types
   - Analyze on-demand vs committed use pricing
   - Calculate preemptible VM savings potential
   - Consider sustained use discounts

2. **GKE Cost Analysis**:
   - Cluster management costs
   - Node pool pricing
   - Load balancer costs
   - Container registry costs

3. **Storage Cost Analysis**:
   - Persistent disk pricing (standard vs SSD vs extreme)
   - Cloud Storage class selection
   - Data transfer costs
   - Backup storage costs

4. **Networking Cost Analysis**:
   - Load balancer costs
   - Cloud CDN costs
   - Data transfer pricing
   - VPC peering costs

5. **Management Services**:
   - Stackdriver costs
   - Cloud Logging costs
   - Cloud Monitoring costs
   - Security Command Center costs

Please provide GCP-specific pricing and optimization recommendations.
```

## Level 4: Advanced Cost Analysis Prompts

### TCO Analysis Prompt
```
Provide a comprehensive Total Cost of Ownership (TCO) analysis for the infrastructure project.

TCO ANALYSIS REQUIREMENTS:
1. **Direct Costs**:
   - Infrastructure costs (compute, storage, networking)
   - Management and monitoring costs
   - Security and compliance costs
   - Data transfer and bandwidth costs

2. **Indirect Costs**:
   - Management overhead
   - Training and certification costs
   - Compliance and governance costs
   - Support and maintenance costs

3. **Operational Costs**:
   - Backup and disaster recovery costs
   - Monitoring and alerting costs
   - Security scanning and compliance costs
   - Performance optimization costs

4. **Opportunity Costs**:
   - Time to market delays
   - Resource allocation decisions
   - Technology lock-in risks
   - Innovation opportunity costs

5. **Comparison Analysis**:
   - Compare with on-premises alternatives
   - Compare with other cloud providers
   - Analyze hybrid cloud scenarios
   - Consider multi-cloud strategies

Please provide detailed TCO calculations and comparisons.
```

### ROI Analysis Prompt
```
Provide a comprehensive Return on Investment (ROI) analysis for the infrastructure project.

ROI ANALYSIS REQUIREMENTS:
1. **Investment Calculation**:
   - Infrastructure investment costs
   - Migration and setup costs
   - Training and certification costs
   - Ongoing operational costs

2. **Benefits Calculation**:
   - Cost savings from cloud migration
   - Improved performance and reliability benefits
   - Reduced operational overhead
   - Enhanced security and compliance benefits
   - Time to market improvements

3. **ROI Metrics**:
   - Calculate ROI percentage
   - Determine payback period
   - Analyze net present value (NPV)
   - Calculate internal rate of return (IRR)

4. **Risk Analysis**:
   - Identify investment risks
   - Analyze cost overrun scenarios
   - Consider performance risks
   - Evaluate security and compliance risks

5. **Sensitivity Analysis**:
   - Analyze impact of cost variations
   - Consider usage pattern changes
   - Evaluate technology changes
   - Assess market condition impacts

Please provide detailed ROI calculations and risk assessments.
```

## Level 5: Specialized Cost Analysis Prompts

### Compliance Cost Analysis Prompt
```
Provide detailed cost analysis for compliance requirements in the infrastructure project.

COMPLIANCE COST ANALYSIS:
1. **Security Compliance**:
   - SOC 2 Type II compliance costs
   - ISO 27001 compliance costs
   - PCI DSS compliance costs
   - HIPAA compliance costs

2. **Data Protection**:
   - Encryption costs (at rest and in transit)
   - Key management costs
   - Data backup and retention costs
   - Audit logging costs

3. **Monitoring and Reporting**:
   - Compliance monitoring tools
   - Audit trail costs
   - Reporting and documentation costs
   - Third-party audit costs

4. **Operational Compliance**:
   - Access control costs
   - Identity management costs
   - Security scanning costs
   - Incident response costs

Please provide detailed compliance cost breakdowns and recommendations.
```

### Performance vs Cost Optimization Prompt
```
Provide analysis of performance vs cost trade-offs for the infrastructure project.

PERFORMANCE-COST ANALYSIS:
1. **Compute Performance**:
   - CPU vs cost optimization
   - Memory vs cost optimization
   - Storage performance vs cost
   - Network performance vs cost

2. **Scalability Analysis**:
   - Auto-scaling cost implications
   - Load balancing cost optimization
   - Database scaling costs
   - Application scaling costs

3. **Availability vs Cost**:
   - Multi-AZ deployment costs
   - Disaster recovery costs
   - Backup and restore costs
   - High availability vs cost trade-offs

4. **Performance Monitoring**:
   - Monitoring tool costs
   - Performance optimization costs
   - Capacity planning costs
   - Performance testing costs

Please provide detailed performance-cost analysis and recommendations.
```

## Usage Guidelines

### How to Use These Prompts

1. **Start with Level 1**: Use the basic cost analysis prompt for initial estimates
2. **Progress to Level 2**: Use detailed prompts for comprehensive analysis
3. **Select Provider**: Use cloud provider-specific prompts for accurate pricing
4. **Add Specialization**: Use specialized prompts for compliance, performance, etc.
5. **Iterate and Refine**: Use multiple prompts to get comprehensive analysis

### Customization Tips

1. **Project-Specific**: Modify prompts with project-specific requirements
2. **Regional Pricing**: Adjust for different regions and pricing
3. **Compliance Needs**: Add compliance-specific requirements
4. **Team Expertise**: Consider team capabilities in cost management
5. **Business Constraints**: Include business-specific constraints and requirements

### Quality Assurance

1. **Verify Pricing**: Cross-reference with official pricing pages
2. **Validate Assumptions**: Review and validate all cost assumptions
3. **Test Scenarios**: Run multiple scenarios for different usage patterns
4. **Peer Review**: Have cost analysis reviewed by team members
5. **Document Decisions**: Document all cost-related decisions and rationale

This template provides a comprehensive framework for using AI tools to perform cost analysis in infrastructure projects, ensuring accurate cost estimation and effective cost management. 