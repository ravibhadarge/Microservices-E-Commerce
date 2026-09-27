#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log) 2>&1

echo "======================================"
echo "   AMAZON LINUX 2023 - DEVOPS TOOLS"
echo "   Auto-Install + Jenkins Auto-Config"
echo "======================================"

echo "===== SYSTEM UPDATE ====="
dnf update -y

echo "===== BASE PACKAGES ====="
dnf install -y git wget unzip tar vim jq fontconfig ca-certificates gnupg docker java-21-amazon-corretto-devel maven --allowerasing

echo "===== DOCKER ====="
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user || true
usermod -aG docker ssm-user || true

echo "===== JAVA 21 ====="
export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto
echo "export JAVA_HOME=/usr/lib/jvm/java-21-amazon-corretto" >> /etc/profile
echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile

echo "===== JENKINS INSTALL ====="
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

echo "===== JENKINS AUTO-CONFIG (admin/admin) ====="
mkdir -p /var/lib/jenkins/init.groovy.d
chown jenkins:jenkins /var/lib/jenkins/init.groovy.d

# Disable setup wizard
cat > /var/lib/jenkins/init.groovy.d/01-disable-setup-wizard.groovy << 'GROOVY'
import jenkins.model.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
instance.save()
GROOVY

# Create admin user: admin / admin
cat > /var/lib/jenkins/init.groovy.d/02-create-admin-user.groovy << 'GROOVY'
import jenkins.model.*
import hudson.security.*

def instance = Jenkins.getInstance()

// Create security realm
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
instance.setSecurityRealm(hudsonRealm)

// Create admin user with password "admin"
def user = hudsonRealm.createAccount('admin', 'admin')
user.save()

// Set authorization strategy - full control for logged-in users
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
GROOVY

# Set proper ownership
chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
chmod 644 /var/lib/jenkins/init.groovy.d/*.groovy

# Start Jenkins
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

echo "Jenkins status:"
systemctl --no-pager --full status jenkins || true

echo "===== NODEJS 22 ====="
curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
dnf install -y nodejs

echo "===== AWS CLI v2 ====="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
rm -rf /tmp/aws
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "===== KUBECTL ====="
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

echo "===== HELM ====="
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "===== TERRAFORM ====="
TF_VERSION="1.13.1"
wget -q "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -O "/tmp/terraform.zip"
unzip -q /tmp/terraform.zip -d /tmp/terraform
install -m 0755 /tmp/terraform/terraform /usr/local/bin/terraform
rm -rf /tmp/terraform /tmp/terraform.zip

echo "===== EKSCTL ====="
EKSCTL_VERSION=$(curl -sL https://api.github.com/repos/eksctl-io/eksctl/releases/latest | jq -r '.tag_name')
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_${EKSCTL_VERSION#v}_Linux_amd64.tar.gz" -o /tmp/eksctl.tar.gz
tar -xzf /tmp/eksctl.tar.gz -C /tmp
install -m 0755 /tmp/eksctl /usr/local/bin/eksctl
rm -f /tmp/eksctl /tmp/eksctl.tar.gz

echo "===== GITHUB CLI ====="
dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
dnf install -y gh

echo "===== TRIVY ====="
rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.55.0/trivy_0.55.0_Linux-64bit.rpm || true

echo ""
echo "======================================"
echo "   INSTALLATION COMPLETE"
echo "======================================"
echo ""
JENKINS_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Jenkins URL: http://${JENKINS_IP}:8080"
echo "Jenkins Username: admin"
echo "Jenkins Password: admin"
echo ""
echo "IMPORTANT: Log out and log back in before using Docker."
