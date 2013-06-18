# == Define: sys::bash::rc
#
# Creates a bash resource file for the given user name.
#
# === Parameters
#
# If a parameter is undefined (undef) it will not be included in the
# bash resource file.
#
# [*name*]
#  The username to create the resource file for.
#
# [*ensure*]
#  Ensure value for this resource, defaults to 'present'.
#
# [*group*]
#  The group to use for the resource file, defaults to undef.
#
# [*editor*]
#  The value of EDITOR in the bash resource file, defaults to undef.
#
# [*extra*]
#  Any extra configuration text to include the resource file.
#  Defaults to undef.
#
# [*path*]
#  The value of PATH in the bash resource file, defaults to the value
#  in the `sys::bash::path` variable.
#
# [*pythonpath*]
#  The value of PYTHONPATH in the bash resource file, defaults to undef.
#
# [*template*]
#  Advanced usage only.  The template to use when generating the bash
#  resource file, defaults to "sys/bash/${::osfamily}.erb".
#
define sys::bash::rc(
  $ensure     = 'present',
  $group      = undef,
  $editor     = undef,
  $extra      = undef,
  $path       = undef,
  $pythonpath = undef,
  $template   = "sys/bash/${::osfamily}.erb",
) {
  include sys::bash

  case $ensure {
    'present': {
      $file_ensure = 'file'
    }
    'absent': {
      $file_ensure = $ensure
    }
    default: {
      fail("Invalid sys::bash::rc ensure value: ${ensure}\n")
    }
  }

  if $path != '' {
    $bashpath = $path
  } else {
    $bashpath = $sys::bash::path
  }

  # The template for the bash resource file; uses the following
  # variables from this scope:
  # * $bashpath
  # * $pythonpath
  # * $editor
  # * $extra
  if $name == 'root' {
    $home = '/root'
  } else {
    $home = "/home/${name}"
  }

  file { "${home}/.bashrc":
    ensure  => $file_ensure,
    owner   => $name,
    group   => $group,
    mode    => '0600',
    content => template($template),
    require => Class['sys::bash'],
  }

  file { "${home}/.bash_profile":
    ensure  => $file_ensure,
    owner   => $name,
    group   => $group,
    mode    => '0600',
    content => "test -r ~/.bashrc && source ~/.bashrc\n",
    require => File["${home}/.bashrc"],
  }

  if $::operatingsystem == Solaris {
    file { "${home}/.zfs_completion":
      ensure => $file_ensure,
      mode   => '0600',
      owner  => $name,
      group  => $group,
      source => 'puppet:///modules/sys/bash/zfs_completion',
    }
  }
}
