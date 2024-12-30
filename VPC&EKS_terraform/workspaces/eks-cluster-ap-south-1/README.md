

terraform init --backend-config=../../backend-config/config.tf --backend-config="key=eks-cluster-ap-south-1"

terraform workspace new eks-cluster-ap-south-1
terraform workspace select eks-cluster-ap-south-1


terraform plan --out eks-cluster-ap-south-1.plan