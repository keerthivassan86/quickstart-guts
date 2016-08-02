# Declare the apt class to manage /etc/apt/sources.list and /etc/sources.list.d
class { 'apt': }

# Install the puppetlabs apt source
# Release is automatically obtained from lsbdistcodename fact if available.
apt::source { 'ubuntu-cloud':
  location          =>  'http://ubuntu-cloud.archive.canonical.com/ubuntu',
  repos             =>  'main',
  release           =>  'trusty-updates/mitaka',
  key               => {
    id              => '5EDB1B62EC4926EA',
    server          => 'keyserver.ubuntu.com',
  },
  include           =>  {
    src             => false,
  },
}
->
exec { 'apt-update':
    command => '/usr/bin/apt-get update'
}
-> Package <| |>
