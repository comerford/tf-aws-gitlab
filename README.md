# tf-aws-gitlab
Terraform config to create a single Gitlab host using Ubuntu 14.04 LTS and Omnibus Gitlab package

All actual values have been generalized, or gitignored and so at a minimum to get this to work you will need:

- A terraform.tfvars file or equivalent with valid variable entries (for [VPC](https://github.com/comerford/tf-aws-gitlab/blob/master/terraform.tfvars.example#L12) etc.)
- Especially valid [access](https://github.com/comerford/tf-aws-gitlab/blob/master/terraform.tfvars.example#L3)/[secret](https://github.com/comerford/tf-aws-gitlab/blob/master/terraform.tfvars.example#L4) keys 
- Actual SSL [cert](https://github.com/comerford/tf-aws-gitlab/blob/master/conf/gitlab.rb#L467)/[key](https://github.com/comerford/tf-aws-gitlab/blob/master/conf/gitlab.rb#L468) files (even self-signed) or gitlab will fail to start
- Agree to the TOU on [marketplace](https://aws.amazon.com/marketplace/pp/B00JV9TBA6/) for Canonical Ubuntu AMIs
- Substitute real IPs for [RFC5737](https://tools.ietf.org/html/rfc5737) addresses
- Sub in real values for the ELB access logs in the [bucket_policy.json](https://github.com/comerford/tf-aws-gitlab/blob/master/bucket_policy.json#L12)
- And if you change region don't forget to change the [principal](https://github.com/comerford/tf-aws-gitlab/blob/master/bucket_policy.json#L9) to the [correct value](http://docs.aws.amazon.com/ElasticLoadBalancing/latest/DeveloperGuide/enable-access-logs.html#attach-bucket-policy) too
- SMTP [credentials](https://github.com/comerford/tf-aws-gitlab/blob/master/conf/gitlab.rb#L290) and [region](https://github.com/comerford/tf-aws-gitlab/blob/master/conf/gitlab.rb#L288) settings in gitlab.rb (will start, but mail won't work)
