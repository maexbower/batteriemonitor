#!/bin/bash
###############################
#Einstellungen
###############################
#Zeit in Sekunden, die zwischen den Abfragen gewartet werden soll (nicht implentiert)
#TIMETOWAIT=60
#Wird ein Cron Job verwendet, wird TIMETOWAIT ignoriert (nicht implentiert)
#USECRON=false
#Welche Technik soll zu Abfrage verwendet werden (UPOWER, ACPI, SYS)
#UPOWER benutzt das upower Paket als Abstaktionsebene
#ACPI benutzt das Paket acpi
#SYS verwendet das ab Kernel 3.19 verwendete Verzeichnis /sys/class/power_supply
USETOOL=UPOWER
#Schwellwerte und Wert
WARNING=('percentage' 20)
CRITICAL=('percentage' 10)
#Gerätefilter(BAT, mouse)
#BAT für Batterien
#mouse funktioniert bei Logitech Performance MX (bisher nur upower)
DEVFILTER="BAT"
NOTIFYCOMMANDPREFIX="/usr/bin/i3-msg -s /home/max/.config/i3/ipc.sock exec"
NOTIFYCOMMAND="/usr/bin/notify-send"
NOTIFYTIMEOUT=20000
NOTIFYWARNINGKEYWORD="normal"
NOTIFYCRITICALKEYWORD="critical"
###############################
#Funktionen
###############################
function quit
{
	exit
}
function writelog ()
{
	echo "$1"
}
function shownotification ()
{
	#1. Parameter Urgency
	#2. Summary
	#3. Texts
	#NOTIFY=""
	#echo $NOTIFY
	$NOTIFYCOMMANDPREFIX "$NOTIFYCOMMAND -u $1 -t $NOTIFYTIMEOUT \"$2\" \"$3\"";
	#echo "$NOTIFYCOMMANDPREFIX $NOTIFY"
	if [[ $? -gt 0 ]]; then
		writelog "Fehler beim Ausführen des Notifycommands"
	fi
}
function trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo -n "$var"
}

function useupower ()
{
	#Get devices
	declare -a DEVICES
	declare -A INFORMATION
	declare -a WARNINGDEV
	declare -a CRITICALDEV
	while IFS= read -r line; do
		if [[ $line == *"$DEVFILTER"* ]]; then
			DEVICES+=("$line")
		fi
	done < <(upower -e)
	#echo ${DEVICES[*]}
	for BATTERY in ${DEVICES[@]}; do
		unset INFORMATION
		declare -A INFORMATION
		#echo $BATTERY
		#Read Data from Device
		while IFS=':' read -r VALUENAME DATA; do
			if [[ "$VALUENAME" != "" && "$DATA" != "" ]]; then
				#Entferne führende und folgende Leerzeichen
				VALUENAME=$(trim $VALUENAME)
				DATA=$(trim $DATA)
				#Ersetze Leerzeichen in der Bezeichnung durch Unterstriche
				VALUENAME=${VALUENAME/' '/'_'}
				DATA=${DATA/','/' '}
				INFORMATION+=([$VALUENAME]="$DATA")
				#echo "$VALUENAME : $DATA"
			fi
		done < <(upower -i $BATTERY)
		#echo ${INFORMATION[*]}
		#Prüfe ob Warning Level überschritten
		#echo ${INFORMATION[${WARNING[0]}]}
		#echo ${INFORMATION[present]}
		if [[ "${INFORMATION[present]}" == "yes" ]]; then 
			if [[ "${INFORMATION[${WARNING[0]}]/'%'/''}" -lt "${WARNING[1]}" ]]; then
				if [[ "${INFORMATION[${CRITICAL[0]}]/'%'/''}" -lt "${CRITICAL[1]}" ]]; then
					CRITICALDEV+=("${INFORMATION[vendor]} ${INFORMATION[model]} : ${INFORMATION[${CRITICAL[0]}]}")
					writelog "Akku ${INFORMATION[vendor]} ${INFORMATION[model]} Kritisch: ${INFORMATION[${WARNING[0]}]}"
					#shownotification $NOTIFYCRITICALKEYWORD "Battery is empty" "Der Akku ${INFORMATION[vendor]} ${INFORMATION[model]} ist leer: ${INFORMATION[${CRITICAL[0]}]}"
				else
					WARNINGDEV+=("${INFORMATION[vendor]} ${INFORMATION[model]} : ${INFORMATION[${WARNING[0]}]}")
					writelog "Akku ${INFORMATION[vendor]} ${INFORMATION[model]} Warnung: ${INFORMATION[${WARNING[0]}]}"
					#shownotification $NOTIFYWARNINGKEYWORD "Battery is low" "Der Akku ${INFORMATION[vendor]} ${INFORMATION[model]} wird knapp: ${INFORMATION[${WARNING[0]}]}"
				fi
			else
				:
				#writelog "Akku ok"
			fi
		else
			:
			writelog "Akku ${INFORMATION[vendor]} ${INFORMATION[model]} nicht angeschlossen"
		fi
	done
	
	if [[ ${#DEVICES[@]} -le $(( ${#CRITICALDEV[@]}+${#WARNINGDEV[@]} )) ]]; then
		if [[ ${#CRITICALDEV[@]} -gt 0 ]]; then
			for DEV in "${CRITICALDEV[@]}"; do 
				shownotification $NOTIFYCRITICALKEYWORD "Battery is empty" "Der Akku ist leer: $DEV"
			done
		fi
		if [[ ${#WARNINGDEV[@]} -gt 0 ]]; then
			#echo ${WARNINGDEV[@]}
			for DEV in "${WARNINGDEV[@]}"; do 
				shownotification $NOTIFYWARNINGKEYWORD "Battery is low" "Der Akku wird knapp: $DEV"
			done
		fi
	else
		writelog "Nicht alle Akkus sind mindestens auf Warning."
	fi
	return 0
}
function useacpi ()
{
	:
}
function usesys()
{
	:
}

###############################
#Beginne Programm
###############################
writelog "Battery Monitor gestartet"
ERRORVALUE=0
ERRORTEXT=""
if [[ ! -z $1 ]]; then
	writelog "DEVFILTER: $1"
	DEVFILTER="$1"
fi
if [[ ! -z $2 ]]; then
	writelog "WARNING: $2"
	WARNING[1]=$2
fi
if [[ ! -z $3 ]]; then
	writelog "CRITICAL: $3"
	CRITICAL[1]=$3
fi
echo ${WARNING[@]}
echo ${CRITICAL[@]}
case "$USETOOL" in
	UPOWER)
		useupower
		;;
	ACPI)
		useacpi
		;;
	SYS)
		usesys
		;;
	*)
		writelog "kein erlaubtes Tool angegeben. Möglich(UPOWER,ACPI,SYS). Gegeben: $USETOOL."
esac
if [ $ERRORVALUE == 0 ]; then
	writelog "erfolgreich Ausgeführt"
	exit 0
else
	writelog "bei der Verarbeitung ist ein Fehler aufgetreten: $ERRORTEXT."
	exit $ERRORVALUE
fi

