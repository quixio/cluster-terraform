resource "local_file" "ansible_file" {
  filename = "ansible/quixcluster.yml"
  content = <<-EOF
- name: "Installing all drivers to the cluster"
  hosts: localhost
  connection: local
  roles:
    - ebs
    - efs
    - nlb
  vars:
    account: ${data.aws_caller_identity.current.account_id}
    k8s_cluster_name: ${module.eks_al2.cluster_name}
    region: ${local.region}
    k8s_role: ${module.eks_al2.eks_managed_node_groups.quix.iam_role_name}
    k8s_id: ${regex("^https?://([^.]+)\\.", module.eks_al2.cluster_endpoint)[0]}
    k8s_key_id: ${module.eks_al2.kms_key_id}
    efs_id: ${aws_efs_file_system.this.id}
  EOF
  depends_on = [  module.eks_al2 ]
}

resource "null_resource" "createcontext" {
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${module.eks_al2.cluster_name}"
  }
  depends_on = [  module.eks_al2 ]
}

resource "null_resource" "ansible_command" {
  provisioner "local-exec" {
    command      = "ansible-playbook quixcluster.yml >> ansible_output.log 2>&1"
    interpreter  = ["/bin/bash", "-c"]
    working_dir  =  "ansible"
  }

   triggers = {
    always_run = timestamp()
  }

  depends_on = [
    null_resource.createcontext,
    local_file.ansible_file
  ]
}
