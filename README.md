
# DevOps Take-Home Assignment

## Overview

This repository contains a containerized application deployment and Kubernetes troubleshooting exercise. It demonstrates application packaging, Helm-based deployment, Kubernetes configuration, deployment automation, and systematic troubleshooting of application and infrastructure issues.

The solution is organized into two main areas:

1. **Application deployment:** Containerized service, Helm chart, and setup automation.
2. **Kubernetes debugging lab:** Investigation of a deliberately broken Helm deployment, analysis of Kubernetes errors, and documented verification results.

## Technology Stack

- Docker — application containerization
- Kubernetes — container orchestration
- kind — local Kubernetes cluster
- Helm — Kubernetes application packaging and deployment
- kubectl — Kubernetes resource management and troubleshooting
- Bash — setup and validation automation
- Git — source control

## Repository Structure

The following is a logical overview. The exact paths should match the files present in this repository.

```text
eb-devops-takehome/
├── service/                 # Application source and Dockerfile
├── chart/                   # Helm chart for application deployment
├── setup.sh                 # Environment/setup automation
├── lab/
│   ├── broken-chart/        # Helm chart used in the debugging exercise
│   ├── FINDINGS.md          # Investigation findings and evidence
│   ├── part4-session.log    # Debugging session record
│   ├── scenario.sh          # Supplied lab setup and verification script
│   └── cluster-state/       # Supplied Kubernetes lab configuration
├── ANSWERS.md               # Gateway API migration responses
└── README.md                # Project documentation
```

Some paths may differ depending on the supplied assignment structure. Refer to the actual repository files when running commands.

## Prerequisites

Install or configure the following tools locally:

- Docker Desktop with the required container-runtime integration
- kubectl
- Helm
- kind
- Git
- Bash-compatible terminal

No cloud account or paid infrastructure is required for the local Kubernetes workflow.

Check tool availability:

```bash
docker --version
kubectl version --client
helm version --short
kind version
git --version
```

## Application Deployment

The application deployment portion uses a container image and a Helm chart to manage Kubernetes resources.

The chart should define the application workload and its supporting resources, including the Deployment, Service, health probes, resource requests and limits, and Ingress configuration where required by the assignment.

### Validate the Helm chart

From the repository root, run:

```bash
helm lint chart
```

This checks the chart for common structural and configuration problems.

Render the Kubernetes manifests without deploying them:

```bash
helm template submission chart
```

Review the rendered resources before installing or upgrading the release.

### Run the setup automation

Inspect the setup script before executing it:

```bash
cat setup.sh
bash -n setup.sh
```

`bash -n` checks shell syntax without executing the script.

If the script matches the supplied assignment workflow, run:

```bash
chmod +x setup.sh
./setup.sh
```

Follow the script output and any prerequisites documented in the assignment.

### Inspect the deployment

Use the namespace and release name configured by the setup process.

For example, if the application is deployed to the `demo` namespace:

```bash
kubectl get deployments -n demo
kubectl get pods -n demo -o wide
kubectl get services -n demo
kubectl get ingress -n demo
```

Inspect rollout status:

```bash
kubectl rollout status deployment/demo -n demo
```

These commands report deployment readiness, pod placement, Service configuration, Ingress resources, and rollout progress.

## Kubernetes Debugging Lab

The debugging exercise is located in `lab/`. It uses a deliberately broken Helm chart and a supplied scenario script to help identify configuration and application issues.

### Start the lab

```bash
cd lab
./scenario.sh up
```

The initial setup may report errors because the lab is intentionally broken. Record the errors and investigate the affected resources instead of treating every initial failure as an environment problem.

### Inspect Kubernetes resources

```bash
kubectl get all -n debug-lab
kubectl get pods -n debug-lab -o wide
kubectl get events -n debug-lab --sort-by=.lastTimestamp
kubectl get jobs -n debug-lab
helm status debug-lab -n debug-lab
```

For a specific pod, inspect its events and configuration:

```bash
kubectl describe pod <pod-name> -n debug-lab
```

For application logs:

```bash
kubectl logs deployment/reporter -n debug-lab
```

Use the appropriate Deployment name when investigating other workloads.

### Verify the lab

From the `lab/` directory:

```bash
./scenario.sh verify
```

The verification script checks the required goal state, including the migration Job, application readiness, reporter permissions, backend health, gateway status, and reporter output.

Record the actual final output in `lab/part4-session.log`. Do not report the lab as fully passing unless the verification confirms it.

### Findings and troubleshooting approach

The investigation covered the following observed areas:

- Migration Job specification validation
- Kubernetes namespace and resource-application ordering
- Container security-context compatibility
- Gateway-to-backend Service addressing
- Reporter ServiceAccount and RBAC permissions
- Reporter readiness and Kubernetes PodList parsing

Detailed observations, commands, and the unresolved reporter issue are documented in `lab/FINDINGS.md`.

The initial lab verification did not pass all checks. Although later testing confirmed that the reporter ServiceAccount could query the Kubernetes API through an independent diagnostic pod, the reporter application's own PodList parsing and readiness behavior remained unresolved in the last confirmed investigation.

## Gateway API Migration

`ANSWERS.md` contains the responses for the Gateway API migration section of the assignment.

It should be reviewed against the exact questions in the assignment document to ensure that every requested topic is answered directly, including migration considerations, routing, TLS, validation, and operational risks where applicable.

## Engineering Considerations

The implementation and troubleshooting process emphasizes:

- Declarative infrastructure and repeatable deployments
- Helm manifest validation before deployment
- Health checks and rollout monitoring
- Kubernetes events and logs for root-cause investigation
- Namespace-aware service discovery
- Least-privilege ServiceAccount permissions
- Resource requests and limits
- Honest reporting of test results and known limitations

## Further Production Improvements

For a production environment, additional improvements could include:

- Automated CI checks for Helm linting and manifest rendering
- Integration tests for application health and service-to-service communication
- Automated deployment rollback and release validation
- Centralized logging, metrics, alerting, and dashboards
- External secret management and stronger credential-handling practices
- Image vulnerability scanning and image provenance verification
- Network policies and a review of workload security contexts
- Documented recovery procedures and deployment runbooks

These are proposed improvements, not claims that every capability is implemented in this repository.

## AI Assistance Disclosure

AI assistance was used to help organize documentation and explain troubleshooting concepts. Commands were run in the local environment, and documented findings were based on observed command output and investigation results. Any unresolved behavior is identified explicitly rather than represented as a successful test.

