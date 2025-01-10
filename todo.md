- mention using external modules
- tg advantages
- nb: check that action cannot be triggered via external user when repo public


- image in ghcr

docker pull devopsinfra/docker-terragrunt:tf-1.10.3-tg-0.71.1
docker tag devopsinfra/docker-terragrunt:tf-1.10.3-tg-0.71.1 ghcr.io/mm-camelcase/docker-terragrunt:tf-1.10.3-tg-0.71.1
docker push ghcr.io/mm-camelcase/docker-terragrunt:tf-1.10.3-tg-0.71.1