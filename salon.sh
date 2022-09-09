#!/bin/bash

TITLE="A Snip Hair"
DECOR=$(printf "%0.s~" {1..13})
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

MAIN_MENU() {
  echo -e "\n$DECOR $TITLE $DECOR\n"
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi
 
  HOUR=$(date +"%H")
  TOD=""

  if [[ $HOUR < 12 ]]
  then
    TOD="morning"
  elif [[ $HOUR < 18 ]]
  then
    TOD="afternoon"
  else
    TOD="evening"
  fi

  echo -e "Good $TOD! Welcome to '$TITLE'.\n"
  
  # get available services
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  # if no service available
  if [[ -z $AVAILABLE_SERVICES ]]
  then
    # exit program
    echo "Sorry, '$TITLE' currently has no services available"
    EXIT
  else
    # display all services
    echo -e "\nHere are the services we offer:"
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME
    do
        echo -e "\t$SERVICE_ID) $NAME"
    done
  
    # ask for service
    echo -e "\nWhich service would you like?"
    read SERVICE_ID_SELECTED

    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
        echo -e "\nOops! Please select a number in order to choose a service.\n"
        MAIN_MENU
    else
        SERVICE_ID=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED")
        # if service does not exist
        if [[ -z $SERVICE_ID ]]
        then
            echo -e "\nOops! '$TITLE' does not currently offer a service for that selection.\n"
            MAIN_MENU
        else
            SELECTION=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID")
            echo -e "\nYour selection: $SELECTION"
            # get customer info
            echo -e "\nPlease type your phone number:"
            read CUSTOMER_PHONE
    
            CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
            # if customer does not exist
            if [[ -z $CUSTOMER_NAME ]]
            then
                # get new customer name
                echo -e "\nPlease type your name:"
                read CUSTOMER_NAME
    
                INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
                if [[ ! $INSERT_CUSTOMER_RESULT == "INSERT 0 1" ]]
                then
                    echo "\nSorry, we are currently unable to add you to our customer list.\n"
                    EXIT
                else
                    echo "Welcome, $CUSTOMER_NAME!"
                fi
            else
                echo "Hi,$CUSTOMER_NAME, welcome back!"
            fi
            # get customer id
            CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
            # get time
            echo -e "\nAt what time would you like your$SELECTION, $CUSTOMER_NAME?"
            read SERVICE_TIME
    
            # insert appointment
            INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES('$CUSTOMER_ID','$SERVICE_ID_SELECTED','$SERVICE_TIME')")
            if [[  $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
            then
                APPOINTMENT=$($PSQL "SELECT  customers.name, appointments.time, services.name FROM appointments JOIN customers ON appointments.customer_id = customers.customer_id JOIN services ON appointments.service_id = services.service_id WHERE appointments.customer_id = $CUSTOMER_ID AND appointments.service_id = $SERVICE_ID_SELECTED AND appointments.time = '$SERVICE_TIME'")
                echo "$APPOINTMENT" | while read NAME BAR TIME BAR SERVICE
                do
                    # confirm appointment details
                    echo -e "\nI have put you down for a $SERVICE at $TIME, $NAME.\n"
                done
                EXIT
            else
                echo -e "\Oops! Sorry, we could not complete that booking.\n"
                EXIT
            fi
      fi
    fi
  fi
}

EXIT() {
  echo -e "\nThank you so much for visiting.\n\nBye for now.\n"
}

MAIN_MENU