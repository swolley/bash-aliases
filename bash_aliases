#!/bin/bash

#swolley custom aliases and functions

# shortcuts fro cd command
cd.() {
  if [[ $# -eq 0 ]]; then
		# move 1 step outside
    cd ..
  elif [[ $1 =~ ^-[0-9]+$ ]]; then
		# move X steps outside
    for i in $( seq 1 "${1#-}" ); do
      cd ..
    done
  elif [[ $1 =~ ^[0-9]+$ ]]; then
		local index=$1
    while [ "$index" -gt 0 ]; do
      local next
      next="$(find . -nowarn -executable -mindepth 1 -maxdepth 1 -type d -not -name '.*' -not -path '*/.*' | sort | head -1)"
      if [[ -n "$next" ]]; then
        cd "$next" || exit
      fi
      ((index--))
    done
  elif [[ "$PWD" == *"$1"* ]]; then
    while [ "$(basename "$PWD")" != "$1" ]; do
      cd .. 
    done
  else
    local next
    next="$(find . -nowarn -executable -type d -not -name '.*' -not -path '*/.*' -iname "$1" | sort | head -1)"
    if [[ -n "$next" ]]; then
      cd "$next" || exit
    else
      echo "bash: cd. $1: Folder not in current path or subdirectories" 1>&2
    fi
  fi
}

# shortcuts for apache & php-fpm services actions
# TODO: handle multiple php-fpm versions on choices
development() {
	# get color code
  function color() {
  	if [ "$1" = 'active' ]; then
      printf "\e[32m"
    else
      printf "\e[31m"
    fi
  }
  
	# get color after action
  function nextcolor() {
    if [ "$1" = 'start' ]; then
      color "active"
    else
      color "inactive"
    fi
  }

	# print service status
  function printresult() {
    local length

    echo -n "$1"
	  length=$((14 - ${#1}))
    for i in {0..$length}; do echo -n " "; done
    echo -ne "[$2 $3"
    length=$((8 - ${#3}))
    for i in {0..$length}; do echo -n " "; done
    echo -e " \e[0m]"
  }

	# change service status
  function toggle() {
    local service_name
    service_name="$1"
    local current_status
    current_status="$2"
    local action
    action="$4"
    local current_color
    current_color="$3"
    local show_output
    show_output="$5"
    local next_color
    next_color=$(nextcolor "$action")
    local length
        
    if [[ "$current_status" != 'active' && "$action" = 'start' ]] || [[ "$current_status" != 'inactive' && "$action" = 'stop' ]] || [[ "$current_status" != 'enabled' && "$action" = 'enable' ]] || [[ "$current_status" != 'disabled' && "$action" = 'disable' ]]; then
      sudo systemctl "$action" "$service_name"
      current_status=$(systemctl is-active "$service_name")
    fi
    if [ "$show_output" -eq 1 ]; then
      length=$((14 - ${#service_name}))
      printresult "$service_name" "$next_color" "$current_status"
    fi
  }

	# execute strat/stop action on selected service
	function action_single() {
		local service_name
    service_name="$1"
		local current_status
    current_status="$2"
		local current_color
    current_color="$3"
		local new_status

		if [ "$service_name" = 'active' ]; then 
			new_status='stop' 
		else 
			new_status='start'
		fi

		toggle "$service_name" "$current_status" "$current_color" "$new_status" 0
	}

	# exceute action on all services
  function action_all() {
    local action
    action="$1"
    local show_output
    show_output="$2"

    toggle "$php_fpm_name" "$php_fpm_status" "$php_fpm_color" "$action" $show_output
    toggle "$apache_name" "$apache_status" "$apache_color" "$action" $show_output
	}

	# print status of all services
  function status() {        
   	printresult "$apache_name" "$apache_color" "$apache_status"
    printresult "$php_fpm_name" "$php_fpm_color" "$php_fpm_status"
  }

	function switch() {
		local service_name
    service_name="$1"

		sudo update-alternatives --config "$service_name"
	}
  
	# read action
  local selection
  selection="$1"
  password=""

	# get services informations
  php_fpm_name=$(service --status-all | grep "\-fpm" | tail -n 1 | awk -F '[[:space:]][[:space:]]+' '{ print $2 }')
  php_fpm_status=$(systemctl is-active "$php_fpm_name")
  php_fpm_color=$(color "$php_fpm_status")
  apache_name=$(service --status-all | grep "apache" | tail -n 1 | awk -F '[[:space:]][[:space:]]+' '{ print $2 }')
  apache_status=$(systemctl is-active "$apache_name")
  apache_color=$(color "$apache_status")

	# handle selections
  if [[ "$selection" = "start" || "$selection" = "stop" || "$selection" = "enable" || "$selection" = "disable" ]]; then
    action_all "$selection" 1
  elif [ "$selection" = "status" ]; then
    status
  elif [ "$selection" = "toggle" ]; then
    local new_status
    local got_to_exit
    got_to_exit=0

    while  [ "$got_to_exit" -eq 0 ]; do
      echo -e "1) $(printresult "$apache_name" "$apache_color" "$apache_status")"
      echo -e "2) $(printresult "$php_fpm_name" "$php_fpm_color" "$php_fpm_status")"
      echo -n "Select a service: "
      read 

      case $REPLY in
        1) 
					action_single "$apache_name" "$apache_status" "$apache_color"
					apache_status=$(systemctl is-active "$service_name")
					apache_color=$(color "$apache_status");;
        2)
					action_single "$php_fpm_name" "$php_fpm_status" "$php_fpm_color"
					php_fpm_status=$(systemctl is-active "$php_fpm_name")
      		php_fpm_color=$(color "$php_fpm_status");;
        *)
            got_to_exit=1;;
      esac
      echo
    done
	elif [ "$selection" = "switch" ]; then
		switch "php"
	else
		echo "Use of development [OPTION] command"
		echo "Executes actions on Apache & php-fpm services."
		echo
		echo "status \t prints apache & php-fpm services status"
		echo "start \t starts both apache & php-fpm services"
		echo "stop \t stops both apache & php-fpm services"
		echo "enable \t enables both apache & php-fpm services on system startup"
		echo "disable  enables both apache & php-fpm services on system startup"
		echo "toggle \t toggles status on selected service from available options"
		echo "switch \t changes php-fpm current system version"
  fi
}
