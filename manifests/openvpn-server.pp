# This creates client certificates in the OpenVPN SSL directory.
class client-package ($username) {

	exec { "genkey-client-$username":
		creates => "/etc/openvpn/clients/$username.key",
		require => File["/etc/openvpn/clients"],
		command => "/usr/bin/openssl genrsa -out /etc/openvpn/clients/$username.key 2048"
	}

	file { "/etc/openvpn/clients/$username.csr.cnf":
		require => File["/etc/openvpn/clients"],
		ensure => present,
		content => template("/home/ubuntu/puppet-vpnserver/templates/conf/openssl/client.conf")
	}

	exec { "gencsr-client-$username":
		creates => "/etc/openvpn/clients/$username.csr",
		require => File["/etc/openvpn/clients/$username.csr.cnf"],
		command => "/usr/bin/openssl req -config /etc/openvpn/clients/$username.csr.cnf -new -key /etc/openvpn/clients/$username.key -out /etc/openvpn/clients/$username.csr"
	}

	exec { "sign-client-$username":
		creates => "/etc/openvpn/clients/$username.pem",
		require => [
			File["/etc/openvpn/clients/$username.csr.cnf"],
			Exec["gencsr-client-$username"],
			Exec["createca"]
		],
		command => "/usr/bin/openssl ca -batch -config /etc/puppetca/openssl.cnf -in /etc/openvpn/clients/$username.csr -out /etc/openvpn/clients/$username.pem"
	}

	file { "/etc/openvpn/clients/$username.ovpn":
		require => File["/etc/openvpn/clients"],
		ensure => present,
		content => template("/home/ubuntu/puppet-vpnserver/templates/conf/openvpn/client.conf")
	}

}


class openvpn-server {

	package { "openvpn": ensure => installed }
	package { "bridge-utils": ensure => installed }

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

	file { "/etc/openvpn/up.sh":
		ensure => present,
		source => "/home/ubuntu/puppet-vpnserver/files/conf/openvpn/up.sh"
	}

	file { "/etc/openvpn/down.sh":
		ensure => present,
		source => "/home/ubuntu/puppet-vpnserver/files/conf/openvpn/down.sh"
	}

	exec { "create-dh":
		creates => "/etc/openvpn/dh1024.pem",
		command => "/usr/bin/openssl dhparam -out /etc/openvpn/dh1024.pem 1024"
	}

	file { "/etc/openvpn/clients":
		ensure => directory,
		require => File["/etc/openvpn"]
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
		source => "/home/ubuntu/puppet-vpnserver/files/conf/openssl/my.conf",
		require => File["/etc/puppetca"]
	}

	file { "/etc/puppetca/openvpn.cnf":
		ensure => present,
		owner => root,
		group => root,
		mode => 600,
		source => "/home/ubuntu/puppet-vpnserver/files/conf/openssl/openvpn.conf",
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
		content => template("/home/ubuntu/puppet-vpnserver/templates/conf/openvpn/server.conf")
	}

	file { "/etc/network/interfaces":
		ensure => present,
		source => "/home/ubuntu/puppet-vpnserver/files/conf/network/interfaces"
	}

	exec { "network-restart":
		command => "/etc/init.d/networking restart",
		refreshonly => true,
		subscribe => File["/etc/network/interfaces"]
	}

	exec { "gen-ta-key":
		command => "/usr/sbin/openvpn --genkey --secret /etc/openvpn/ta.key",
		creates => "/etc/openvpn/ta.key",
		require => Package["openvpn"]
	}

	service { "openvpn":
		enable => true,
		ensure => running,
		require => [
			Exec["create-dh"],
			Exec["gen-ta-key"],
			File["/etc/openvpn/server.conf"]
		],
		subscribe => [
			File["/etc/openvpn/server.conf"]
		]
	}

}

class { "openvpn-server": }
class { "client-package": username => "client1" }

