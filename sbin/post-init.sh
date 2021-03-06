#!/sbin/busybox sh


# Logging

/sbin/busybox cp /data/user.log /data/user.log.bak
/sbin/busybox rm /data/user.log
exec >>/data/user.log
exec 2>&1

echo $(date) START of post-init.sh



# Remount rootfs rw
  /sbin/busybox mount rootfs -o remount,rw

#Copiar modulos a /system
sbin/busybox mount /system -o remount,rw

/sbin/busybox cp -f /lib/modules/*.ko /system/lib/modules/
/sbin/busybox chmod 755 /system/lib/modules/*.ko;


#Fijamos la frecuencia limite en 200MHz
#echo "200000"  > /sys/power/cpufreq_min_limit

##### Early-init phase #####

# Android Logger enable tweak (lo dejo por compatibilidad con Hardcore)
if /sbin/busybox [ "`/sbin/busybox grep ANDROIDLOGGER /system/etc/tweaks.conf`" ]; then
  insmod /lib/modules/logger.ko
fi

#Desde el recovery
if /sbin/busybox [ -f /data/.enable_logs ]; then
   insmod /lib/modules/logger.ko
   echo Enable logs
fi

#Cargar modulo frandom
insmod /lib/modules/frandom.ko

# IPv6 privacy tweak
#if /sbin/busybox [ "`/sbin/busybox grep IPV6PRIVACY /system/etc/tweaks.conf`" ]; then
  echo "2" > /proc/sys/net/ipv6/conf/all/use_tempaddr
#fi


# Remount all partitions with noatime
#  for k in $(/sbin/busybox mount | /sbin/busybox grep relatime | /sbin/busybox cut -d " " -f3)
#  do
#        sync
#        /sbin/busybox mount -o remount,noatime $k
#  done

# Remount ext4 partitions with optimizations
  for k in $(/sbin/busybox mount | /sbin/busybox grep ext4 | /sbin/busybox cut -d " " -f3)
  do
        sync
        /sbin/busybox mount -o remount,commit=15 $k
  done
  

# Miscellaneous tweaks
  echo "1500" > /proc/sys/vm/dirty_writeback_centisecs
  echo "200" > /proc/sys/vm/dirty_expire_centisecs
  echo "0" > /proc/sys/vm/swappiness
  echo "8192" > /proc/sys/vm/min_free_kbytes

# CFS scheduler tweaks
  echo HRTICK > /sys/kernel/debug/sched_features

# SD cards (mmcblk) read ahead tweaks
  echo "256" > /sys/block/mmcblk0/bdi/read_ahead_kb
  echo "256" > /sys/block/mmcblk1/bdi/read_ahead_kb

# TCP tweaks
  echo "2" > /proc/sys/net/ipv4/tcp_syn_retries
  echo "2" > /proc/sys/net/ipv4/tcp_synack_retries
  echo "10" > /proc/sys/net/ipv4/tcp_fin_timeout

# SCHED_MC power savings level
  #echo "1" > /sys/devices/system/cpu/sched_mc_power_savings

# Turn off debugging for certain modules
  echo "0" > /sys/module/wakelock/parameters/debug_mask
  echo "0" > /sys/module/userwakelock/parameters/debug_mask
  echo "0" > /sys/module/earlysuspend/parameters/debug_mask
  echo "0" > /sys/module/alarm/parameters/debug_mask
  echo "0" > /sys/module/alarm_dev/parameters/debug_mask
  echo "0" > /sys/module/binder/parameters/debug_mask


###### Compatibilidad con CWMManager ##########


# Remount system RW
/sbin/busybox mount -t rootfs -o remount,rw rootfs 
    

mkdir -p /customkernel/property
	echo true >> /customkernel/property/customkernel.cf-root 
	echo true >> /customkernel/property/customkernel.base.cf-root 
	echo Apolo >> /customkernel/property/customkernel.name 
	echo "Kernel Apolo JB" >> /customkernel/property/customkernel.namedisplay 
	echo 136 >> /customkernel/property/customkernel.version.number 
	echo 5.6 >> /customkernel/property/customkernel.version.name 
	echo true >> /customkernel/property/customkernel.bootani.zip 
	echo true >> /customkernel/property/customkernel.bootani.bin 
	echo true >> /customkernel/property/customkernel.cwm 
	echo 5.0.2.7 >> /customkernel/property/customkernel.cwm.version
#/sbin/busybox mount -t rootfs -o remount,ro rootfs 


##### Install SU ######################################################################################
Extracted_payload=0
# Check for auto-root bypass config file
if [ -f /system/.noautoroot ] || [ -f /data/.noautoroot ];
then
	echo "File .noautoroot found. Auto-root will be bypassed."
else
	# Seccion para rootear, instalar CWMManager y libreria del BLN
	#if  [ -e /system/xbin/su ] &&  [ -e /system/app/Superuser.apk ]  && [ -e /system/app/CWMManager.apk ] && [ -e /system/lib/hw/lights.exynos4.so.ApoloBAK2 ];
	if [ -f /system/Apolo/Desde_4-6 ];
	then
		echo "Nada que hacer, tenemos todo listo" 
	else
		if [ -f /system/Apolo/Desde_4- ];
		then
			/sbin/busybox mount /system -o remount,rw
				/sbin/busybox rm -rf /system/Apolo/Desde_4-
			/sbin/busybox mount /system -o remount,ro
		fi

		echo "Extraer payload"	
			Extracted_payload=1				
			/sbin/chmod 755 /sbin/read_boot_headers
			eval $(/sbin/read_boot_headers /dev/block/mmcblk0p5)
			load_offset=$boot_offset
			load_len=$boot_len
			cd / 
			/sbin/dd bs=512 if=/dev/block/mmcblk0p5 skip=$load_offset count=$load_len | tar x
		 	
		#Hacemos  root
			#/sbin/busybox mount /system -o remount,rw
			#/sbin/busybox rm /system/bin/su
			#/sbin/busybox rm /system/xbin/su
			#/sbin/busybox cp /res/misc/su /system/xbin/su
			#/sbin/xzcat /res/misc/su.xz > /system/xbin/su
			#/sbin/busybox chown 0.0 /system/xbin/su
			#/sbin/busybox chmod 6755 /system/xbin/su
			#/sbin/busybox mount /system -o remount,ro
		#Supersu
			#/sbin/busybox mount /system -o remount,rw
			#/sbin/busybox rm /system/app/Superuser.apk
			#/sbin/busybox rm /data/app/Superuser.apk
			#/sbin/busybox rm /system/app/Supersu.apk
			#/sbin/busybox rm /data/app/Supersu.apk
			#/sbin/busybox rm /system/app/*supersu*
			#/sbin/busybox rm /data/app/*supersu*
			#/sbin/busybox cp /res/misc/Superuser.apk /system/app/Superuser.apk
			#/sbin/xzcat /res/misc/Superuser.apk.xz > /data/app/Superuser.apk
			#/sbin/busybox chown 0.0 /data/app/Superuser.apk
			#/sbin/busybox chmod 644 /data/app/Superuser.apk
			#/sbin/busybox mount /system -o remount,ro 
		
		#Librerias para el BLN

			sbin/busybox mount /system -o remount,rw
			/sbin/xzcat /res/misc/lights.exynos4.so.xz > /res/misc/lights.exynos4.so
			echo "Copiando las  liblights"
			/sbin/busybox cp -f /system/lib/hw/lights.exynos4.so /system/lib/hw/lights.exynos4.so.ApoloBAK2
			/sbin/busybox cp -f /res/misc/lights.exynos4.so /system/lib/hw/lights.exynos4.so
			/sbin/busybox chown 0.0 /system/lib/hw/lights.exynos4.so
			/sbin/busybox chmod 644 /system/lib/hw/lights.exynos4.so

		#Lo hacemos solo la primera vez
			/sbin/busybox mkdir /system/Apolo
    			/sbin/busybox chmod 755 /system/Apolo
			echo 1 > /system/Apolo/Desde_4-6
			/sbin/busybox mount /system -o remount,ro 
	fi
	#Borramos payload
	rm -rf /res/misc/*
fi

/sbin/busybox mount -t rootfs -o remount,ro rootfs

# Fin de la seccion su y ficheros auxiliares ############################################################################################################################

echo $(date) PRE-INIT DONE of post-init.sh
##### Post-init phase #####
sleep 12

#Colocando tweaks de configuracion

if /sbin/busybox [ -f /data/.disable_mdnie ]; then
   echo 1 > /sys/class/misc/mdnie_preset/mdnie_preset
   echo $(date) Disable mdnie sharpness
fi

if /sbin/busybox [ -f /data/.enable_crt ]; then
   echo $(cat /data/.enable_crt) > /sys/power/fb_pause
   echo $(date) Value inside the .enable_crt
else
   echo 50 > /sys/power/fb_pause
   echo $(date) Default Value 50
   echo $(date) No .enable_crt, so 50 is default value to fb_pause
fi


# init.d support

echo $(date) USER EARLY INIT START from /system/etc/init.d
if cd /system/etc/init.d >/dev/null 2>&1 ; then
    for file in * ; do
        if ! cat "$file" >/dev/null 2>&1 ; then continue ; fi
        echo "START '$file'"
        /system/bin/sh "$file"
        echo "EXIT '$file' ($?)"
    done
fi
echo $(date) USER EARLY INIT DONE from /system/etc/init.d





echo $(date) END of post-init.sh
