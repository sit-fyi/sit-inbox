#! /usr/bin/env bash

cfg=/playbook/roles/common/vars/main.yml


# Convert configuration from TOML to YAML 
if [ -f /etc/sit-inbox/config.toml ]; then
        echo "Reading config /etc/sit-inbox.toml"
        mkdir -p $(dirname $cfg)
        toml2yaml /etc/sit-inbox/config.toml > "$cfg"
else
        echo /etc/sit-inbox/config.toml not found, aborting
        exit 1
fi

json=config.json
yaml2json /schema.yaml > /schema.json
yaml2json ${cfg} > ${json}
ajv compile -s /schema.json || exit 1
ajv validate -s /schema.json -d ${json} || exit 1
rm ${json}

cols=$(tput cols)
lines=$(tput lines)
 
ANSIBLE_STDOUT_CALLBACK=unixy ansible-playbook -l 127.0.0.1 /playbook/playbook.yml || exit 1

syslogd
crond -b

while true; do
        cols=$(tput cols)
        lines=$(tput lines)
        result=$(dialog --keep-window \
                --begin 0 $(expr ${cols} / 4) --tailboxbg /var/log/messages ${lines} $(expr ${cols} \* 3 / 4)\
                --and-widget --keep-tite --keep-window \
                --begin 0 0 --no-shadow --menu "Action" 10 $(expr ${cols} / 4) 10 \
                "M" "Check mail" \
                "Q" "Quit" \
                --output-fd 1)
        case "${result}" in
                Q)
                        clear
                        exit 0
                        ;;
                M)
                        check-email &
                        ;;
                *)      echo
                        ;;
        esac
done
