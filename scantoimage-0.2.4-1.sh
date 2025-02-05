#! /bin/bash
set +o noclobber
#
#   $1 = scanner device
#   $2 = friendly name
#

#   
#       100,200,300,400,600
#
# query device with scanimage -h to get allowed resolutions
# in color resolution more than 300 slows things down
resolution=300
# leave height and width uncommented to autodetect
#height=114
#width=160
compress_format="png"

function Usage() {
    echo -e "Usage:"
    echo -e "\t scantoimage.sh <devicename>\n"
    echo -e "The devicename is optional."
    echo -e "Check the source for options. Will write a png file in a default directory after scanning."
    echo -e "Heights and width can be specified in the script. So can compression format, resolution."
}

# parse one simple option. Allows you to get help
while getopts "h" opt; do
    case "$opt" in
        h)
            Usage
            exit 0
            ;;
    esac
done

# set color to full color or 24 bit. 
mode='"24Bit Color"'
#mode='"Black & White"'

# LOGFILE
scriptname=$(basename "$0")
# $0 refers to the script name
basedir=$(readlink -f "$0" | xargs dirname)

# change to directory of script
cd ${basedir}
echo "basedir = $basedir" 

# ugly hack that makes environment variables set available
cfgfile=$(ls ../brscan-skey-*.cfg)
echo "cfgfile = $cfgfile"
if [[ -r "$cfgfile" ]]; then
    echo "Found cfgfile"
    source "$cfgfile"
    echo "environment after processing cfgfile"
    env
fi


# SAVETO DIRECTORY
if [[ -z "$SAVETO" ]];  then
    SAVETO=${HOME}'/brscan/photos'
else
    SAVETO=${SAVETO}'/photos/'
fi

mkdir -p $SAVETO

if [[ -z $LOGDIR ]]; then
    # if LOGDIR is not set, choose a default
    mkdir -p ${HOME}/brscan
    logfile=${HOME}"/brscan/$scriptname.log"
else
    mkdir -p $LOGDIR
    logfile=${LOGDIR}"/$scriptname.log"
fi
touch ${logfile}

if [ -z "$1" ]; then
    device='brother4:net1;dev0'
else
    device=$1
fi

# in scantofile the widht and height are automatically set. Here, they're not.

if [ "`which usleep  2>/dev/null `" != '' ];then
    usleep 100000
else
    sleep  0.1
fi
output_file=${SAVETO}"/brscan_photo_`date +%Y-%m-%d-%H-%M-%S`.pnm"

#echo "scan from $2($device) to $output_file"

# options
if [[ -z "$height" || -z "$width" ]]; then
    SCANOPTIONS="--mode $mode --device-name \"$device\" --resolution $resolution"
else
    SCANOPTIONS="--mode $mode --device-name \"$device\" --resolution $resolution -x $width -y $height"
fi

# echo the command to stdout. Then write it to logfile.
echo "scanimage $SCANOPTIONS > $output_file"
echo "scanimage $SCANOPTIONS > $output_file" >> $logfile 
echo "scanimage $SCANOPTIONS > $output_file" 2>> $logfile | bash

umask 000

#scanimage --verbose $SCANOPTIONS > $output_file 2>/dev/null

# if the file is zero size, run again.
if [ ! -s $output_file ];then
  if [ "`which usleep  2>/dev/null `" != '' ];then
    usleep 1000000
  else
    sleep  1
  fi
  echo "Rerunning scanimage $SCANOPTIONS"
  scanimage $SCANOPTIONS > $output_file 2>/dev/null

fi
#echo gimp -n $output_file  2>/dev/null \;rm -f $output_file | sh & 

if [ -s $output_file ]; then
    echo  $output_file is created.

    # Should convert to jpg and delete duplicates
    output_file_compressed=$(dirname $output_file)"/"$(basename $output_file .pnm)".$compress_format"
    echo convert -trim -bordercolor White -border 20x10 +repage -quality 95 -density "$resolution" $output_file "$output_file_compressed" 
    echo convert -trim -quality 95 -density "$resolution" $output_file "$output_file_compressed" >> $logfile
    echo convert -trim -quality 95 -density "$resolution" "$output_file" "$output_file_compressed" | bash
fi
