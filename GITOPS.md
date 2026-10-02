# GitOps with Helm + Argo CD

```
git push (code) -> Jenkins CI job per service
   1. docker build  -> ravibhadarge/<service>:<BUILD_NUMBER>   (run 1 -> :1, run 2 -> :2, ...)
   2. docker push
   3. scripts/update-image-tag.sh dev <service>=<BUILD_NUMBER>
        -> commits environments/dev/values.yaml  (services.<service>.tag)
Argo CD (watches Git) -> helm template ecommerce/ + environments/dev/values.yaml -> cluster
```

Jenkins never runs `kubectl apply`. Git is the source of truth; Argo CD only reads it.

## Where things live

| What | File |
|---|---|
| Chart (templates, defaults) | `ecommerce/` |
| Everything you tune per environment (replicas, HPA, ingress host, DB size, **image tags**) | `environments/<env>/values.yaml` |
| One image tag per service | `services.<name>.tag` (loadgenerator: `loadgenerator.image.tag`) |
| Argo CD Applications | `argocd/ecommerce-<env>.yaml` |
| CI (build, push, write tag) | `jenkinsfiles/<service>/Jenkinsfile` |
| CD (promote / deploy / rollback) | `jenkinsfiles/cd/Jenkinsfile` |
| Tag writer used by both | `scripts/update-image-tag.sh` |

Tags are **per service** because every Jenkins job has its own build counter
(frontend may be at 12 while cartservice is at 10).

## One-time setup

```bash
# Argo CD (skip if already installed)
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# if the repo is private: add it in Argo CD (Settings -> Repositories) with a GitHub token

# create the apps
kubectl apply -f argocd/ecommerce-dev.yaml
kubectl apply -f argocd/ecommerce-staging.yaml      # only if this cluster runs staging
kubectl apply -f argocd/ecommerce-production.yaml   # only if this cluster runs production
```

Each environment has its own EKS cluster (see README). Either install Argo CD in each cluster
(use `server: https://kubernetes.default.svc`, as written) or register the other clusters in one
Argo CD and change `destination.server`.

## Daily use

* **Deploy to dev:** run the service's CI job (or `all-services`). Done: Argo CD picks up the new tag.
* **Promote:** run the `cd` job -> `ENVIRONMENT=staging`, `ACTION=promote`, `PROMOTE_FROM=dev`
  (copies every tag from dev; staging/production wait for manual approval).
* **One service, specific build:** `ACTION=deploy`, `SERVICE=frontend`, `IMAGE_TAG=12`.
* **Rollback:** `ACTION=rollback`, `SERVICE=frontend`, `IMAGE_TAG=<older build>`
  (or `git revert` the tag commit; Argo CD follows Git either way).
* **Change any other value** (replicas, HPA, resources, host): edit `environments/<env>/values.yaml`,
  commit, push. No pipeline needed.

## Notes

* Only immutable `:<build number>` tags are pushed now (no `:latest`).
* Tag commits carry `[skip ci]`. If a job is triggered by a webhook/SCM polling, install the
  "SCM Skip" plugin or filter paths, otherwise these commits can retrigger CI.
* Argo CD polls Git about every 3 minutes; add a GitHub webhook to `<argocd>/api/webhook` for instant sync.
* `kubernetes-files/` is now legacy (nothing updates it). Do not apply it to a cluster managed by Argo CD.
* `backend` has no CI Jenkinsfile yet; its tag is seeded at `1` and can be changed with the `cd` job.
* Seeded tags in `environments/*/values.yaml` are the numbers that were in `kubernetes-files/*.yaml`.
  Check they exist on Docker Hub before the first sync.
