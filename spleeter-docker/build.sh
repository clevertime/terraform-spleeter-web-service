# Build the docker image
docker build -t  spleeter .

# Tag the image to match the repository name
docker tag $IMAGE 848147755445.dkr.ecr.us-west-2.amazonaws.com/spleeter-web-service-repo:latest

# Register docker to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 848147755445.dkr.ecr.us-west-2.amazonaws.com/spleeter-web-service-repo

# Push the image to ECR
docker push 848147755445.dkr.ecr.us-west-2.amazonaws.com/spleeter-web-service-repo:latest
