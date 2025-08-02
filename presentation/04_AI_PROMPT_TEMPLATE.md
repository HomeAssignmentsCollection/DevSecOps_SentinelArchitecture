# AI Prompt Template for Infrastructure Projects

## Overview
This document provides a structured approach to using AI tools for infrastructure project development, based on reverse engineering the Rapyd Sentinel project. The template includes multiple levels of prompts for iterative development.

## Level 1: Project Foundation Prompt

### Initial Project Setup Prompt
```
You are a senior DevOps engineer tasked with creating a comprehensive infrastructure project. 

PROJECT CONTEXT:
- Project Name: [PROJECT_NAME]
- Cloud Provider: AWS
- Infrastructure Tool: Terraform
- Container Orchestration: Amazon EKS
- CI/CD: GitHub Actions
- Security Requirements: Production-ready with compliance standards

REQUIREMENTS:
1. Create a modular Terraform infrastructure with the following components:
   - Two isolated VPCs (public-facing and private)
   - EKS clusters in each VPC
   - VPC peering for secure cross-VPC communication
   - Security groups with minimal access
   - Load balancers and networking components

2. Implement Kubernetes manifests for:
   - Backend service (private, internal)
   - Gateway proxy service (public-facing)
   - Network policies for pod isolation
   - Service configurations

3. Set up CI/CD pipeline with:
   - GitHub Actions workflows
   - Security scanning (Checkov, TFLint)
   - Automated testing and validation
   - OIDC federation for AWS access

4. Include comprehensive documentation:
   - README with setup instructions
   - Architecture diagrams
   - Security documentation
   - Best practices guide

CONSTRAINTS:
- Follow Infrastructure as Code best practices
- Implement security-first design
- Ensure modularity and reusability
- Include proper error handling
- Add comprehensive testing

Please create the complete project structure with all necessary files and configurations.
```

### Expected Output Structure
```
project-name/
├── infrastructure/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── backend.tf
├── modules/
│   ├── vpc/
│   ├── eks/
│   ├── networking/
│   └── security/
├── k8s-manifests/
│   ├── gateway/
│   └── backend/
├── scripts/
├── .github/workflows/
├── docs/
└── README.md
```

## Level 2: Detailed Component Prompts

### VPC Module Prompt
```
Based on the project foundation, create a detailed Terraform VPC module with the following specifications:

MODULE REQUIREMENTS:
- Create VPC with configurable CIDR block
- Create 2 private subnets in different availability zones
- Create route tables with internet gateway
- Implement security groups with minimal required access
- Add proper tagging strategy
- Include outputs for VPC ID, subnet IDs, and security group IDs

SECURITY REQUIREMENTS:
- Private subnets for sensitive workloads
- Security groups with least privilege access
- No public EC2 instances
- Proper network ACLs

Please provide the complete module with main.tf, variables.tf, and outputs.tf files.
```

### EKS Module Prompt
```
Create a Terraform EKS module for the project with the following specifications:

MODULE REQUIREMENTS:
- EKS cluster with configurable node groups
- IAM roles and policies for EKS
- Security groups for cluster communication
- Auto-scaling configuration
- Proper tagging and labeling

SECURITY REQUIREMENTS:
- OIDC provider for service accounts
- RBAC configuration
- Network policies
- Pod security policies

PERFORMANCE REQUIREMENTS:
- Multi-AZ deployment
- Auto-scaling groups
- Spot instance support for cost optimization
- Resource quotas and limits

Please provide the complete module with all necessary configurations.
```

### CI/CD Pipeline Prompt
```
Create GitHub Actions workflows for the infrastructure project with the following requirements:

WORKFLOW REQUIREMENTS:
1. Terraform Validation Workflow:
   - Trigger on PR to main branch
   - Path-based triggers for infrastructure changes
   - Terraform fmt, validate, and plan
   - Security scanning with Checkov and TFLint
   - Comment results on PR

2. Infrastructure Deployment Workflow:
   - Trigger on push to main branch
   - OIDC federation for AWS access
   - Terraform apply with rollback capability
   - Infrastructure validation
   - Output capture and storage

3. Kubernetes Deployment Workflow:
   - Trigger after successful infrastructure deployment
   - Manifest validation with kubeval
   - Security scanning with kubesec
   - Deployment to EKS clusters
   - Health checks and connectivity testing

SECURITY REQUIREMENTS:
- No hardcoded credentials
- OIDC federation for AWS access
- Security scanning in all workflows
- Audit logging and trail

Please provide the complete workflow configurations.
```

## Level 3: Security and Best Practices Prompts

### Security Implementation Prompt
```
Implement comprehensive security measures for the infrastructure project:

SECURITY LAYERS:
1. Network Security:
   - VPC isolation and segmentation
   - Security groups with minimal rules
   - Network ACLs
   - VPC peering with proper routing

2. Container Security:
   - Kubernetes NetworkPolicy
   - Pod security policies
   - RBAC configuration
   - Service account management

3. Infrastructure Security:
   - IAM roles with least privilege
   - OIDC federation
   - Encryption at rest and in transit
   - Audit logging

4. CI/CD Security:
   - Security scanning in pipelines
   - Secret management
   - Code signing
   - Vulnerability assessment

Please provide the security configurations and best practices implementation.
```

### Best Practices Implementation Prompt
```
Implement industry best practices for the infrastructure project:

BEST PRACTICES AREAS:
1. Infrastructure as Code:
   - Modular design with reusable components
   - Consistent naming conventions
   - Proper state management
   - Version control and tagging

2. Monitoring and Observability:
   - Logging strategy
   - Metrics collection
   - Alerting configuration
   - Health checks

3. Cost Optimization:
   - Resource right-sizing
   - Spot instance usage
   - Auto-scaling policies
   - Tagging for cost allocation

4. Disaster Recovery:
   - Backup strategies
   - Multi-region deployment
   - Recovery procedures
   - Business continuity planning

Please provide the best practices implementation with examples and configurations.
```

## Level 4: Testing and Validation Prompts

### Testing Strategy Prompt
```
Create a comprehensive testing strategy for the infrastructure project:

TESTING REQUIREMENTS:
1. Infrastructure Testing:
   - Terratest for Terraform modules
   - Unit tests for individual components
   - Integration tests for complete infrastructure
   - Performance testing

2. Security Testing:
   - Static analysis (Checkov, TFLint)
   - Dynamic testing (penetration testing)
   - Compliance scanning
   - Vulnerability assessment

3. Application Testing:
   - Kubernetes manifest validation
   - Container image scanning
   - End-to-end testing
   - Load testing

4. CI/CD Testing:
   - Pipeline validation
   - Deployment testing
   - Rollback testing
   - Monitoring validation

Please provide the complete testing strategy with scripts and configurations.
```

### Validation and Quality Assurance Prompt
```
Implement quality assurance measures for the infrastructure project:

QUALITY REQUIREMENTS:
1. Code Quality:
   - Static analysis tools
   - Code formatting standards
   - Documentation requirements
   - Review processes

2. Security Quality:
   - Security scanning integration
   - Compliance checking
   - Policy enforcement
   - Audit trail maintenance

3. Performance Quality:
   - Resource optimization
   - Performance monitoring
   - Capacity planning
   - Scalability testing

4. Operational Quality:
   - Monitoring and alerting
   - Incident response procedures
   - Change management
   - Documentation standards

Please provide the quality assurance implementation with tools and processes.
```

## Level 5: Advanced Features and Optimization Prompts

### Advanced Features Prompt
```
Implement advanced features for production readiness:

ADVANCED FEATURES:
1. Service Mesh:
   - Istio implementation
   - Traffic management
   - Security policies
   - Observability integration

2. GitOps:
   - ArgoCD deployment
   - Git-based workflow
   - Automated synchronization
   - Rollback capabilities

3. Secrets Management:
   - HashiCorp Vault integration
   - Kubernetes secrets management
   - Rotation policies
   - Access control

4. Advanced Monitoring:
   - Prometheus and Grafana
   - Distributed tracing
   - Custom metrics
   - Alerting rules

Please provide the advanced features implementation with configurations and examples.
```

### Performance Optimization Prompt
```
Optimize the infrastructure for performance and scalability:

OPTIMIZATION AREAS:
1. Network Optimization:
   - Load balancer configuration
   - Connection pooling
   - CDN integration
   - Network policies

2. Resource Optimization:
   - Instance right-sizing
   - Auto-scaling policies
   - Resource quotas
   - Cost optimization

3. Application Optimization:
   - Container optimization
   - Image caching
   - Resource limits
   - Performance tuning

4. Database Optimization:
   - Connection pooling
   - Read replicas
   - Backup strategies
   - Performance monitoring

Please provide the optimization strategies with configurations and examples.
```

## Template Usage Guide

### Step-by-Step Process

1. **Start with Level 1**: Use the foundation prompt to create the basic project structure
2. **Iterate with Level 2**: Add detailed components one by one
3. **Enhance with Level 3**: Implement security and best practices
4. **Validate with Level 4**: Add comprehensive testing
5. **Optimize with Level 5**: Add advanced features as needed

### Customization Guidelines

1. **Project-Specific Requirements**: Modify prompts to include project-specific requirements
2. **Technology Stack**: Adjust for different cloud providers or tools
3. **Compliance Requirements**: Add industry-specific compliance needs
4. **Team Constraints**: Consider team size and expertise level

### Quality Assurance

1. **Review Generated Code**: Always review and validate AI-generated code
2. **Test Implementations**: Run comprehensive tests on all components
3. **Security Validation**: Ensure security measures are properly implemented
4. **Documentation**: Maintain comprehensive documentation

## Example Usage

### Project Initialization
```bash
# Use Level 1 prompt to create project foundation
# Review and validate the generated structure
# Customize for specific requirements
```

### Component Development
```bash
# Use Level 2 prompts for each component
# Test each component individually
# Integrate components together
```

### Security Implementation
```bash
# Use Level 3 security prompt
# Validate security measures
# Test security configurations
```

### Final Validation
```bash
# Use Level 4 testing prompt
# Run comprehensive tests
# Validate all components
```

## Best Practices for AI Prompt Usage

1. **Be Specific**: Include detailed requirements and constraints
2. **Iterate Gradually**: Build complexity step by step
3. **Validate Output**: Always review and test generated code
4. **Maintain Context**: Keep track of previous prompts and decisions
5. **Document Decisions**: Record important architectural decisions
6. **Security First**: Always prioritize security in prompts
7. **Test Everything**: Include testing requirements in all prompts

This template provides a structured approach to using AI tools for infrastructure development while maintaining quality, security, and best practices. 