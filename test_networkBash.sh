#!/bin/bash

# Menu that lets me select (1) Ping IP Address(es); (2) Get current IP Address; (3) Scan the Network;
# (4) Test Network Quality; (5) TCP Dump; (6) Check Open Ports; and (7) EXIT

# Each selection will have a function to conduct, like TCP Dump or Check Open TCP Ports

# After each option, the user will hit enter/return to go back to the menu

# Choice 5 takes WAY TOO LONG
    # I implemented a desired duration input
    # but, the output gets screwed up with the "Press Enter to return to the menu"

# fixed choice 4 and the output not lining up with the desired catagories

menu() {
    
    while true; do

        echo "-------------------------"
        echo "===== Options Below ====="
        echo "-------------------------"
        echo "(1) Ping IP Address(es)"
        echo "(2) Get Current IP Address"
        echo "(3) Scan Current Network"
        echo "(4) Network Quality Test"
        echo "(5) TCP Dump"
        echo "(6) Check Open TCP Ports"
        echo "(7) Exit"
        echo "========================="
        read -p "Choose an option: " choice
        echo

        case "$choice" in
            1) ping_IP ;;
            2) get_IP ;;
            3) scan_Network ;;
            4) test_NetworkQ ;;
            5) dump_TCP ;;
            6) check_Ports ;;
            7)
                echo "Exiting... Goodbye!"
                break
                ;;
            *)
                echo "*****************************"
                echo "Invalid Selection. Try Again"
                echo "*****************************"
                ;;
        esac

        echo
        read -p "Press Enter to Return to the menu..."
    done

}

ping_IP() {
    read -p "Enter one or more IP Addresses (separated by spaces): " -a ips

    # check if at least one IP was entered
    if [ ${#ips[@]} -eq 0 ]; then
        echo "******************"
        echo "< No IPs Entered >"
        echo "******************"
        return 1
    fi

    # now loop through the user's IPs and ping them
    for ip in "${ips[@]}"; do
        echo
        echo "Pinging $ip ..."
        echo
        ping -c 4 "$ip"
        echo "-------------------------"
    done

}

get_IP() {
    # extracting ip addr and filtering the loopback address
    echo "Local IP Address(es): "
    ip -4 addr show | awk '/inet/ && $2 !~ /^127/ {print "  _ " $2}' | cut -d/ -f1

    echo ""

    #pulling public IP via DNS lookup (not using curl/wget)
    echo " Public IP Address(es): "
    public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)
    if [ -n "$public_ip" ]; then
        echo "  - $public_ip"
    else
        echo "  - Unable to detect (network may block external queries)"
    fi

}

scan_Network() {
    # obtain local network subnet (e.g. 192.168.1) Assumes a /24 subnet
    subnet=$(ipconfig getifaddr en0 | awk -F. '{print $1"."$2"."$3}')

    if [ -z "$subnet" ]; then
        subnet=$(ipconfig getifaddr en1 | awk -F. '{print $1"."$2"."$3}')
    fi

    if [ -z "$subnet" ]; then
        echo "Unable to determine network subnet."
        return 1
    fi

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Scanning network ${subnet}.0/24 ..."
    echo "This may take ~10 seconds"
    echo

    # will loop through all possible (1-254) and ping each once. Will only wait 5 seconds
    # pings are run in parallel (& at the end)
    for i in {1..254}; do
        ping -c 1 -W 5 "${subnet}.${i}" > /dev/null 2>$1 &
    done
    wait

    # arp -a will show ARP cache (which devices repsonded)
    # lists IP addresses, MAC addresses, and hostnames of active devices
    echo 
    echo "Active Devices Found:"
    echo "---------------------"
    arp -a

}

test_NetworkQ() {
    # this will be a pretty output, extracting specific things from networkQuality -verbose
    # executes macOS's built-in networkQuality tool -verbose
    # captures both stdout and stderr (2>&1)
    # searches for specific lines and extracts the values
    # example, $3, $4 pring 3rd and 4th words, which are the speed value and unit like "150 Mbps"
    # displays in a clean output instead of verbose raw output
    echo
    echo "Running macOS Network Quality Test..."
    echo "--------------------------------------"

    result=$(networkQuality -v 2>&1)

    summary=$(echo "$result" | awk '/==== SUMMARY ====/,0')
    
    upload=$(echo "$summary" | awk '/Uplink capacity:/ {print $3, $4}')
    download=$(echo "$summary" | awk '/Downlink capacity:/ {print $3, $4}')
    responsiveness=$(echo "$summary" | awk '/^Responsiveness:/ {print $2, $3, $4, $5, $6, $7}')

    # Download Speed, Upload Speed, and Responsiveness
    # responsiveness is netowkr latency under load using apple's proprietary metric, similar to bufferbloat testing
    echo "Download:       $download"
    echo "Upload:         $upload"
    echo "Responsiveness: $responsiveness"
    echo "--------------------------------------"

}

dump_TCP() {
    # will list all network interfaces on MacOS, prompting the user to choose one
    # runs tcpdump with root privileges and stops easily with a ctrl + c
    # also allowing user to filter via ports or capture all traffic to a specific IP

    echo "___________________"
    echo
    echo "TCP Dump Interface:"
    networksetup -listallhardwareports | awk '/Device/ {print "  -", $2}'

    read -p "Enter interface to capture on (e.g. en0): " iface
    read -p "Option filter (e.g. 'Port 80' or '192.168.1.50 or press Enter for none): " filter
    read -p "Capture duration in seconds (or press Enter for unlimited): " duration
    
    echo "Starting tcpdump on $iface ..."
    echo "Press CTRL+C to STOP"
    echo "----------------------------------"

    if [[ -n "$duration" ]]; then
        # Start tcpdump in background with timeout
        if [[ -z "$filter" ]]; then
            sudo tcpdump -i "$iface" &
        else
            sudo tcpdump -i "$iface" $filter &
        fi
        
        tcpdump_pid=$!
        sleep "$duration"
        sudo kill $tcpdump_pid 2>/dev/null
        echo
        echo "Capture completed after $duration seconds."
    else
        # No timeout - run normally
        if [[ -z "$filter" ]]; then
            sudo tcpdump -i "$iface"
        else
            sudo tcpdump -i "$iface" $filter
        fi
    fi
}

check_Ports() {
    # use this command to check TCP listening ports: sudo lsof -iTCP -sTCP:LISTEN
    # this will just list port number rather than changing it to a weird name. 
    # also just for TCP; not UDP

    echo 
    echo "Checking Listening TCP Ports..."
    echo "---------------------------------"

    if command -v lsof >/dev/null 2>&1; then
        #macOS version
        sudo lsof -nP -iTCP -sTCP:LISTEN
    else
        #linux version of netstat
        if command -v ss >/dev/null 2>&1; then
            ss -tln
        else
            netstat -tln
        fi
    fi
    
}

menu
