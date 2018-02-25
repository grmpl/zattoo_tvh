#!/bin/bash

#      Copyright (C) 2017-2018 Jan-Luca Neumann
#      https://github.com/sunsettrack4/zattoo_tvh/
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with zattoo_tvh. If not, see <http://www.gnu.org/licenses/>.


echo "ZattooPLUS for tvheadend"
echo "(c) 2017-2018 Jan-Luca Neumann"
echo "Version 0.3.3 2018/02/25"
echo ""

command -v phantomjs >/dev/null 2>&1 || { echo "PhantomJS is required but it's not installed!  Aborting." >&2; exit 1; }
command -v uni2ascii >/dev/null 2>&1 || { echo "uni2ascii is required but it's not installed!  Aborting." >&2; exit 1; }
command -v xmllint >/dev/null 2>&1 || { echo "libxml2-utils is required but it's not installed!  Aborting." >&2; exit 1; }

cd ~/ztvh
mkdir user 2> /dev/null

export QT_QPA_PLATFORM=offscreen


# ################
# MENU OPTIONS   #
# ################

if [ -e user/options ]
then
	echo "Press [ENTER] to open the options menu. Script continues in 5 secs..." && echo ""
	if read -t 5
	then
		while true
		do
			echo "--- OPTIONS MENU ---"
			until grep -q "chlogo [0-1]" user/options
			do
				sed -i 's/chlogo.*//g' user/options
				sed -i '/^\s*$/d' user/options
				echo "chlogo 0"  >> user/options
			done
			if grep -q "chlogo 1" user/options
			then
				echo "[1] Disable ZATTOO CHANNEL LOGOS"
			elif grep -q "chlogo 0" user/options
			then
				echo "[1] Enable ZATTOO CHANNEL LOGOS"
			fi
			if grep -q "epgdata [1-7]" user/options
			then
				echo "[2] Change time period for ZATTOO EPG GRABBER (current: $(sed '/epgdata/!d;s/epgdata //g;' ~/ztvh/user/options) day(s))"
			elif grep -q "epgdata 0" user/options
			then
				echo "[2] Enable ZATTOO EPG GRABBER"
			else
				sed -i 's/epgdata.*//g' user/options
				sed -i '/^\s*$/d' user/options
				echo "[2] Enable ZATTOO EPG GRABBER"
				echo "epgdata 0" >> user/options
			fi
			echo "[3] Change streaming quality/bandwidth"
			if grep -q "chpipe 3" user/options
			then
				echo "    (current: MAXIMUM @ 3-5 Mbit/s)"
			elif grep -q "chpipe 2" user/options
			then
				echo "    (current: MEDIUM @ 1,5 Mbit/s)"
			elif grep -q "chpipe 1" user/options
			then
				echo "    (current: LOW @ 600 kbit/s)"
			else
				sed -i 's/chpipe.*//g' user/options
				sed -i '/^\s*$/d' user/options
				echo "chpipe 3" >> user/options
				echo "    (current: MAXIMUM @ 3-5 Mbit/s"
			fi
			echo "[4] Restart script"
			echo "[5] Exit script"
			echo "[9] Logout from Zattoo and exit script" && echo ""
			read -p "Number....: " -n1 n && echo ""
			echo ""
			case $n in
			1)	if grep -q "chlogo 1" user/options
				then
					sed -i 's/chlogo 1/chlogo 0/g' user/options
					echo "ZATTOO CHANNEL LOGOS disabled!" && echo ""
				else
					sed -i 's/chlogo 0/chlogo 1/g' user/options
					echo "ZATTOO CHANNEL LOGOS enabled!" && echo ""
				fi;;
			2)	sed -i 's/epgdata.*//g' user/options
				sed -i '/^\s*$/d' user/options
				until grep -q "epgdata [0-7]" user/options 2> /dev/null
				do
					echo "Please enter the number of days you want to retrieve the EPG information."
					echo "[0] - DISABLE /// [1-7] - ENABLE"
					read -p "Number....: " -n1 epgnum && echo ""
					sed -i 's/epgdata.*//g' user/options
					sed -i '/^\s*$/d' user/options
					echo "epgdata $epgnum" >> user/options
					if grep -q "epgdata [1-7]" user/options 2> /dev/null
					then
						echo "ZATTOO EPG GRABBER enabled for $(sed '/epgdata/!d;s/epgdata //g;' ~/ztvh/user/options) day(s)!" && echo ""
						mv ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg.xml ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg_OLD.xml 2> /dev/null 
					elif grep -q "epgdata 0" user/options
					then
						echo "ZATTOO EPG GRABBER disabled!" && echo ""
					else
						echo "- ERROR: INVALID VALUE! -" && echo ""
						sed -i 's/epgdata.*//g' user/options
						sed -i '/^\s*$/d' user/options
					fi
				done;;
			3)	sed -i 's/chpipe.*//g' user/options
				sed -i '/^\s*$/d' user/options
				until grep -q "chpipe [1-3]" user/options 2> /dev/null
				do
					echo "Please choose the streaming quality you want to use."
					echo "[1] - LOW @ 600 kbit/s"
					echo "[2] - MEDIUM @ 1,5 Mbit/s"
					echo "[3] - MAXIMUM @ 3-5 Mbit/s"
					read -p "Number....: " -n1 pipenum && echo ""
					echo "chpipe $pipenum" >> ~/ztvh/user/options
					if grep -q "chpipe 3" ~/ztvh/user/options 2> /dev/null
					then
						echo "Streaming quality set to MAXIMUM" && echo ""
					elif grep -q "chpipe 2" ~/ztvh/user/options 2> /dev/null
					then
						echo "Streaming quality set to MEDIUM" && echo ""
					elif grep -q "chpipe 1" ~/ztvh/user/options 2> /dev/null
					then
						echo "Streaming quality set to LOW" && echo ""
					else
						echo "- ERROR: INVALID VALUE! -" && echo ""
						sed -i 's/chpipe.*//g' ~/ztvh/user/options
						sed -i '/^\s*$/d' ~/ztvh/user/options
					fi
				done;;
			4)	bash ztvh.sh
				exit 1;;
			5)	echo "GOODBYE" && exit 1;;
			9)	echo "Logging out..."
				rm channels.m3u chpipe.sh zattoo_fullepg.xml -rf user -rf work -rf epg -rf logos -rf chpipe 2> /dev/null
				echo "GOODBYE" && exit 1;;
			esac
		done
	fi
else
	touch user/options
fi

echo "Starting script..." && echo ""
rm -rf work 2> /dev/null && mkdir work


# ###############################
# EXPORT COOKIES AND SESSION ID #
# ###############################

cd work
phantomjs ~/ztvh/save_page.js https://zattoo.com/login > cookie_list
grep "beaker.session.id" cookie_list > session

# retrieve user data
if grep -q -E "login|password" ~/ztvh/user/userfile 2> /dev/null
then true
else
	echo "- ZATTOO LOGIN PAGE -"
	read -p "email.....: " login
	read -sp "password..: " password
	echo "login=$login" > ~/ztvh/user/userfile
	echo "password=$password" >> ~/ztvh/user/userfile
	echo "- ACCOUNT DATA SAVED! -"
	echo ""
fi 


# ###############
# LOGIN PROCESS #
# ###############

echo "Login to Zattoo webservice..."

session=$(<session)

curl -i -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/x-www-form-urlencoded" -v --cookie "$session" --data-urlencode "$(sed '1!d' ~/ztvh/user/userfile)" --data-urlencode "$(sed '2!d' ~/ztvh/user/userfile)" https://zattoo.com/zapi/v2/account/login > login.txt 2> /dev/null


# #############
# LOGIN CHECK #
# #############

if grep -q '"success": true' login.txt
then
	echo "- LOGIN SUCCESSFUL! -" && echo ""
	rm cookie_list
	sed '/Set-cookie/!d' login.txt > workfile
	sed -i 's/expires.*//g' workfile
	sed -i 's/Set-cookie: //g' workfile
	sed -i 's/Set-cookie: //g' workfile
	tr -d '\n' < workfile > session
	sed -i 's/; Path.*//g' session
	session=$(<session)
else 
	rm ~/ztvh/user/userfile
	echo "- LOGIN FAILED! -" && echo ""
	exit 0
fi


# ##############
# CHANNEL LIST #
# ##############

echo "Fetching channel list..."
sed 's/, "/\n/g' login.txt | grep "power_guide_hash" > powerid
sed -i 's/.*: "//g' powerid && sed -i 's/.$//g' powerid
powerid=$(<powerid)
curl -X GET --cookie "$session" https://zattoo.com/zapi/v2/cached/channels/$powerid?details=False > channels_file 2> /dev/null

if grep -q '"success": true' channels_file
then
	echo "Creating channel list..."
	sed 's/"display_alias"/\n&/g' channels_file > workfile
	sed -i '1d' workfile
	sed -i 's/{/\n/g' workfile
	sed -i '/"availability": "subscribable"/d' workfile && cp workfile channels_file
	sed -i '/"drm_required"/s/\("drm_required": true, \)\("logo_black_84": ".*\)\("logo_white_42": ".*\)\("logo_white_84": ".*\)\("availability": "available", \)\("level": ".*\)\("logo_token": ".*\)\("logo_black_42": ".*\)\(}.*\)/\1\4\8, \2\6\3\5\7\9/g' workfile
	sed -i '/"drm_required"/s/\("drm_required": true, \)\("logo_white_84": ".*\)\(}\], "recommendations": .*\)\(, "logo_black_84": ".*\)/\2\4\3},/g' workfile
	sed -i -e '/"drm_required"/s/"drm_required": true, //g' -e '/"recommendations"/s/, }, //g' -e '/"logo_token"/s/, },/},/g' workfile
	sed -i ':a $!N;s/\n"logo_white_84"/ "logo_white_84"/;ta P;D' workfile
	sed -i '/level/!d' workfile
	sed -i 's/}.*//g' workfile
	sed -i 's/"sharing".*"cid"/"cid"/g' workfile
	sed -i 's/"recording".*"logo_black_84": "/"logo_black_84": "http:\/\/images.zattic.com/g' workfile
	sed -i 's/"level".*"title"/"title"/g' workfile
	sed -i 's/, "logo_white_42".*//g' workfile
	sed -i -e 's/,//g' -e 's/.*/& /g' workfile
	sed -i 's/\("display_alias": ".*" \)\("cid": ".*" \)\("logo_black_84": ".*" \)\("title": ".*" \)/\2\3\4\1/g' workfile
	sed -i 's/"cid": "/#EXTINF:0001 tvg-id="/g' workfile
	sed -i 's/"logo_black_84": "/group-title="Zattoo" tvg-logo="/g' workfile
	sed -i 's/ "title": "/, /g' workfile
	sed -i 's/" "display_alias": "/\npipe:\/\/-USER-\/chpipe\//g' workfile
	sed -i -e 's/pipe:\/\/.*/&.sh/g' -e 's/" .sh/.sh/g' workfile
	sed -i '1i #EXTM3U' workfile
	
	cd ~/ztvh
	echo $PWD > work/userfolder
	sed -i 's/\//\\\//g' work/userfolder
	sed -i 's/.*/#\!\/bin\/bash\nsed -i "s\/-USER-\/&/g' work/userfolder
	sed -i '/sed/s/.*/&\/g" work\/workfile/g' work/userfolder
	bash work/userfolder
	
	cd work
	sed -i 's/\\u[a-z0-9][a-z0-9][a-z0-9][a-z0-9]/\[>\[&\]<\]/g' workfile
	ascii2uni -a U -q workfile > workfile2
	mv workfile2 workfile
	sed -i -e 's/\[>\[//g' -e 's/\]<\]//g' workfile
	mv workfile ~/ztvh/channels.m3u
	rm login.txt userfolder
	echo "- CHANNEL LIST CREATED! -" && echo ""
else
	echo "- ERROR: UNABLE TO FETCH CHANNEL LIST -" && echo ""
	rm ~/ztvh/channels.m3u powerid login.txt 2> /dev/null
	exit 0
fi


# ###############
# CHANNEL LOGOS #
# ###############

echo "--- ZATTOO CHANNEL LOGOS ---"

until grep -q -E "chlogo 0|chlogo 1" ~/ztvh/user/options 2> /dev/null
do
	echo "Do you want to download and update the channel logo images from Zattoo?"
	echo "[1] - Yes /// [0] - No"
	read -p "Number....: " -n1 logonum
	echo "chlogo $logonum" > ~/ztvh/user/options
	if grep -q -E "chlogo 0|chlogo 1" ~/ztvh/user/options 2> /dev/null
	then
		echo ""
	else
		echo "- ERROR: INVALID VALUE! -" && echo ""
	fi
done

if grep -q "chlogo 0" ~/ztvh/user/options 2> /dev/null
then
	sed -i 's/ tvg-logo=".*84x48.png"//g' ~/ztvh/channels.m3u
	echo "- LOGO GRABBER DISABLED! -" && echo ""
elif grep -q "chlogo 1" ~/ztvh/user/options 2> /dev/null
then 
	echo "Collecting/updating channel logo images..."
	mkdir ~/ztvh/logos 2> /dev/null
	sed 's/#EXTINF.*\(tvg-id=".*"\).*\(tvg-logo=".*"\).*/\2 \1/g' ~/ztvh/channels.m3u > workfile
	sed -i '/pipe/d' workfile
	sed -i 's/tvg-logo="/curl /g' workfile
	sed -i 's/" tvg-id="/ > ~\/ztvh\/logos\//g' workfile
	sed -i 's/" group.*/.png 2> \/dev\/null/g' workfile
	sed -i 's/#EXTM3U/#\!\/bin\/bash/g' workfile
	bash workfile
	sed -i 's/ group-title="Zattoo" tvg-logo=".*",/,/g' ~/ztvh/channels.m3u
	sed -i 's/tvg-id=".*"/& xyz&/g' ~/ztvh/channels.m3u
	sed -i 's/xyztvg-id="/tvg-logo="logos\//g' ~/ztvh/channels.m3u
	sed -i 's/", /.png" group-title="Zattoo", /g' ~/ztvh/channels.m3u
	chmod a+x ~/ztvh/logos/*
	echo "- CHANNEL LOGO IMAGES SAVED! -" && echo ""
	rm workfile
fi


# ##############
# PIPE STREAMS #
# ##############

until grep -q "chpipe [1-3]" ~/ztvh/user/options 2> /dev/null
do
	echo "Please choose the streaming quality you want to use."
	echo "[1] - LOW @ 600 kbit/s"
	echo "[2] - MEDIUM @ 1,5 Mbit/s"
	echo "[3] - MAXIMUM @ 3-5 Mbit/s"
	read -p "Number....: " -n1 pipenum
	echo "chpipe $pipenum" >> ~/ztvh/user/options
	if grep -q "chpipe [1-3]" ~/ztvh/user/options 2> /dev/null
	then
		echo ""
	else
		echo "- ERROR: INVALID VALUE! -" && echo ""
		sed -i 's/chpipe.*//g' ~/ztvh/user/options
		sed -i '/^\s*$/d' ~/ztvh/user/options
	fi
done

echo "Creating pipe scripts..."
mkdir ~/ztvh/chpipe 2> /dev/null
sed 's/#EXTM3U/#\!\/bin\/bash/g' ~/ztvh/channels.m3u > workfile
sed -i '/#EXTINF/{s/.*tvg-id="/ch_id=\$(echo "/g;s/" tvg-logo.*/")/g;s/" group-title.*/")/g;}' workfile
sed -i '/pipe:\/\//{s/.*chpipe\//sed "s\/CID_CHANNEL\/\$ch_id\/g" ~\/ztvh\/pipe.sh > ~\/ztvh\/chpipe\//g;}' workfile
bash workfile

if grep -q "chpipe 3" ~/ztvh/user/options
then
	sed -i '5s/# //g' ~/ztvh/chpipe/*
elif grep -q "chpipe 2" ~/ztvh/user/options
then
	sed -i '6s/# //g' ~/ztvh/chpipe/*
else
	sed -i '7s/# //g' ~/ztvh/chpipe/*
fi

chmod a+x ~/ztvh/chpipe/*
echo "- PIPE SCRIPTS CREATED! -" && echo ""
rm workfile


# ################
# EPG DATA       #
# ################

echo "--- ZATTOO EPG GRABBER ---"

until grep -q "epgdata [0-7]" ~/ztvh/user/options 2> /dev/null
do
	echo "Please enter the number of days you want to retrieve the EPG information."
	echo "[0] - DISABLE /// [1-7] - ENABLE"
	read -p "Number....: " -n1 epgnum
	echo "epgdata $epgnum" >> ~/ztvh/user/options
	if grep -q "epgdata [0-7]" ~/ztvh/user/options 2> /dev/null
	then
		echo ""
	else
		echo "- ERROR: INVALID VALUE! -" && echo ""
		sed -i 's/epgdata.*//g' ~/ztvh/user/options
		sed -i '/^\s*$/d' ~/ztvh/user/options
	fi
done

if grep -q "epgdata 0" ~/ztvh/user/options 2> /dev/null
then
	echo "- EPG GRABBER DISABLED! -" && echo "--- DONE ---" && exit 0
fi 

echo "Grabbing EPG data for $(sed '/epgdata/!d;s/epgdata //g;' ~/ztvh/user/options) day(s)!" && echo ""

mkdir ~/ztvh/epg 2> /dev/null


#
# Check if EPG collection process was interrupted
#

cd ~/ztvh
bash zguide_pc.sh
touch ~/ztvh/epg/stats


#
# Entering loop to keep EPG cache up to date
#

while [ -e ~/ztvh/epg/stats ]
do
	rm ~/ztvh/epg/stats
	cd ~/ztvh/work
	
	#
	# Cleanup EPG cache / delete old cache files
	#
	
	ls ~/ztvh/epg > epglist
	until sed '1!d' epglist | grep -q "$(date +%Y%m%d)"
	do
		if [ -s epglist ]
		then
			rm -rf ~/ztvh/epg/$(sed '1!d' epglist) 
			ls ~/ztvh/epg > epglist
		else
			echo "$(date +%Y%m%d)" > epglist
		fi
	done
	rm epglist


	#
	# Download EPG details
	#
	
	cd ~/ztvh
	bash zguide_dl.sh


	#
	# Collect EPG details
	#

	if ls ~/ztvh/epg | grep -q "datafile" 2> /dev/null
	then
		echo "Collecting EPG details..."
		echo "That may take a while..."	&& echo ""
	fi


	for i in {1..7..1}
	do
		bash epg/datafile_${i} 2> /dev/null &
	done
	wait


	# 
	# Check EPG cache for completeness
	#

	cd ~/ztvh
	bash zguide_fc.sh
	
	
	#
	# Repeat process: Keep manifest up to date
	#

	if [ -e ~/ztvh/epg/stats ]
	then
		echo "Checking for updates..."
	elif [ -e ~/ztvh/epg/stats2 ]
	then
		echo "No updates found!" && echo ""
		mv ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg.xml ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg_OLD.xml 2> /dev/null
	elif [ -e ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg.xml ]
	then
		echo "No updates found! EPG XMLTV file up to date!" && echo ""
		cp ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg.xml ~/ztvh/zattoo_fullepg.xml 2> /dev/null
		sort -u ~/ztvh/epg/status -o ~/ztvh/epg/status
		echo "--- DONE ---"
		exit 0
	fi
done
echo "- EPG FILES COLLECTED SUCCESSFULLY! -" && echo ""
rm ~/ztvh/epg/stats2 2> /dev/null


# 
# Sum up epg details
#

echo "Creating EPG XMLTV file..."
echo "That may take a while..." && echo ""

echo "Merging collected EPG details to a single EPG file..."

bash ~/ztvh/zguide_su.sh


#
# Create EPG XMLTV files
#

cd ~/ztvh/epg
bash ~/ztvh/zguide_xmltv.sh


#
# Validate xml file
#

echo "Validating EPG XMLTV file..."

if xmllint --noout ~/ztvh/epg/$(date +%Y%m%d)_zattoo_fullepg.xml | grep -q "parser error" 2> ~/ztvh/errorlog
then
	echo "- ERROR: XMLTV FILE VALIDATION FAILED! -"
else
	echo "- XMLTV FILE VALIDATION SUCCEEDED! -" && echo ""
	rm ~/ztvh/errorlog
fi

# #####################
# CLEAN UP WORKFOLDER #
# #####################

cd ~/ztvh/work
rm workfile* powerid 2> /dev/null
rm ~/ztvh/epg/stats2 2> /dev/null
sort -u ~/ztvh/epg/status -o ~/ztvh/epg/status

echo "--- DONE ---"