mount -t proc none root/proc
mount --rbind /sys root/sys
mount --rbind /dev root/dev
mount --rbind /run root/run
