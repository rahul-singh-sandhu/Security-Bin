#!/bin/bash

# _____   ______
# |  __ \ / ____| Rahul Sandhu
# | |__) | (___   rahul@sandhuservices.dev
# |  _  / \___ \  https://sandhuservices.dev/
# | | \ \ ____) | https://gitlab.sandhuservices.dev/rahulsandhu/
# |_|  \_\_____/  https://github.com/rahul-singh-sandhu

NAME="Security Universal Policy Binary"
CODENAME="securitybinary"
COPYRIGHT="Copyright (C) 2022 Rahul Sandhu"
LICENSE="GNU General Public License 3.0"
VERSION="0.1"

if [[ $(firewall-cmd --query-panic) == "yes" ]]; then lockdown_mode_status="enabled"; else lockdown_mode_status="disabled"; fi

if [[ $1 == "firewall" ]]; then
	case $2 in
	"allow")
		if [ -z ${3+x} ]; then
			echo "Port not specified - please specify a port."
		fi
		firewall-cmd --permanent --zone=external --add-port=$3
		;;
	"deny")
		if [ -z ${3+x} ]; then
			echo "Port not specified - please specify a port."
		fi
		firewall-cmd --permanent --zone=external --remove-port=$3
		;;
	"list")
		if [[ -z ${3+x} ]]; then
			firewall-cmd --list-all
		else
			firewall-cmd --list-ports --zone=${3}
		fi
		;;
	"down")
		if [[ -z ${3+x} ]]; then
			systemctl stop firewalld.service
		else
			echo -e "Unexpected argument ${3}"
		fi
		;;
	"up")
		if [[ -z ${3+x} ]]; then
			systemctl start firewalld.service
		else
			echo -e "Unexpected argument ${3}"
		fi
		;;
	"disable")
		if [[ -z ${3+x} ]]; then
			systemctl disable firewalld.service
		else
			echo -e "Unexpected argument ${3}"
		fi
		;;
	"enable")
		if [[ -z ${3+x} ]]; then
			systemctl enable firewalld.service
		else
			echo -e "Unexpected argument ${3}"
		fi
		;;
	"status")
		if [[ -z ${3+x} ]]; then
			systemctl status firewalld.service
		else
			echo -e "Unexpected argument ${3}"
		fi
		;;
	esac
elif [[ $1 == "network" ]]; then
	case $2 in
	"password-show")
		if [[ -z ${3+x} ]]; then
			echo "Argument expected: "Wifi Network" "
		else
			wifi_password=$(nmcli -s -g 802-11-wireless-security.psk connection show "${3}") && echo -e "${3}: ${wifi_password}"
		fi
		;;
	"down")
		case $3 in
		"wifi"|"wireless")
			wireless_interfaces=$(nmcli device | awk '$2=="wifi" {print $1}') && nmcli device disconnect ${wireless_interfaces};;
		"ethernet"|"wired")
			wired_interfaces=$(nmcli device | awk '$2=="ethernet" {print $1}') && nmcli device disconnect ${wired_interfaces};;
		"")
			systemctl stop NetworkManager;;
		*)
			nmcli device disconnect ${3};;
		esac
		;;
	"up")
		case $3 in
		"wifi"|"wireless")
			wireless_interfaces=$(nmcli device | awk '$2=="wifi" {print $1}') && nmcli device connect ${wireless_interfaces};;
		"ethernet"|"wired")
			wired_interfaces=$(nmcli device | awk '$2=="ethernet" {print $1}') && nmcli device connect ${wired_interfaces};;
			"")
			systemctl start NetworkManager;;
		*)
			nmcli device connect ${3};;
		esac
		;;
	"vpn")
		case $3 in
		"up")
			if [[ -z ${4+x} ]]; then
				IFS=$'\n' array=($(nmcli connection show | grep vpn | sed 's/ .*$//'))
				if [[ ${array[0]} == "" ]]; then
					echo "No VPN connections found."
				elif [[ ${array[1]} == "" ]] && [[ ${array[0]} != "" ]]; then
					nmcli connection up ${array[0]}
				else
					j=0 && k=0
					for i in "${array[@]}"; do
						j=$((j+1))
						echo "${j}. ${array[${k}]}"
						k=$((k+1))
					done
					read -p "Please enter a vpn connection: " user_vpn_connection
					user_vpn_connection=$((user_vpn_connection-1))
					nmcli connection up ${array[${user_vpn_connection}]}
				fi
			else
				nmcli connection up ${4}
			fi
			;;
		"down")
			if [[ -z ${4+x} ]]; then
				IFS=$'\n' array=($(nmcli connection show --active | grep vpn | sed 's/ .*$//'))
				if [[ ${array[0]} == "" ]]; then
					echo "No VPN connections found."
				elif [[ ${array[1]} == "" ]] && [[ ${array[0]} != "" ]]; then
					nmcli connection down ${array[0]}
				else
					j=0 && k=0
					for i in "${array[@]}"; do
						j=$((j+1))
						echo "${j}. ${array[${k}]}"
						k=$((k+1))
					done
					read -p "Please enter a vpn connection: " user_vpn_connection
					user_vpn_connection=$((user_vpn_connection-1))
					nmcli connection down ${array[${user_vpn_connection}]}
				fi
			else
				nmcli connection up ${4}
			fi
			;;
		esac
		;;
	"restart")
		systemctl restart NetworkManager;;
	"stop")
		systemctl stop NetworkManager;;
	"start")
		systemctl start NetworkManager;;
	esac
elif [[ $1 == "status" ]] || [[ $1 == "--status" ]]; then
	echo -e "Firewall status: $(firewall-cmd --state)"
	secure_boot_status=$(mokutil --sb-state | sed 's/.* //p' | sed '1!d')
	echo -e "Secure Boot status: ${secure_boot_status}"
	if [[ $(sestatus | grep "enabled" | grep "SELinux") == *"enabled"* ]]; then echo "SELinux: enabled"; else echo "SELinux: disabled"; fi
	IFS=$'\n' array=($(nmcli connection show --active | grep vpn | sed 's/ .*$//'))
	if [[ ${array[0]} == "" ]]; then vpn_status="inactive"; else vpn_status="active"; fi
	echo -e "VPN: ${vpn_status}"
	echo -e "Lockdown mode: ${lockdown_mode_status}"
fi
