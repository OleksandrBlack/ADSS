#!/bin/bash

check_enabled() {
  services=("mhddos" "distress" "db1000n")
  stop_service=0
  for service in "${services[@]}"; do
    if sudo systemctl is-active "$service" >/dev/null; then
      stop_service=1
      break
    fi
  done
  return "$stop_service"
}

create_symlink() {
  if [ ! -L "/etc/systemd/system/mhddos.service" ]; then
    sudo ln -sf "$SCRIPT_DIR"/services/mhddos.service /etc/systemd/system/mhddos.service >/dev/null 2>&1
  fi

  if [ ! -L "/etc/systemd/system/distress.service" ]; then
    sudo ln -sf "$SCRIPT_DIR"/services/distress.service /etc/systemd/system/distress.service >/dev/null 2>&1
  fi

  if [ ! -L "/etc/systemd/system/db1000n.service" ]; then
    sudo ln -sf "$SCRIPT_DIR"/services/db1000n.service /etc/systemd/system/db1000n.service >/dev/null 2>&1
  fi

  if [ ! -L "/etc/systemd/system/x100.service" ]; then
    sudo ln -sf "$SCRIPT_DIR"/services/x100.service /etc/systemd/system/x100.service >/dev/null 2>&1
  fi
}

stop_services() {
  adss_dialog "$(trans "Зупиняємо атаку")"
  sudo systemctl stop distress.service >/dev/null
  sudo systemctl stop db1000n.service >/dev/null
  sudo systemctl stop mhddos.service >/dev/null
  confirm_dialog "$(trans "Атака зупинена")"
  ddos_tool_managment
}

get_ddoss_status() {
  services=("mhddos" "distress" "db1000n", "x100")
  service=""

  for element in "${services[@]}"; do
    if systemctl is-active --quiet "$element.service"; then
      service="$element"
      break
    fi
  done
  if [[ -n "$service" ]]; then
    while true; do
      clear
      echo -e "${GREEN}$(trans "Запущено $service")${NC}"

      #Fix Kali
      #https://t.me/c/1764189517/301014
      #https://t.me/c/1764189517/300970
      #tail --lines=20 /var/log/syslog | grep -w "$service"
	  #Fix Parrot
      #journalctl -n 20 -u "$service.service" --no-pager

      #Fix Ubuntu < 19
      lsb_version="$(. /etc/os-release && echo "$VERSION_ID")"
      lsb_id="$(. /etc/os-release && echo "$ID")"

      if [[ "$lsb_id" == "ubuntu" ]] &&
         [[ "$lsb_version" < 19* ]]; then
        journalctl -n 20 -u "$service.service" --no-pager
      else
        tail --lines=20 /var/log/adss.log
      fi

      echo -e "${ORANGE}$(trans "Нажміть будь яку клавішу щоб продовжити")${NC}"

      if read -rsn1 -t 0.1; then
        break
      fi
    done
  else
    confirm_dialog "$(trans "Немає запущених процесів")"
  fi
}

ddos_tool_installed() {
  if [[ ! -f "$TOOL_DIR/db1000n" ]]; then
    return 1
  fi

  if [[ ! -f "$TOOL_DIR/distress" ]]; then
    return 1
  fi

  is_not_arm_arch
  if [[ $? == 1 ]]; then
    if [[ ! -f "$TOOL_DIR/mhddos_proxy_linux" ]]; then
      return 1
    fi
  fi

  return 0
}

ddos_tool_managment() {
  menu_items=("$(trans "Статус атаки")")
  check_enabled
  enabled_tool=$?
  if [[ "$enabled_tool" == 1 ]]; then
    menu_items+=("$(trans "Зупинити атаку")")
  fi
  menu_items+=("$(trans "Налаштування автозапуску")")
  is_not_arm_arch
  if [[ $? == 1 ]]; then
    menu_items+=("MHDDOS")
  fi
  menu_items+=("DB1000N" "DISTRESS" "X100" "$(trans "Повернутись назад")")
  res=$(display_menu "$(trans "Управління ддос інструментами")" "${menu_items[@]}")

  case "$res" in
  "$(trans "Статус атаки")")
    get_ddoss_status
    ddos_tool_managment
    ;;
  "$(trans "Зупинити атаку")")
    stop_services
    ;;
  "$(trans "Налаштування автозапуску")")
    autoload_configuration
    ;;
  "MHDDOS")
    initiate_mhddos
    ;;
  "DB1000N")
    initiate_db1000n
    ;;
  "DISTRESS")
    initiate_distress
    ;;
  "X100")
    initiate_x100
  ;;
  "$(trans "Повернутись назад")")
    ddos
    ;;
  esac
}
