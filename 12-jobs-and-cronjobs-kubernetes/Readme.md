# 🧭 Kubernetes Jobs & CronJobs — Full Notes

Companion notes for the **Kubernetes Jobs & CronJobs Explained** video. Everything covered on screen — concepts, YAML, and commands — is captured here for reference.

---

## 0. Setup

```bash
minikube delete
minikube start --driver=docker --nodes=3
kubectl get nodes
```

Confirms 1 control-plane + 2 worker nodes are `Ready` before starting.

---

## 1. Why Not a Deployment?

A Deployment's job is to **keep Pods running** — if the container exits (even successfully), the Deployment restarts it forever. That's correct for a web server, wrong for a one-time task.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-generator
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-generator
  template:
    metadata:
      labels:
        app: report-generator
    spec:
      containers:
        - name: report
          image: busybox:1.36
          command: ["sh", "-c", "echo Generating report; sleep 10"]
```

```bash
kubectl apply -f bad-deployment.yaml
kubectl get pods -w
```

**Result:** the Pod restarts in a loop forever, even though the task "succeeded."

```text
Deployment goal:  "Keep 1 Pod running"       →  restarts forever
Job goal:         "Get 1 successful finish"  →  stops after success
```

---

## 2. What Is a Job?

> A **Job** runs a task to completion. It creates a Pod, tracks whether it succeeds or fails, and stops once the required number of successful completions is reached.

```text
                Job
                 |
                 v
               Pod
                 |
        +--------+--------+
        |                 |
     SUCCESS           FAILURE
        |                 |
        v                 v
   Job Complete       Retry according
                       to Job policy
```

**Layering:** the Job is the controller (policy — how many successes, how many retries). The Pod is where execution happens (container, command, exit code).

```text
Job
└── spec
    └── template          ← this is a Pod template
        └── spec
            └── containers
```

---

## 3. Your First Job

```yaml
apiVersion: batch/v1
kind: Job

metadata:
  name: hello-job

spec:
  template:
    metadata:
      labels:
        app: hello-job

    spec:
      restartPolicy: Never

      containers:
        - name: hello
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              echo "Starting Job..."
              echo "Doing some work..."
              sleep 10
              echo "Job completed successfully!"
```

| Field | Purpose |
|---|---|
| `apiVersion: batch/v1` | Jobs live in the `batch` API group |
| `spec.template` | Pod template used to create the work Pod |
| `restartPolicy` | Must be `Never` or `OnFailure` — never `Always` |

```bash
kubectl apply -f job.yaml
kubectl get jobs
kubectl get pods
```

Expected:

```text
NAME         COMPLETIONS   DURATION   AGE
hello-job    1/1           11s        15s
```

```text
hello-job-xxxxx   0/1   Completed
```

⚠️ `0/1 Completed` is **healthy** for a Job Pod — it means the container finished successfully and isn't running anymore. It is not the same signal as a broken Deployment Pod.

```bash
kubectl logs job/hello-job
```

---

## 4. Job Lifecycle & Troubleshooting Order

```text
Job created
    ↓
Job controller creates Pod
    ↓
Pod scheduled
    ↓
Container starts
    ↓
Work executes
    ↓
Container exits with code 0
    ↓
Pod = Completed
    ↓
Job = Complete
```

**Troubleshooting order:** Job → Pod → Logs (always in that order).

```bash
kubectl describe job hello-job
kubectl describe pod $(kubectl get pods -l job-name=hello-job -o jsonpath='{.items[0].metadata.name}')
```

---

## 5. Failure, Retries & backoffLimit

```yaml
apiVersion: batch/v1
kind: Job

metadata:
  name: failed-job

spec:
  backoffLimit: 3

  template:
    spec:
      restartPolicy: Never

      containers:
        - name: failing-task
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              echo "Starting task..."
              echo "Something went wrong!"
              exit 1
```

```bash
kubectl apply -f failed-job.yaml
kubectl get pods -w
kubectl get job failed-job
kubectl describe job failed-job
```

```text
Job
 |
 +--> Pod #1 → FAIL
 +--> Pod #2 → FAIL
 +--> Pod #3 → FAIL
 +--> Pod #4 → FAIL
 |
 Job = Failed  (backoffLimit: 3 exceeded)
```

- `backoffLimit` = number of Pod failures tolerated before the Job is marked `Failed`
- Default is **6** if not set
- Kubernetes applies an increasing delay between retries (backoff) — not instant back-to-back attempts
- Design question: is the task **idempotent**? Retrying isn't automatically safe — that's on the application, not Kubernetes

---

## 6. completions

> `completions` = total **successful** work required — not total Pod count.

```yaml
apiVersion: batch/v1
kind: Job

metadata:
  name: completion-job

spec:
  completions: 3

  template:
    spec:
      restartPolicy: Never

      containers:
        - name: worker
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              echo "Processing one unit of work..."
              sleep 5
              echo "Work completed!"
```

```bash
kubectl apply -f completions-job.yaml
kubectl get jobs,pods -w
```

If a run fails, an extra Pod is created to make up for it:

```text
Pod 1 → FAIL
Pod 2 → SUCCESS
Pod 3 → FAIL
Pod 4 → SUCCESS
Pod 5 → SUCCESS
   ↓
Job Complete (3/3 successes, 5 Pods total)
```

---

## 7. parallelism

> `completions` = how much work is needed. `parallelism` = how much runs at once.

```yaml
apiVersion: batch/v1
kind: Job

metadata:
  name: parallel-job

spec:
  completions: 6
  parallelism: 2

  template:
    spec:
      restartPolicy: Never

      containers:
        - name: worker
          image: busybox:1.36
          command:
            - sh
            - -c
            - |
              echo "Worker started: $(hostname)"
              sleep 10
              echo "Worker completed: $(hostname)"
```

```bash
kubectl apply -f parallel-job.yaml
kubectl get pods -l job-name=parallel-job -w
```

```text
Total work required = 6 successful completions
Parallelism cap     = 2 concurrent Pods

Time 1:  Pod A + Pod B
Time 2:  Pod C + Pod D
Time 3:  Pod E + Pod F

→ 6 successful completions → Job Complete
```

Kubernetes controls **how many Pods run** — your application controls **what each Pod actually does** (e.g. via a queue or `completionMode: Indexed`).

---

## 8. Extra Job Settings

```yaml
spec:
  activeDeadlineSeconds: 300   # hard ceiling on total Job runtime (incl. retries)
  ttlSecondsAfterFinished: 3600  # auto-delete Job + Pods this long after finishing
```

- `activeDeadlineSeconds` — terminates the Job as `Failed` if still active past this limit, regardless of `backoffLimit`
- `ttlSecondsAfterFinished` — automatic cleanup so finished Jobs don't pile up

---

## 9. Job vs Deployment vs DaemonSet

| If you're saying... | Use |
|---|---|
| "Run my API continuously." | Deployment |
| "Run a logging/monitoring agent on every node." | DaemonSet |
| "Run this database migration once." | Job |
| "Run this backup every night at 2 AM." | CronJob |
| "Process 10,000 independent work items, need 10,000 successes." | Job with `completions` + `parallelism` |

---

## 10. What Is a CronJob?

> A **CronJob** creates Job objects on a repeating schedule. The Job then manages the Pods that do the work.

```text
CronJob
   | schedule fires
   v
  Job
   | creates
   v
  Pod
   | executes
   v
Task completes
```

**Troubleshooting order:** CronJob (is it creating Jobs?) → Job (is it failing?) → Pod/logs (why is it failing?).

---

## 11. Your First CronJob

```yaml
apiVersion: batch/v1
kind: CronJob

metadata:
  name: hello-cronjob

spec:
  schedule: "*/1 * * * *"

  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never

          containers:
            - name: hello
              image: busybox:1.36
              command:
                - sh
                - -c
                - |
                  echo "CronJob started at $(date)"
                  echo "Running scheduled task..."
                  sleep 10
                  echo "Scheduled task completed at $(date)"
```

```text
CronJob
  └── jobTemplate
       └── template          ← Pod template
            └── containers
```

```bash
kubectl apply -f cronjob.yaml
kubectl get cronjobs
kubectl get cronjob,jobs,pods
```

Run the last command again after a minute to see a new Job appear.

---

## 12. Cron Schedule Syntax

```text
* * * * *
│ │ │ │ │
│ │ │ │ └── Day of week   (0–6, Sunday = 0)
│ │ │ └──── Month         (1–12)
│ │ └────── Day of month  (1–31)
│ └──────── Hour          (0–23)
└────────── Minute        (0–59)
```

| Schedule | Meaning |
|---|---|
| `*/1 * * * *` | Every minute |
| `*/5 * * * *` | Every 5 minutes |
| `0 0 * * *` | Midnight, every day |
| `0 2 * * *` | 2 AM, every day |
| `0 2 * * 0` | 2 AM, every Sunday |
| `30 8 * * 1-5` | 8:30 AM, weekdays |
| `0 0 1 * *` | Midnight, first of every month |

Timezone matters — set it explicitly:

```yaml
spec:
  timeZone: "Asia/Kolkata"
```

---

## 13. concurrencyPolicy

| Policy | Behavior |
|---|---|
| `Allow` (default) | New Job starts even if previous is still running |
| `Forbid` | Skip the new scheduled run while previous is still active |
| `Replace` | Kill the running Job, start the new one instead |

```yaml
apiVersion: batch/v1
kind: CronJob

metadata:
  name: long-cronjob

spec:
  schedule: "*/1 * * * *"
  concurrencyPolicy: Forbid

  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never

          containers:
            - name: worker
              image: busybox:1.36
              command:
                - sh
                - -c
                - |
                  echo "Long task started at $(date)"
                  sleep 90
                  echo "Long task finished at $(date)"
```

```bash
kubectl apply -f cronjob-forbid.yaml
kubectl get cronjob,jobs,pods -w
```

```text
Minute 1  →  Job A starts ─────────────── (running for 90s)
Minute 2  →  skipped (Job A still active, concurrencyPolicy: Forbid)
Minute 3  →  Job B starts
```

---

## 14. History Limits & suspend

```yaml
spec:
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
```

Keeps only the most recent N successful/failed Jobs — prevents unbounded accumulation on long-running CronJobs.

```yaml
spec:
  suspend: true
```

```bash
kubectl patch cronjob hello-cronjob -p '{"spec":{"suspend":true}}'
kubectl get cronjob hello-cronjob
kubectl patch cronjob hello-cronjob -p '{"spec":{"suspend":false}}'
```

⚠️ `suspend: true` only stops **future** scheduled runs — it does not stop a Job already in progress.

---

## 15. Production Examples & Checklist

**Nightly batch (e-commerce example):**
- Generate previous day's sales report
- Archive old records
- Clean temporary files
- Run payment reconciliation

**Batch processing (CI pipeline example):**
```yaml
completions: 10000
parallelism: 20
```

**Before shipping a production Job/CronJob, ask:**

```text
1. How long does this task normally take?
2. What happens if it fails?
3. Is retrying safe — is the task idempotent?
4. Can two executions safely overlap?
5. Which timezone does the schedule actually need?
6. How much Job history should we retain?
7. What CPU/memory does the task realistically need?
8. What happens if a dependency (DB, API) is unavailable?
9. How do we pause scheduling during a maintenance window?
10. How do we get alerted when a scheduled task fails?
```

---

## 16. Common Mistakes

1. Using a Deployment for a one-time task — it restarts "finished" containers forever
2. Forgetting `restartPolicy` — must be `Never` or `OnFailure`
3. Confusing `completions` with Pod count — it's successful work, not attempts
4. Thinking a CronJob runs Pods directly — the chain is always `CronJob → Job → Pod`
5. Ignoring `concurrencyPolicy` when a task can outlast its own schedule interval
6. Unlimited Job history — always set history limits (and `ttlSecondsAfterFinished` on standalone Jobs)

---

## 17. Cheat Sheet

```bash
# Cluster setup
minikube delete
minikube start --driver=docker --nodes=3
kubectl get nodes

# Jobs
kubectl apply -f job.yaml
kubectl get jobs
kubectl get pods
kubectl get jobs,pods
kubectl describe job <name>
kubectl logs job/<name>
kubectl delete job <name>

# CronJobs
kubectl apply -f cronjob.yaml
kubectl get cronjobs
kubectl get cronjob,jobs,pods
kubectl describe cronjob <name>
kubectl delete cronjob <name>

# Suspend / resume a CronJob
kubectl patch cronjob <name> -p '{"spec":{"suspend":true}}'
kubectl patch cronjob <name> -p '{"spec":{"suspend":false}}'
```

---

## 18. Final Mental Model

```text
Deployment ─────► KEEP RUNNING
DaemonSet  ─────► ONE PER ELIGIBLE NODE
Job        ─────► RUN → COMPLETE
CronJob    ─────► SCHEDULE → JOB → POD → COMPLETE
```

```text
completions  = total successful work required
parallelism  = how much of that work runs concurrently
backoffLimit = how many failures are tolerated before giving up
```

> Deployment asks: is my application running?
> DaemonSet asks: do I have the required Pod on every eligible node?
> Job asks: did my work successfully finish?
> CronJob asks: is it time to create the next Job?

---

## 📝 Additional notes

- **Missed schedules:** `startingDeadlineSeconds` limits how late a CronJob run may start. If the deadline passes, that run is skipped and counted as missed.
- **Smarter failure handling:** a Job's `podFailurePolicy` can fail immediately on specific exit codes, so it doesn't waste retries on errors that retrying won't fix.
- **Make jobs safe to re-run:** a CronJob can occasionally create more than one Job for a schedule, or none at all, so write your job so running it twice causes no harm.

## 📖 Official documentation

Learn more from the official Kubernetes docs:

- [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Handling retriable and non-retriable Pod failures](https://kubernetes.io/docs/tasks/job/pod-failure-policy/)

## 🙌 Support my work

If this helped you learn Kubernetes, please support the channel:

- 📺 **[Subscribe on YouTube](https://www.youtube.com/shubhamgourtech?sub_confirmation=1)** for more free DevOps and cloud courses
- 💼 **[Connect on LinkedIn](https://www.linkedin.com/in/theshubhamgour/)**
- 📸 **[Follow on Instagram](https://www.instagram.com/theshubhamgour/)**

#theshubhamgour #shubhamgour
