#!/bin/bash

if [[ -z "${SKIP_SLEEP+x}" ]]; then
  sleep 900
fi

torrentid=$1
torrentname=$2
torrentpath=$3

tmpdir=$(/usr/bin/mktemp -d)

##############################################################
# Define these vars to the path where they are located
##############################################################
dc=/usr/bin/deluge-console
deluge_state_dir=/home/woodsdog/.config/deluge/state
rtfr=/home/woodsdog/bin/rtorrent_fast_resume.pl
rtxmlrpc=/home/woodsdog/bin/rtxmlrpc
torrent_download_dir=/home/woodsdog/torrents/downloads
xmlrpc=/usr/bin/xmlrpc
xmlrpc_endpoint=127.0.0.1
xmlrpc_command="${xmlrpc} ${xmlrpc_endpoint}"
##############################################################


function on_exit() {
    rm -rf "${tmpdir}"
}

#trap on_exit EXIT

function set_tracker {
  case $1 in
    *alpharatio*)
   	  tracker=ar
      ;;
    *empire*|*stackoverflow*|*iptorrent*)
   	  tracker=ipt
      ;;
    *torrentleech*)
   	  tracker=tl
      ;;
   	*)
   	  tracker=$1
	  ;;
  esac
}

tracker_line=$($dc info $torrentid | grep "^Tracker" | awk -F: '{print $2}' | tr -d " ")
set_tracker $tracker_line
ratio=$($dc info $torrentid | grep Ratio: | awk -F "Ratio: " '{print $2}')

#echo $tracker
#echo $ratio
#echo $ratio_rounded_down

cp ${deluge_state_dir}/${torrentid}.torrent ${tmpdir}

$rtfr $torrent_download_dir ${deluge_state_dir}/${torrentid}.torrent ${tmpdir}/${torrentid}_fast.torrent
if [[ $? -ne 0 ]]; then
  echo "Something went wrong when converting the torrent file with $(basename ${rtfr})"
  echo "exiting..."
  exit 10
fi

# remove the torrent from deluge
$dc rm $torrentid

#$rtxmlrpc load_start ${tmpdir}/${torrentid}_fast.torrent
#sleep 3
#$rtxmlrpc d.set_custom1 ${torrentid} ${tracker}
#$rtxmlrpc d.set_custom ${torrentid} deluge_ratio ${ratio}

$xmlrpc_command load_start ${tmpdir}/${torrentid}_fast.torrent
sleep 3
$xmlrpc_command d.set_custom1 ${torrentid} ${tracker}
$xmlrpc_command d.set_custom ${torrentid} deluge_ratio ${ratio}

/usr/bin/rm -rf $tmpdir
