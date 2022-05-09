while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -u|--username)
    username="$2"
    shift # past argument
    ;;
esac
shift # past argument or value
done

sudo kill -9 $(sudo lsof -t -i:8897)
localPort=8897
browser=brave-browser #google-chrome
serverIP=146.83.176.249

#######################################################################
# 1. Run juypter in remote server
# only run jupyter if it isn't already running
out=$(ssh -T ${username}@${serverIP} <<HERE
    if [ \$(ps -u ${username} | grep jupyter | wc -l) -eq 0 ]
    then
	if [ ! -d jupyter ]; then mkdir jupyter; fi
        cd jupyter
        echo "module load python/3.8.3" > jupyter.sh
	echo "jupyter notebook --no-browser --NotebookApp.token=${username}" >> jupyter.sh 
        screen -S jupyter -d -m bash jupyter.sh
    fi
    # Get remote port number. If there is more than 1, get the first
    jupyter notebook list | grep localhost | awk '{split(\$0,a,"localhost:");split(a[2],b,"/"); print b[1]}' | head -n1
HERE
)
# get remote port
remotePort=$(echo $out | awk '{print $NF}') 

# 2. Star listening the remote port on local port 
# only start listening if port isn't already in use
# num equals 1 if port number is already in use, 0 otherwise
num=$(netstat -lnt | awk -v y=$localPort"$" 'BEGIN{x=0} ($6 == "LISTEN" && $4 ~ y){x=1}END{print x}')

#while [ $num -eq 0 ]
if [ $num -eq 0 ]
then
#    num=$(netstat -lnt | awk -v y=$localPort"$" 'BEGIN{x=0} ($6 == "LISTEN" && $4 ~ y){x=1}END{print x}')
    ssh -f ${username}@${serverIP} -L ${localPort}:localhost:${remotePort} -N
fi

# 3. Open jupyter in browser
${browser} http://localhost:${localPort}/tree?token=${username} &

