# CIP Cloud Credential Operator

[Version: v0.0.0]


## What is it?
See [README.md](./README.md) for detailed information about this component based on OpenShift Cloud Credential Operator.



## Why creating a custom version?

This component greatly simplify operations app-specific AWS IAM users management and related
Access Key / Secret Key (AKSK).

Cloud Innovation Platform extensively OpenShift on AWS from the beginning of the project
but as we are progressively integrating CSP's managed kubernetes services such as AWS EKS,
Azure AKS and our internal Cloud Platform, we need to build our own version of this operator.

We'll try to contribute contribute as much as possible to the upstream repository and reserve
this repo to our platforms-specific configuration & features.



## License

This component is licensed under Apache License, version 2 as the upstream component.

