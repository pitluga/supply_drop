class valid {
  file { "/etc/hosts":
    ensure => present,
    content => "127.0.0.1 localhost",
    owner => root,
    group => root,
    mode => "0644"
  }
}
