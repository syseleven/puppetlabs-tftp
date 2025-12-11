# @summary tftp
#
#
# @param username tftp service username.
# @param directory tftp service file directory.
# @param address tftp service bind address (default 0.0.0.0).
# @param port tftp service bind port (default 69).
# @param options tftp service bind port (default 69).
# @param inetd Run as an xinetd service instead of standalone daemon (false)
# @param package tftp server package name.
# @param binary tftp server binary path.
# @param defaults Manage /etc/default/tftpd-hpa file (Debian/Ubuntu
# Requires:
#
#   Class['xinetd']  (if inetd set to true)
#
# Usage:
#
#   class { 'tftp':
#     directory => '/opt/tftp',
#     address   => $facts['networking']['ip'],
#     options   => '--ipv6 --timeout 60',
#   }
#
class tftp (
  String                        $username  = $tftp::params::username,
  Stdlib::Absolutepath          $directory = $tftp::params::directory,
  String                        $address   = $tftp::params::address,
  Variant[Stdlib::Port, String] $port      = $tftp::params::port,
  String                        $options   = $tftp::params::options,
  Boolean                       $inetd     = $tftp::params::inetd,
  String                        $package   = $tftp::params::package,
  Stdlib::Absolutepath          $binary    = $tftp::params::binary,
  Boolean                       $defaults  = $tftp::params::defaults,
) inherits tftp::params {
  $virtual_package = 'tftpd-hpa'

  package { $virtual_package:
    ensure => present,
    name   => $package,
  }

  if $defaults {
    file { '/etc/default/tftpd-hpa':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('tftp/tftpd-hpa.erb'),
      require => Package[$virtual_package],
      notify  => Service['tftpd-hpa'],
    }
  }

  if $inetd {
    include 'xinetd'

    xinetd::service { 'tftp':
      port        => $port,
      protocol    => 'udp',
      server_args => "${options} -u ${username} ${directory}",
      server      => $binary,
      bind        => $address,
      socket_type => 'dgram',
      cps         => '100 2',
      flags       => 'IPv4',
      per_source  => '11',
      wait        => 'yes',
      require     => Package[$virtual_package],
    }

    $svc_ensure = stopped
    $svc_enable = false
  } else {
    $svc_ensure = running
    $svc_enable = true
  }

  $start = $tftp::params::provider ? {
    'base'  => "${binary} -l -a ${address}:${port} -u ${username} ${options} ${directory}",
    default => undef
  }

  service { 'tftpd-hpa':
    ensure    => $svc_ensure,
    enable    => $svc_enable,
    provider  => $tftp::params::provider,
    hasstatus => $tftp::params::hasstatus,
    pattern   => '/usr/sbin/in.tftpd',
    start     => $start,
  }
}
