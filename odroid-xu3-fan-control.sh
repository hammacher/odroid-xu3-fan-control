#!/bin/bash

# Loud fan control script to lower speed of fun based on current
# max temperature of any cpu
#
# See README.md for details.

#set to false to suppress logs
DEBUG=true

# Make sure only root can run our script
if (( $EUID != 0 )); then
   echo "This script must be run as root:" 1>&2
   echo "sudo $0" 1>&2
   exit 1
fi


TEMPERATURE_FILE="/sys/devices/10060000.tmu/temp"
FAN_MODE_FILE="/sys/devices/odroid_fan.14/fan_mode"
FAN_SPEED_FILE="/sys/devices/odroid_fan.14/pwm_duty"
TEST_EVERY=3 #seconds
new_fan_speed_default=80
LOGGER_NAME=odroid-xu3-fan-control

#make sure after quiting script fan goes to auto control
function cleanup {
  ${DEBUG} && logger -t $LOGGER_NAME "event: quit; temp: auto"
  echo 1 > ${FAN_MODE_FILE}
}
trap cleanup EXIT

current_max_temp=`cat ${TEMPERATURE_FILE} | cut -d: -f2 | sort -nr | head -1`
echo "fan control started. Current max temp: ${current_max_temp}"
echo "For more logs see:"
echo "sudo tail -f /var/log/syslog"

while [ true ];
do
  echo 0 > ${FAN_MODE_FILE} #to be sure we can manage fan

  current_max_temp=`cat ${TEMPERATURE_FILE} | cut -d: -f2 | sort -nr | head -1`
  ${DEBUG} && logger -t $LOGGER_NAME "event: read_max; temp: ${current_max_temp}"

  temp_min=60000
  temp_max=80000
  fan_min=80
  fan_max=255
  new_fan_speed=$(( $fan_min + ($fan_max - $fan_min)*($current_max_temp - $temp_min)/($temp_max - $temp_min) ))
  new_fan_speed=$(( $new_fan_speed < $fan_min ? 1 : $new_fan_speed > $fan_max ? $fan_max : $new_fan_speed ))
  ${DEBUG} && logger -t $LOGGER_NAME "event: adjust; speed: ${new_fan_speed}"
  echo ${new_fan_speed} > ${FAN_SPEED_FILE}

  sleep ${TEST_EVERY}
done
