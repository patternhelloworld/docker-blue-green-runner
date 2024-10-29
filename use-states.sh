#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false

cache_all_states() {

  echo '[NOTICE] Checking which container, blue or green, is running. (Priority :  Where Consul Pointing = Where Nginx Pointing  > Which Container Running > Which Container Restarting)'

  local consul_pointing
  consul_pointing=$(docker exec ${project_name}-nginx curl ${consul_key_value_store}?raw 2>/dev/null || echo "failed")

  local nginx_pointing
  nginx_config=$(docker exec ${project_name}-nginx cat /etc/nginx/conf.d/nginx.conf || echo "failed")
  if echo "$nginx_config" | grep -Eq "^[^#]*proxy_pass http[s]*://${project_name}-blue"; then
      blue_exists="blue"
  else
      blue_exists="failed"
  fi

  if echo "$nginx_config" | grep -Eq "^[^#]*proxy_pass http[s]*://${project_name}-green"; then
      green_exists="green"
  else
      green_exists="failed"
  fi

  if [[ $blue_exists == "blue" ]] && [[ $green_exists == "green" ]]; then
      nginx_pointing="error"
  elif [[ $blue_exists == "blue" ]]; then
      nginx_pointing="blue"
  elif [[ $green_exists == "green" ]]; then
      nginx_pointing="green"
  else
      nginx_pointing="failed"
  fi


  local blue_status
  blue_status=$(docker inspect --format='{{.State.Status}}' ${project_name}-blue 2>/dev/null || echo "unknown")
  local green_status
  green_status=$(docker inspect --format='{{.State.Status}}' ${project_name}-green 2>/dev/null || echo "unknown")


  echo "[DEBUG] ! Checking which (Blue OR Green) is currently running... (Base Check) : consul_pointing(${consul_pointing}), nginx_pointing(${nginx_pointing}), blue_status(${blue_status}), green_status(${green_status})"

  local blue_score=0
  local green_score=0

  # consul_pointing
  if [[ "$consul_pointing" == "blue" ]]; then
      blue_score=$((blue_score + 50))
  elif [[ "$consul_pointing" == "green" ]]; then
      green_score=$((green_score + 50))
  fi

  # nginx_pointing
  if [[ "$nginx_pointing" == "blue" ]]; then
      blue_score=$((blue_score + 50))
  elif [[ "$nginx_pointing" == "green" ]]; then
      green_score=$((green_score + 50))
  fi


  # status
  case "$blue_status" in
      "running")
          blue_score=$((blue_score + 30))
          ;;
      "restarting")
          blue_score=$((blue_score + 29))
          ;;
      "created")
          blue_score=$((blue_score + 28))
          ;;
      "exited")
          blue_score=$((blue_score + 27))
          ;;
      "paused")
          blue_score=$((blue_score + 26))
          ;;
      "dead")
          blue_score=$((blue_score + 25))
          ;;
      *)
          ;;
  esac

  case "$green_status" in
      "running")
          green_score=$((green_score + 30))
          ;;
      "restarting")
          green_score=$((green_score + 29))
          ;;
      "created")
          green_score=$((green_score + 28))
          ;;
      "exited")
          green_score=$((green_score + 27))
          ;;
      "paused")
          green_score=$((green_score + 26))
          ;;
      "dead")
          green_score=$((green_score + 25))
          ;;
      *)
          ;;
  esac


  # Check creation times and award 5 points to the most recently created container
  local blue_created green_created
  blue_created=$(docker inspect --format='{{.Created}}' ${project_name}-blue 2>/dev/null || echo "unknown")
  green_created=$(docker inspect --format='{{.Created}}' ${project_name}-green 2>/dev/null || echo "unknown")

  if [[ "$blue_created" != "unknown" && "$green_created" != "unknown" ]]; then
      if [[ "$blue_created" > "$green_created" ]]; then
          blue_score=$((blue_score + 5))
      elif [[ "$green_created" > "$blue_created" ]]; then
          green_score=$((green_score + 5))
      fi
  fi

  # Final
  if [[ $blue_score -gt $green_score ]]; then

         state='blue'
         if [[ ("$blue_status" == "unknown" || "$blue_status" == "exited" || "$blue_status" == "paused" || "$blue_status" == "dead") && "$green_status" == "running" ]]; then
           state_for_emergency='green'
         else
           state_for_emergency=${state}
         fi
         new_state='green'
         new_upstream=${green_upstream}

  elif [[ $green_score -gt $blue_score ]]; then

         state='green'
          if [[ ("$green_status" == "unknown" || "$green_status" == "exited" || "$green_status" == "paused" || "$green_status" == "dead") && "$blue_status" == "running" ]]; then
            state_for_emergency='blue'
          else
            state_for_emergency=${state}
          fi
         new_state='blue'
         new_upstream=${blue_upstream}

  else
        state='green'
        state_for_emergency=${state}
        new_state='blue'
        new_upstream=${blue_upstream}
  fi

  echo "[DEBUG] ! Checked which (Blue OR Green) is currently running... (Final Check) : blue_score : ${blue_score}, green_score : ${green_score}, state : ${state}, new_state : ${new_state}, state_for_emergency : ${state_for_emergency}, new_upstream : ${new_upstream}."
}