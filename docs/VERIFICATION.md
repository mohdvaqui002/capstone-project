# Verified results

Checked during the 2026-09-28/29 setup session.

| Check | Result |
|---|---|
| Terraform | Four EC2 instances running; original 23-resource apply completed |
| Ansible | All four hosts configured without errors; repeat run changed=0 and failed=0 |
| Kubernetes | One control-plane and two workers Ready, v1.35.9, containerd 2.2.1 |
| Cluster services | CoreDNS and Flannel running; service DNS returned the website |
| Jenkins | Authenticated access enabled; Java 21 and Docker active |
| Jenkins build 1 | SUCCESS: checkout, Docker build, HTTP checks, Docker Hub push |
| Jenkins build 2 | SUCCESS, automatically triggered by an SCM change |
| GitHub Actions | Container checks and GitHub Pages passed after the startup retry fix |
| Image | Published to mohdvaqui002/capstone-project by digest |
| Kubernetes application test | Two Ready replicas on different workers, NodePort 30008 |
| HTTP | Both worker public IPs returned HTTP 200 during the temporary validation deployment |
| Jenkins RBAC | Can patch capstone deployments; cannot read kube-system secrets |
| Release gate | Positive/negative date tests passed; real runs outside the 25th skipped production deployment |

The temporary capstone-validation namespace was deleted after verification, freeing NodePort 30008. A production release has not yet occurred. Routine releases are configured for the 25th of each month in Asia/Kolkata; an initial off-calendar production demo requires an explicit exception. Do not describe the website as currently deployed to production.

This project interprets the brief's CodeBuild wording as the Jenkins build stage. AWS CodeBuild is not provisioned. The repository uses main in place of master. These interpretations should be confirmed with the assessor if literal naming/services are required.

The local outputs/evidence folder contains the actual Jenkins console, image digest, Kubernetes inventory and Ansible recap. Credentials, live SSH keys, state and inventory are intentionally excluded from this public repository.
