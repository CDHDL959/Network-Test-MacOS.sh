# Network-Test-MacOS.sh
MacOS zsh script that allows users to choose specific network tests (ping multiple IPs, get current IP, scan current network, a network quality test, TCP dump, and check open TCP ports). 

In more detail, this script is a series of functions that will perform the following:
* **menu()**: a while True loop, displaying options and reading user input. After each option is selected, the script will continually loop until the user explcity chooses to exit (7).
* **ping_IP()**: check if at least one IP was entered. If that is met, it will loop through the IPs and ping them. Made sure to limit it to 4 pings.
* **get_IP()**: extracting ip addr and filtering the loopback address. Then, it will pull public IP via DNS lookup (not using curl/wget).
* **scan_Network()**: obtains IP address from interface en0 (Wi-Fi) or en1 (Ethernet), extracts first 3 octets to get our subnet. Then, it will loop through all possible host address (1-254) and send one ping packet to each IP. It has a maximum wait time of 5 seconds. All pings will be run in parallel (the & at the end). This is limited since it assumes /24 subnet, only finds devices that repsond to ping, and is MacOS specific.
* **test_NetworkQ()**: will output in a clean format the results of Apple's proprietary NetworkQuality -verbose tool. Will select specific lines and output Download Speed, Upliad Speed, and Responsiveness underload.
* **dump_TCP()**: lists all network interfaces on macOS and prompts the user to select one. Runs tcpdump with root privilges. Additionally, allows users to filter via ports capture all traffic to a specific IP.
* **check_Ports()**: checks TCP listening ports via sudo lsof -iTCP -sTCP:LISTEN. Will list port number rather than something unrecognizible. Does not check UDP. Also has a macOS version and a linux version of netstat. 
