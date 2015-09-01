# Puppet VPN Server Configuration

This is a quick and dirty Ubuntu-compatible Puppet manifest that will configure
an OpenVPN server and bundle up a client configuration package. I have only
tested this with AWS instances (namely to play Steam games earlier than the
intended release time like the gigantic nerd that I am).

## Using the manifest

Install the pre-requisites "git" and "puppet", then clone the repo in the main
ubuntu user's directory. Additionally make sure the AWS security group allows
UDP traffic on port 1194.

Run the puppet manifest like so:

```shell
sudo puppet apply manifests/openvpn-server.pp
```

This will generate CA, keys and so forth for the server. Now grab the client
configuration files from "/etc/openvpn/clients" and install them on the actual
client computer. That theoretically should be it.
