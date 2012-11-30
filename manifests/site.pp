node default {
}

class openvpn-server {

	package { "openvpn": 
		ensure => installed
	}

}

