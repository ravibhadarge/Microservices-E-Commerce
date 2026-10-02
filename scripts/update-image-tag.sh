#!/usr/bin/env bash
# GitOps image-tag updater: edits environments/<env>/values.yaml, commits, pushes.
# Argo CD then syncs the cluster from Git.
#
# Usage (run from the repo root, inside a git checkout whose "origin" is writable):
#   scripts/update-image-tag.sh <env> <service>=<tag> [<service>=<tag> ...]
#   scripts/update-image-tag.sh <env> --from <src-env>     # promote every tag from <src-env>
#
# Env vars:
#   GIT_BRANCH_NAME  branch to push to (default: main)
#   DRY_RUN=1        show the diff, do not commit or push (file is restored)
#   APPLY_ONLY=1     edit the values file in the working tree only (no commit/push, not restored);
#                    used to helm-lint/render the proposed change
#   GITOPS_OUT       file listing the "<service>=<tag>" pairs applied (default: .gitops-changes)
set -euo pipefail

BRANCH="${GIT_BRANCH_NAME:-main}"
OUT="${GITOPS_OUT:-.gitops-changes}"
YQ_VERSION="v4.44.3"

die() { echo "ERROR: $*" >&2; exit 1; }

[ $# -ge 2 ] || die "usage: $0 <env> <service>=<tag>... | $0 <env> --from <src-env>"
ENVIRONMENT="$1"; shift
VALUES="environments/${ENVIRONMENT}/values.yaml"
[ -f "$VALUES" ] || die "$VALUES not found (run from the repo root)"

SRC_ENV=""; PAIRS_ARG=()
if [ "$1" = "--from" ]; then
  [ $# -eq 2 ] || die "--from needs exactly one source environment"
  SRC_ENV="$2"
  [ -f "environments/${SRC_ENV}/values.yaml" ] || die "environments/${SRC_ENV}/values.yaml not found"
  [ "$SRC_ENV" != "$ENVIRONMENT" ] || die "source and target environment are the same"
else
  PAIRS_ARG=("$@")
fi

# ---- yq (install into the workspace if the agent does not have it) ----
if command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -q 'mikefarah\|version v4'; then
  YQ="$(command -v yq)"
else
  arch="$(uname -m)"; case "$arch" in x86_64) arch=amd64;; aarch64|arm64) arch=arm64;; esac
  mkdir -p .bin
  curl -fsSL -o .bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${arch}"
  chmod +x .bin/yq
  YQ="$PWD/.bin/yq"
fi

tag_path() {  # service -> yq path of its tag
  if [ "$1" = "loadgenerator" ]; then echo '.loadgenerator.image.tag'
  else echo ".services.\"$1\".tag"; fi
}

service_exists() {
  [ "$1" = "loadgenerator" ] && return 0
  "$YQ" -e ".services.\"$1\"" ecommerce/values.yaml >/dev/null 2>&1
}

all_services() {
  "$YQ" '.services | keys | .[]' ecommerce/values.yaml
  echo loadgenerator
}

# Fill PAIRS (array of service=tag) for the current checkout state.
build_pairs() {
  PAIRS=()
  if [ -n "$SRC_ENV" ]; then
    for s in $(all_services); do
      t="$("$YQ" "$(tag_path "$s")" "environments/${SRC_ENV}/values.yaml")"
      { [ -n "$t" ] && [ "$t" != "null" ]; } || continue
      PAIRS+=("$s=$t")
    done
  else
    PAIRS=("${PAIRS_ARG[@]}")
  fi
  [ ${#PAIRS[@]} -gt 0 ] || die "nothing to apply"
}

apply_pairs() {
  for pair in "${PAIRS[@]}"; do
    s="${pair%%=*}"; t="${pair#*=}"
    [[ "$pair" == *=* ]] || die "bad argument '$pair' (expected service=tag)"
    [[ "$t" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid tag '$t' for $s"
    service_exists "$s" || die "unknown service '$s'"
    TAG="$t" "$YQ" -i "$(tag_path "$s") = strenv(TAG)" "$VALUES"
  done
}

git config user.email >/dev/null 2>&1 || git config user.email "jenkins@ci.local"
git config user.name  >/dev/null 2>&1 || git config user.name  "jenkins"

if [ "${APPLY_ONLY:-0}" = "1" ]; then
  build_pairs; apply_pairs
  printf '%s\n' "${PAIRS[@]}" > "$OUT"
  exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
  build_pairs; apply_pairs
  printf '%s\n' "${PAIRS[@]}" > "$OUT"
  echo "---- planned change to $VALUES ----"
  git --no-pager diff -U0 -- "$VALUES" || true
  git checkout -- "$VALUES"
  exit 0
fi

ok=0
for i in 1 2 3 4 5; do
  # Always start from the newest remote branch so the commit is a fast-forward.
  git fetch origin "$BRANCH"
  git reset --hard "origin/${BRANCH}"

  build_pairs
  apply_pairs
  printf '%s\n' "${PAIRS[@]}" > "$OUT"

  git add "$VALUES"
  if git diff --cached --quiet; then
    echo "No change: ${VALUES} already has these tags."
    ok=1; break
  fi

  if [ -n "$SRC_ENV" ]; then summary="promote ${SRC_ENV} -> ${ENVIRONMENT}"
  else summary="${PAIRS[*]}"; fi
  git commit -m "gitops(${ENVIRONMENT}): ${summary} [skip ci]"

  if git push origin "HEAD:${BRANCH}"; then
    echo "Pushed: ${summary}"
    ok=1; break
  fi
  echo "Push rejected, re-syncing and retrying (${i}/5)..."
  sleep $((RANDOM % 5 + 2))
done
[ "$ok" = "1" ] || die "push failed after 5 attempts"
