# Diagnose Internet and BGP connection

# Print an empty line for spacing
:put ""; 

# Print the system identity name
:put [/system identity get name]; 

# Get and print the current time and date
:local time [system clock get time]; 
:local date [system clock get date]; 
:put ("$date $time"); 

# Print the router model
:put ("Mikrotik " . [/system routerboard get model]); 

# Check the status of ethernet interfaces
:local ether1Status [interface ethernet get ether1 running]; 
:local ether2Status [interface ethernet get ether2 running]; 
:if (($ether1Status = false) and ($ether2Status = false)) do={
    :terminal style varname; 
    :put "No ISP Link"; 
    :terminal style none;
} else={
    :put "Link is OK";
}; 

# Get and print the WAN MAC address
:do {
    :local wanMac [/interface ethernet get [find where name=[/interface list member get [find where interface~"ether" and list~"WAN"] interface]] mac-address]; 
    :put "Mac-address is $wanMac";
} on-error={
    :terminal style varname; 
    :put "Unable to get mac-address"; 
    :terminal style none;
}; 

# Determine service type and ISP IP
:local serviceType "Internet"; 
:local ispIp ""; 
:do { 
    :set $ispIp [/interface gre get toMiran local-address];
} on-error={ 
    :set $ispIp [/interface gre get toMiranVPN local-address]; 
    :if ($ispIp~"172.2") do={
        :set $serviceType "VPN"
    }
}; 
:put "Service type is $serviceType"; 
:put "ISP IP-address is $ispIp"; 

# Get the Miran IP address
:local miranIP ""; 
:do { 
    :set $miranIP [/interface gre get toMiran remote-address];
} on-error={ 
    :set $miranIP [/interface gre get toMiranVPN remote-address];
}; 

# Determine and print the ISP gateway
:local ispGateway ""; 
:if ($serviceType~"Internet") do={
    :set $ispGateway [:tostr [/ip route get [find where dst-address~"$miranIP"] gateway]]; 
    :if ($ispGateway~"-") do={ 
        :put "It's $ispGateway as a gateway"; 
        :if ([interface get [find where name~"$ispGateway"] running]=true) do={
            :put "$ispGateway is up"
        } else={
            :terminal style varname; 
            :put "$ispGateway is down"; 
            :terminal style none;
        };
    } else={
        :put "ISP Gateway is $ispGateway"
    };
} else={
    :set $ispGateway ($ispIp-1); 
    :put "ISP Gateway is $ispGateway";
}; 

# Print default gateway and its distance
:local defGateway [/ip route get [find where dst-address=0.0.0.0/0 and active=yes] gateway-status]; 
:local defGatewayDist [/ip route get [find where dst-address=0.0.0.0/0 and active=yes] distance]; 
:if ($defGateway~"Miran") do={
    :put "Default active gateway is $defGateway";
} else={
    :terminal style varname; 
    :put "Default active gateway is $defGateway"; 
    :terminal style none;
};
:put "Default active gateway distance is $defGatewayDist"; 

# Check BGP peer states
:do {
    :put ("BR1 peer is " . [/routing bgp peer get BR1 state])
} on-error={
    :terminal style varname; 
    :put "No BR1 peer"; 
    :terminal style none;
}; 
:do {
    :put ("BR2 peer is " . [/routing bgp peer get BR2 state])
} on-error={
    :terminal style varname; 
    :put "No BR2 peer"; 
    :terminal style none;
}; 

# Ping ISP Gateway and Miran IP and print the status
:put ""; 
:if (!($ispGateway~"-")) do={
    :local pingIspGateway [/ping $ispGateway count=5]; 
    :if ($pingIspGateway != 0) do= {
        :put "ISP Gateway $ispGateway is reachable";
    } else={
        :terminal style varname; 
        :put "ISP Gateway $ispGateway is unreachable"; 
        :terminal style none;
    };
}; 
:put ""; 
:put ""; 
:local pingMiranIP [/ping $miranIP count=5]; 
:if ($pingMiranIP != 0) do= {
    :put "Miran IP $miranIP is reachable";
} else={
    :terminal style varname; 
    :put "Miran IP $miranIP is unreachable"; 
    :terminal style none;
}; 

# Print an empty line for spacing
:put "";
