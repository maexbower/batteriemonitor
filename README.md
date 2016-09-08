#Beschreibung
Dieses Skript liest den aktuellen Akkustand aus und gibt bei unterschreiten eines definierten Wertes eine Warnung aus.
#Aufbau:
##/usr/src/batterymon/

1 script.sh

* wird vom Systemd Service aufgerufen und führt das eigendliche Skript mit dem gewünschten Parametern auf

2 monitor.sh

* **Syntax:** `monitor.sh [Filter][Critical][Warning]`

* **Standardwerte:**

	*  Filter=BAT (sucht in der Ausgabe von upower -e nach dem gegebenen String, Logitech Performance MX wird mit mouse gefunden)
	* Critical=10
	* Warning=20
	
* **Zurzeit implementiert Methoden:**
	 - [X] upower
	
* **Geplante Methoden:**

	 - [ ] acpi

	 - [ ] /sys/class/
	
* **In der monitor.sh können noch weitere Eistellungen getätigt werden:**
```

NOTIFYCOMMANDPREFIX="/usr/bin/i3-msg -s /home/max/.config/i3/ipc.sock exec"
	
NOTIFYCOMMAND="/usr/bin/notify-send"
	
NOTIFYTIMEOUT=20000
	
NOTIFYWARNINGKEYWORD="normal"
	
NOTIFYCRITICALKEYWORD="critical"
```
	
##/var/lib/systemd/system

3 batterymon.service
* Servicefile für Sytemd. 

* Pfad zur script.sh anpassen, wenn es nicht unter /usr/src/batterymon liegt
		
4 batterymon.timer
* Timerfile für Systemd

* muss ebenfalls mit systemctl aktiviert werden. Definiert das Aufrufintervall, ähnlich wie cron.


