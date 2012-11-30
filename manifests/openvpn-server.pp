class openvpn-server {

	package { "openvpn": 
		ensure => installed
	}

}

class { "openvpn-server": }

