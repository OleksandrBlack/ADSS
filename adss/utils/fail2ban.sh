#!/bin/bash

source "${SCRIPT_DIR}/utils/os-definition.sh"

install_fail2ban() {
    echo -e "${GREEN}Встановлюємо Fail2ban${NC}"

    case $(get_distribution) in
            debian)
                sudo apt-get update -y
                sudo apt-get upgrade -y
                sudo apt-get install -y fail2ban
            ;;
            ubuntu)
                sudo apt-get update -y
                sudo apt-get install -y fail2ban
            ;;
            fedora)
                sudo dnf update -y
                sudo dnf upgrade -y
                sudo dnf install -y fail2ban
            ;;
            centos)
                sudo yum update -y
                sudo yum install -y epel-release
                sudo yum install -y fail2ban
            ;;
    esac

    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo bash -c "echo '
[ssh]
enabled = true
port 	= ssh
filter = sshd
action = iptables[name=sshd, port=ssh, protocol=tcp]
logpath = %(sshd_log)s
backend = %(sshd_backend)s
maxretry = 3
bantime = 600' >> /etc/fail2ban/jail.local"

    sudo /bin/systemctl restart fail2ban.service
    echo -e "${GREEN}Fail2ban успішно встановлено${NC}"
}