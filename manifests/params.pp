# @summary
#
class tftp::params {
  $address    = '0.0.0.0'
  $port       = '69'
  $options    = '--secure'
  $binary     = '/usr/sbin/in.tftpd'
  $inetd      = true

  case $facts['os']['family'] {
    'Debian': {
      $package  = 'tftpd-hpa'
      $defaults = true
      $username = 'tftp'
      case $facts['os']['name'] {
        'Debian': {
          $directory  = '/srv/tftp'
          $hasstatus  = false
          $provider   = undef
        }
        'Ubuntu': {
          # ubuntu now uses systemd
          if versioncmp($facts['os']['release']['full'], '15.04') >= 0 {
            $provider = 'systemd'
          } else {
            $provider   = 'upstart'
          }
          $directory  = '/var/lib/tftpboot'
          $hasstatus  = true
        }
        default: {
          fail "${$facts['os']['name']} is not supported"
        }
      }
    }
    'RedHat': {
      $package    = 'tftp-server'
      $username   = 'nobody'
      $defaults   = false
      $directory  = '/var/lib/tftpboot'
      $hasstatus  = false
      $provider   = 'base'
    }
    default: {
      $package    = 'tftpd'
      $username   = 'nobody'
      $defaults   = false
      $hasstatus  = false
      $provider   = undef
      warning("Tftp ${$facts['os']['name']} may not be supported")
    }
  }
}
