class openvpn-server {

	package { "openvpn": 
		ensure => installed
	}

	file { "/etc/openvpn/ssl":
		ensure => directory,
		owner => root,
		group => root,
		mode => 700,
		require => [ 
			Package["openvpn"],
			File["/etc/openvpn"]
		]
	}

	file { "/etc/openvpn":
		ensure => directory,
                owner => root,
                group => root,
                mode => 700,
	}

	file { "/etc/puppetca":
		ensure => directory,
		owner => root,
		group => root,
		mode => 700,
		require => Package["openvpn"]
	}

	file { "/etc/puppetca/index.txt":
		ensure => present
	}

	file { "/etc/puppetca/serial":
		ensure => present,
		content => "01\n",
		replace => "false"
	}

	file { "/etc/puppetca/certs": 
		ensure => directory,
		require => File["/etc/puppetca"]
	}

	file { "/etc/puppetca/private":
		ensure => directory,
		require => File["/etc/puppetca"]
	}

	file { "/etc/puppetca/openssl.cnf":
		ensure => present,
		owner => root,
		group => root,
		mode => 600,
		source => "/home/ubuntu/puppet/files/conf/openssl/my.conf",
		require => File["/etc/puppetca"]
	}

	file { "/etc/puppetca/openvpn.cnf":
		ensure => present,
		owner => root,
		group => root,
		mode => 600,
		source => "/home/ubuntu/puppet/files/conf/openssl/openvpn.conf",
		require => File["/etc/puppetca"]
	}

	exec { "createca":
		creates => "/etc/puppetca/certs/ca.pem",
		require => [
			File["/etc/puppetca/openssl.cnf"],
			File["/etc/puppetca/certs"],
			File["/etc/puppetca/private"]
		],
		command => "/usr/bin/openssl req -config /etc/puppetca/openssl.cnf -x509 -nodes -days 30 -newkey rsa:2048 -out /etc/puppetca/certs/ca.pem -outform PEM -keyout /etc/puppetca/private/ca.key"
	}

	file { "/etc/puppetca/certs/ca.pem": }

	exec { "vpn-key":
		creates => "/etc/openvpn/ssl/server.key",
		require => File["/etc/openvpn/ssl"],
		command => "/usr/bin/openssl genrsa -out /etc/openvpn/ssl/server.key 2048"
	}

	exec { "vpn-csr":
		creates => "/etc/openvpn/ssl/server.csr",
		require => File["/etc/openvpn/ssl/server.key"],
		command => "/usr/bin/openssl req -config /etc/puppetca/openvpn.cnf -new -key /etc/openvpn/ssl/server.key -out /etc/openvpn/ssl/server.csr"
	}

	file { "/etc/openvpn/ssl/server.key":
		owner => root,
		group => root,
		mode => 600
	}

	exec { "vpn-sign":
		creates => "/etc/openvpn/ssl/server.pem",
		require => [
			File["/etc/openvpn/ssl/server.key"],
			File["/etc/puppetca/openssl.cnf"],
			File["/etc/puppetca/index.txt"],
			File["/etc/puppetca/serial"],
			File["/etc/puppetca/certs/ca.pem"],
			Exec["createca"]
		],
		command => "/usr/bin/openssl ca -batch -config /etc/puppetca/openssl.cnf -in /etc/openvpn/ssl/server.csr -out /etc/openvpn/ssl/server.pem"
	}

	file { "/etc/openvpn/ssl/server.pem": }

	file { "/etc/openvpn/server.conf":
		ensure => present,
		require => [ 
			File["/etc/puppetca/certs/ca.pem"],
			Package["openvpn"]
		],
		content => template("/home/ubuntu/puppet/templates/conf/openvpn/server.conf")
	}
}

class { "openvpn-server": }

