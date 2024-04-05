# Update NetAssist IPv6 Tunnel Client IPv4 address
# This is an upgrade to an existing script from
# http://wiki.mikrotik.com/wiki/Hurricane_Electric_IPv6_Tunnel_-_IPv4_Endpoint_updater
# API call format:
# https://tb.netassist.ua/autochangeip.php?l=YOURLOGIN&p=YOURPASSWORD&ip=YOURIP
# ----------------------------------
# Modify the following to match your parameters
# ----------------------------------


# Router's WAN interface name
:local WANinterface "FTTH-TCT"

# Router's 6to4 interface name
:local NAtunnelinterface "sit1"

# Your username - you use it to log in at https://tb.netassist.ua
:local NAuserid "username"

# Your password - you use it to log in at https://tb.netassist.ua
:local NApassword "password"

# ----------------------------------
# STOP modifying here
# ----------------------------------
# Internal processing below...
# ----------------------------------
:local NAupdatehost "tb.netassist.ua"
:local NAupdatepath "/autochangeip.php"
:local outputfile ("NA-" . $NAtunnelinterface . ".txt")
:local NAipv4addr

# Get WAN interface IP address
:set NAipv4addr [/ip address get [/ip address find interface=$WANinterface] address]
:set NAipv4addr [:pick [:tostr $NAipv4addr] 0 [:find [:tostr $NAipv4addr] "/"]]

:if ([:len $NAipv4addr] = 0) do={
   :log error ("Could not get IP for interface " . $WANinterface)
   :error ("Could not get IP for interface " . $WANinterface)
}

# Update the NAtunnelinterface with WAN IP
/interface 6to4 {
    :if ([get ($NAtunnelinterface) local-address] != $NAipv4addr) do={
        :log info ("Updating IPv6 Tunnel " . $NAtunnelinterface  . " Client IPv4 address to new IP " . $NAipv4addr . "...")
        disable $NAtunnelinterface

        
        /tool fetch mode=https host=($NAupdatehost) url=("https://" . $NAupdatehost . $NAupdatepath . "?l=" . $NAuserid . "&p=" . $NApassword . "&ip=" . $NAipv4addr) dst-path=($outputfile)
        # Change the client IPv4 address
        set ($NAtunnelinterface) local-address=$NAipv4addr

        # I like to make a little pause before enabling the interface
        /delay 3
        
        # Enable the IPv6 interface
        enable $NAtunnelinterface 

        # Append the file to log for review
        :log info ([/file get ($outputfile) contents])
        
        # Clean up after ourselves
        /file remove ($outputfile)
        
    } else={
        # If client's IPv4 didn't change at all, put it in the log so that we know the script is working
        :log info ("Updating " . $NAtunnelinterface . " No change, IP is still " . $NAipv4addr )
    }   
}