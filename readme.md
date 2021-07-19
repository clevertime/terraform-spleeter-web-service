# terraform-spleeter-web-service
tf module to create spleeter web service on aws

spleeter is a machine learning library that can perform audio transformations; this project specifically focuses on splitting vocal tracks from the accompaniment track in an MP3 file

## diagram
![diagram](./docs/images/architecture-diagram.png)

## prerequisites
*the following have been tested, other versions may work*

### software
- **terraform** >=0.13.0
- **docker** >=19.x.x
- **python** >=3.x.x

### services
- AWS Account
- Credentials to run terraform against your AWS account
- VPC to deploy resources into

## usage
this repository includes a script [deploy.sh](./deploy.sh) that will build the docker image and infrastructure required to run the spleeter web service

```
> ./deploy.sh -h

    -h -- Opens up this help message
    -p -- Name of the AWS profile to use
    -r -- AWS Region to deploy to (e.g. eu-west-1)
    -s -- AWS subnets to deploy resources to (e.g. -s subnet-xxxxxxxx,subnet-yyyyyyyy)
```

example invocation: `./deploy.sh -p my_aws_profile_name -r us-west-2 -s subnet-XXXXXXXXXXXXX,subnet-YYYYYYYYYYYYY`

1. Run Deploy Script.
  a. `provider.tf` will be created with your region and profile .
  b. `terraform.tfvars` will be created with the specified subnets.
  c. Terraform will create an ECR repository first.
  d. Docker will build the image and push to the ECR repository. (This may take a few minutes depending on your connection)
  e. The ECR image uri will be added to `terraform.tfvars`.
  f. Terraform will build the rest of the required infrastructure.
  ```
  Apply complete! Resources: 26 added, 0 changed, 0 destroyed.

Outputs:

ecr_repository_url = "848147755445.dkr.ecr.us-west-2.amazonaws.com/spleeter-web-service-repo"
s3_processed_bucket = "spleeter-web-service-processed"
s3_uploads_bucket = "spleeter-web-service-uploads"
status_dynamo_table = "spleeter-web-service-data"
```
2. Upload an mp3 file to the uploads bucket. (there is an example file in [./files/](./files))
3. Monitor progress in either Dynamo or StepFunctions
4. Once file is in a processed state, the separated audio files can be downloaded from the processed S3 bucket.

## terraform-docs
## Providers

| Name | Version |
|------|---------|
| archive | n/a |
| aws | n/a |

## Modules

No Modules.

## Resources

| Name |
|------|
| [archive_file](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) |
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_dynamodb_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) |
| [aws_ecr_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) |
| [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_lambda_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) |
| [aws_lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |
| [aws_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) |
| [aws_s3_bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) |
| [aws_sfn_state_machine](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sfn_state_machine) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| custom\_name | override name to use when naming resources | `any` | `null` | no |
| ddb\_read\_capacity | ddb | `number` | `2` | no |
| ddb\_write\_capacity | n/a | `number` | `2` | no |
| docker\_ecs\_uri | n/a | `any` | `null` | no |
| prefix | add prefix to default name i.e. 'prefix-spleeter-web-service' | `string` | `""` | no |
| subnets | ecs | `list` | `[]` | no |
| tags | n/a | `map` | `{}` | no |
| ttl | Time to live of processed jobs; specified in days | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| ecr\_repository\_url | n/a |
| s3\_processed\_bucket | n/a |
| s3\_uploads\_bucket | n/a |
| status\_dynamo\_table | n/a |
