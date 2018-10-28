# = Class: redis::preinstall
#
# This class provides anything required by the install class.
# Such as package repositories.
#
class redis::preinstall {
  if $::redis::manage_repo {
    case $::operatingsystem {
      'RedHat', 'CentOS', 'Scientific', 'OEL', 'Amazon': {
        require ::epel
      }

      'Debian': {
        contain ::apt

        case $::operatingsystemmajrelease {
          # Squeeze, Wheezy, Jessie
          '6', '7', '8': {
            # Assume dotdeb supplies packages
            apt::source { 'dotdeb':
              location => 'http://packages.dotdeb.org/',
              release  =>  $::lsbdistcodename,
              repos    => 'all',
              key      => {
                id     => '6572BBEF1B5FF28B28B706837E3F070089DF5277',
                source => 'http://www.dotdeb.org/dotdeb.gpg',
              },
              include  => { 'src' => true },
              before   => [
                Class['apt::update'],
                Package[$::redis::package_name],
              ],
            }
          }

          # Stretch onwards
          default: {
            # Grab from Debian backports
            if ! defined(Apt::Source["${::lsbdistcodename}-backports"]) {
              apt::source { "${::lsbdistcodename}-backports":
                location => "http://ftp.debian.org/debian",
                release  => "${::lsbdistcodename}-backports",
                repos    => "main",
                pin      => "-1",
                include  => { 'src' => true },
                before   => [
                  Class['apt::update'],
                  Package[$::redis::package_name],
                ],
              }
            }

            # Allow redis/tooling to be installed from backports
            apt::pin { "${::lsbdistcodename}-backports-redis-server":
              packages => "redis $::redis::package_name redis-tools $::redis::sentinel_package_name",
              priority => 500,
              release  => "${::lsbdistcodename}-backports",
              before   => [
                Class['apt::update'],
                Package[$::redis::package_name],
              ],
              require  => Apt::Source["${::lsbdistcodename}-backports"],
            }
          }
        }
      }

      'Ubuntu': {
        contain ::apt
        apt::ppa { $::redis::ppa_repo:
          before   => [
            Class['apt::update'],
            Package[$::redis::package_name],
          ],
        }
      }

      default: {
      }
    }
  }
}

