
# Findings — Part 4 debug lab

## Defect 1

**Symptom** (what you observed — paste the real command output):

The initial Helm installation failed while creating the migration Job.

Actual error observed:

```text
Job.batch "migrate" is invalid:
spec.template.spec.restartPolicy: Required value:
valid values: "OnFailure", "Never"
```

**Cause** (the actual root cause, not the symptom restated):

The migration Job used an invalid `restartPolicy`. Kubernetes Jobs support `OnFailure` or `Never`; `Always` is not valid for a Job.

**Fix** (what you changed, and why this over alternatives):

The required correction is to set the migration Job's pod template to `restartPolicy: Never` or `restartPolicy: OnFailure`. This complies with Kubernetes Job requirements. Confirm the final value in the chart before recording this as fixed.

**How I found it** (the sequence of commands/reasoning that led you here):

I ran the supplied lab setup command:

```bash
./scenario.sh up
```

Helm reported that the `migrate` Job was invalid because its restart policy was not allowed. I used the error to identify the affected resource and the field that needed investigation.

---

## Defect 2

**Symptom:**

The setup initially reported that it could not create the LimitRange because the `debug-lab` namespace did not exist.

Actual error observed:

```text
Error from server (NotFound):
error when creating "cluster-state/limits.yaml":
namespaces "debug-lab" not found
```

**Cause:**

The LimitRange creation was attempted when the namespace was not available to that operation. The available output does not establish whether this was caused by setup ordering, the state of the cluster, or another environmental condition.

**Fix:**

The later setup output showed the LimitRange being created successfully and the namespace remaining present. I would verify the namespace and LimitRange after setup before deciding whether a code change is necessary. I would not modify the supplied `scenario.sh` or `cluster-state/` files if the assignment requires them to remain unchanged.

**How I found it:**

I inspected the output of `./scenario.sh up` and identified the namespace-related error. I then checked the namespace and LimitRange using:

```bash
kubectl get namespace debug-lab
kubectl get limitrange -n debug-lab
```

The later output showed the LimitRange being created.

---

## Defect 3

**Symptom:**

Several application pods failed to start and entered `CreateContainerConfigError`.

Actual Kubernetes event observed:

```text
Error: container has runAsNonRoot and image has non-numeric user (nonroot),
cannot verify user is non-root
```

The event was reported for application workloads including the backend, gateway, metrics, reporter, and worker.

**Cause:**

The pod security context requested `runAsNonRoot: true`, but the container image declared a username rather than a numeric user ID. Kubernetes could not verify the non-root identity from that image configuration.

**Fix:**

The configuration needs to use a numeric non-root UID compatible with the image, if the image and assignment constraints permit it. For example:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65532
```

The UID must be validated against the actual image and its filesystem permissions. This example should not be recorded as the applied fix unless that is what was actually changed.

**How I found it:**

I inspected pod status and Kubernetes events:

```bash
kubectl get pods -n debug-lab
kubectl describe pod -n debug-lab
kubectl get events -n debug-lab --sort-by=.lastTimestamp
```

The events showed that Kubernetes was rejecting container startup because it could not verify the image's non-root user.

---

## Defect 4

**Symptom:**

The gateway did not report the backend as healthy during lab verification.

The initial gateway configuration referenced:

```text
http://backend.default.svc:8080
```

The backend Service was deployed in the `debug-lab` namespace.

**Cause:**

The gateway's initial backend URL referenced the `default` namespace instead of `debug-lab`. Kubernetes Service DNS names must point to the namespace where the target Service exists.

**Fix:**

The gateway URL should reference the backend Service in the correct namespace, for example:

```text
http://backend.debug-lab.svc.cluster.local:8080
```

The final configured value should be checked against the chart and recorded as the fix only if it was actually applied.

**How I found it:**

I inspected the gateway configuration and the available Services:

```bash
kubectl describe deployment gateway -n debug-lab
kubectl get services -n debug-lab
```

I compared the namespace in the configured backend URL with the namespace containing the backend Service.

---

## Defect 5

**Symptom:**

The lab verification initially reported:

```text
FAIL ServiceAccount debug-lab/reporter cannot list pods
```

The initial authorization check returned:

```text
no
```

**Cause:**

The reporter's Kubernetes identity initially lacked effective permission to list pods in the `debug-lab` namespace, or the intended RoleBinding and ServiceAccount configuration was not effective at that point.

**Fix:**

The reporter must use the intended ServiceAccount, and the Role and RoleBinding must grant that ServiceAccount permission to list pods in the required namespace.

The authorization check later returned `yes`. A separate diagnostic pod using the reporter ServiceAccount also successfully queried the Kubernetes API and received HTTP 200 with a valid PodList response.

**How I found it:**

I checked the reporter's permissions with:

```bash
kubectl auth can-i list pods -n debug-lab \
  --as=system:serviceaccount:debug-lab:reporter
```

I then inspected the ServiceAccount, Role, and RoleBinding:

```bash
kubectl get serviceaccount,role,rolebinding -n debug-lab
```

After further troubleshooting, the authorization check returned `yes`, and the separate API test returned a valid response.

---

## Defect 6

**Symptom:**

The reporter readiness endpoint returned HTTP 503. The application log showed:

```text
pod list failed: parse pod list: unexpected end of JSON input
GET /healthz -> 503
```

**Cause:**

The reporter application encountered an error while parsing the Kubernetes PodList response. The exact application-side root cause was not established.

A separate diagnostic pod using the reporter ServiceAccount successfully queried the Kubernetes API endpoint and received HTTP 200 with valid PodList JSON. Therefore, the available evidence did not establish a general Kubernetes API connectivity or RBAC failure as the cause of the reporter's parsing error.

**Fix:**

I verified the reporter ServiceAccount's authorization and tested the Kubernetes API independently. These checks confirmed that the separate test client could retrieve a valid PodList, but they did not resolve the reporter application's own parsing and readiness failure.

The reporter issue remained unresolved in the last confirmed investigation. My next step would be to inspect the reporter's effective environment, request construction, API response handling, and parsing logic, then rerun the supplied verification script.

**How I found it:**

I inspected the reporter logs and deployment:

```bash
kubectl logs deployment/reporter -n debug-lab
kubectl describe deployment reporter -n debug-lab
```

I checked the ServiceAccount permission:

```bash
kubectl auth can-i list pods -n debug-lab \
  --as=system:serviceaccount:debug-lab:reporter
```

I then used a separate diagnostic pod with the reporter ServiceAccount to query:

```text
/api/v1/namespaces/debug-lab/pods
```

The diagnostic request returned HTTP 200 with valid PodList JSON, while the reporter application continued to log a parsing error. This narrowed the investigation but did not identify the exact cause.

---

## Final Status

The investigation identified Kubernetes Job validation and container security-context errors, examined namespace/resource ordering and gateway service addressing, and verified reporter ServiceAccount permissions using an independent API test.

The reporter's own PodList parsing and readiness issue remained unresolved in the last confirmed investigation. The final result should be updated using the actual output of:

```bash
./scenario.sh verify
```

I would next investigate the reporter's API response handling and parsing path, then repeat the verification and document any additional evidence.


If you ran out of time on any defect, say so here and describe what you would
have tried next — that section is read carefully and counts in your favour.
