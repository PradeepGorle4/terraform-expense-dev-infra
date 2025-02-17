#!/bin/bash

dnf install ansible -y

# For Push based in Ansible
# cmd - ansible-playbook -i inventory backend.yaml

# For Push based in Ansible

ansible-pull -i localhost, -U https://github.com/PradeepGorle4/expense-ansible-roles-tf.git main.yaml -e component=backend -e environment=$1