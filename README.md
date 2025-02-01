# aws-infra-demo


env=demo
service_name=keycloak-service

task_arn=$(aws ecs list-tasks --cluster "${env}-cc-infra-cluster" --service-name ${env}-cc-infra-${service_name} --query "taskArns[]" --output text)

aws ecs execute-command \
  --cluster "${env}-cc-infra-cluster" \
  --task $task_arn \
  --container $service_name \
  --command "sh" \
  --interactive \
  --region eu-west-1

# keycloak urls
  https://auth.camelcase.club/realms/demo-realm/.well-known/openid-configuration


# API Tests

## token

curl -X POST "https://auth.camelcase.club/realms/demo-realm/protocol/openid-connect/token" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -d "client_id=static-app" \
     -d "client_secret=AYyxGdiab7SoxrGCbZO1r2akiWsndDPC" \
     -d "grant_type=password" \
     -d "username=mark@camelcase.email" \
     -d "password=Opt1plex!" \
     -o token.json

## api

curl -X GET "http://localhost:8080/api/users" \
     -H "Authorization: Bearer $(jq -r '.access_token' token.json)" \
     -H "accept: */*"