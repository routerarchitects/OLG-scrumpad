interfaces {
    ethernet eth0 {
        address "dhcp"
        description "WAN"
    }
    loopback lo {
    }
}
pki {
    ca my-ca {
        certificate "MIIDnTCCAoWgAwIBAgIUa4wwks6IjzlQ+3xg95Sq/6fsUocwDQYJKoZIhvcNAQELBQAwVzELMAkGA1UEBhMCR0IxEzARBgNVBAgMClNvbWUtU3RhdGUxEjAQBgNVBAcMCVNvbWUtQ2l0eTENMAsGA1UECgwEVnlPUzEQMA4GA1UEAwwHdnlvcy5pbzAeFw0yNTEwMTIxMzQxMjFaFw0zMDEwMTExMzQxMjFaMFcxCzAJBgNVBAYTAkdCMRMwEQYDVQQIDApTb21lLVN0YXRlMRIwEAYDVQQHDAlTb21lLUNpdHkxDTALBgNVBAoMBFZ5T1MxEDAOBgNVBAMMB3Z5b3MuaW8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDGr7+r3EntXVvsS7WJjdPQFuQcve5BxpB8MvPrxbpDiSAled/QOD7d9FMNqvylDbFoDNf61tnrPxTI9W6wmADKKQvrFeTf1bTx9bzGyL4BQXxKmtjtuLlE3lUqf4HChbfizsKQVRZ5F4hJLhSKsR5Yly2oIBTKMKOlvuk9OC3Pl2qzIxfg6K27tuVpqWgW6Q7lyRh2/Hlr5rSA9AIsEyPzFzNBmvuMruH+nhD6axPSEDxdqWeImBYGy7IhK5kbP8jKMoVF7UMcvxMDy0qHusglNwy9g7UQH77pN/tW2hnsB+4g3BFwOb3fDV1d6thwt9y3bkd8ImK1bKlmrAPmQOazAgMBAAGjYTBfMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcDATAdBgNVHQ4EFgQUI6ApTlBC0EedvcLlH+KkCZR0l68wDQYJKoZIhvcNAQELBQADggEBAFnr4/Cp6PEVp0FEvxY6DJmeEU9Ay1j6mTsz9XURveWZSOmko573ls9xCbLMB8pJ8xSYfbAsfgTiftTo6Y+DqwGhu3Mc896JbENt9SJh8gbRX5Y+hEa2O35qfj+KSOAjFymzdycmh/S2/adMwVjg6cSYxngiqoVMVN1EQgt2XVPJCnL7yK+7awJh1CdcMyByZ/n34q3geG9ZVsxJQbgOLm3Tug4PpJx7PjY85dAXJQmkeQodMi2HD3E/i/WQZ/mq6EfevEL7Bo/hz2hC6rokFn9ejeEs4m8/kXnD+pGMzwuXhvvn/tYhSl4xh15ms5ILGewy52AlqFadwaT3PDK9SLc="
        private {
            key "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDGr7+r3EntXVvsS7WJjdPQFuQcve5BxpB8MvPrxbpDiSAled/QOD7d9FMNqvylDbFoDNf61tnrPxTI9W6wmADKKQvrFeTf1bTx9bzGyL4BQXxKmtjtuLlE3lUqf4HChbfizsKQVRZ5F4hJLhSKsR5Yly2oIBTKMKOlvuk9OC3Pl2qzIxfg6K27tuVpqWgW6Q7lyRh2/Hlr5rSA9AIsEyPzFzNBmvuMruH+nhD6axPSEDxdqWeImBYGy7IhK5kbP8jKMoVF7UMcvxMDy0qHusglNwy9g7UQH77pN/tW2hnsB+4g3BFwOb3fDV1d6thwt9y3bkd8ImK1bKlmrAPmQOazAgMBAAECggEAHzdyv8pTKoJIvzYKoOuR1CJx7FrNCd7sSY8/Mr6KFt1UbymYXXXQ2XzvOvkFS9t8Zv2Jm5rRJKcbGWiHtSLqENk6daZRePeclTLdBPB6UJEyOY3dt8VBBU3XXLTUNYoJNmSc6MzC71CgCZC+Cn0XPae3CoYhLhP5SkErZ9fL9CRZCTkjTT3XERiKR39piLC3aRcxNBfdMcXgYo5DvtwbpleaI9d0nec8eKNAmNf6S1ohJm0KdRz6O0p2jsVFLp3/ZWObd/ij/IFWr8RYnBsVaz76DX7jO1QC+aKyAC/QahOrJFO0otFjJbIoXO7Z99q9hseLmQqvXUENn4i16ifQ0QKBgQDsBEwubnHg0io05GsQwarj6+nr6HJ/UYrb2Bb77dhkByx0OSVP+fm9umRD4qbrv2NltkdPqS/671UVZlJ38kTYGTQsXoeK2CRGIxx8q3bqB8K/eDZDqb/XKOrV7SNJNjFOwqq1fjrNumhJ5qIEz2c8riZvUn0AJL4I0qvE/l6ZsQKBgQDXgk+7fRF+FKH9uGFCUWD9H3TZNlS9gKbZ4SnwoXlX/cUZ954OMRcuClh5m6L6mKVgLTs6gXrG48hlO2fWsm8GVioLueJ8mYRXS1cNdniYX4C5tQJO9vycfX4tzorfkF13+WTBBn5259ZSc5ysEL7VRxtGJEsuAAZKJKb77T17owKBgEfF/szX9XWjNAaluBF+c9OgOKDvLXKef5Xfnw26BOZWcCRgBILPyCz0c+1ZDd3/c+DIj+Mf1mF/SuaZGVc0q87zyzP7A0kr9cwGfXFES4NcHNNRYV8uThLGdLPdy69F9bS36mYLHyLVH0XqBzdjQ0fmxfVwpmbWxZu1RVtA58/hAoGAZOjoqrLKYQ4KOAKA0AvI7V0wWpEdJsq51eWfvMPvTKtQAnO2t5B2+SDxAqhErTCSpzEmvaNpOP3plLU3TwmoAQCRmYIFsjA0DqgBcBVcLITzgoFmPlFaQXBlh89hqYMwsP+/FL8UslqmOV9XKh6BLN6pv7M43KY4S7lT0zzoAB8CgYEAl9NxqWAwEeYeSndmFwAXHXTcB8fV3XMCuE7abhUgBUsXn/9GUx3e/8Mg9/x/l8uXjFaHu0gfUEZ9CxQPM3VZXcXjm/NypzmfHqf8p0Kx73o7AoBBxqn4D+pbzZhGiEi5AJbYd4ik9yfYe21rENtNECeAqpPNjwLHeIiWoYq5GfA="
        }
    }
    certificate api-cert {
        certificate "MIIDsTCCApmgAwIBAgIUWDJsrZgI3qZodiAfHrjXAxdmbwowDQYJKoZIhvcNAQELBQAwVzELMAkGA1UEBhMCR0IxEzARBgNVBAgMClNvbWUtU3RhdGUxEjAQBgNVBAcMCVNvbWUtQ2l0eTENMAsGA1UECgwEVnlPUzEQMA4GA1UEAwwHdnlvcy5pbzAeFw0yNTEwMTIxMzQyMzlaFw0yNjEwMTIxMzQyMzlaMFcxCzAJBgNVBAYTAkdCMRMwEQYDVQQIDApTb21lLVN0YXRlMRIwEAYDVQQHDAlTb21lLUNpdHkxDTALBgNVBAoMBFZ5T1MxEDAOBgNVBAMMB3Z5b3MuaW8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCWptrVJnD+oLXtCRp593Ku8dsnYGyHMi0ohr1bdhjB5xWvt/zLCYII3Ub3C+t+QSqVfpc9tQR5niS7WlqCqxCfwCvmsJE74aidZKNbG+E807GcUKr2bNhiFInPeUSz20zikxOIXCrdrQ/uFlGtor4nJGuGL05wNfrDySnqzBdRDhm5tPkSN7oeMVZuxDOSjnBClNT4Np6v8ENtFlDSu+dUpeWutO2eK0VcycuzHgxMWc4/kVW8q1DpNsOrdhmd3K5CxLqR5C290XlDFL2Yiv43scZh9wvPuioULbRV6qS48Renxe0LBZhafMJCHr0aLFzkW96m3gl52hcvPXG2FlzTAgMBAAGjdTBzMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMB0GA1UdDgQWBBTAcqb/TwzxRJ9v7XryRwIvy85ozzAfBgNVHSMEGDAWgBQjoClOUELQR529wuUf4qQJlHSXrzANBgkqhkiG9w0BAQsFAAOCAQEAoP4NHO0GBdVbqk41XcZ8bk0fWVKmTEAejhRuGBvegkmUAAzJRMb2y0nBE6xoG11dXBiIWrFAvk22E30h/RtbWhGIfabPFjG53CbTBUPZh3hM6cFdqmTTYTlBpFtp2XEdbdh6BJRyxOPU1MQp1yzmUHWc2mMZsTa8TQZAGbBkh8kaJ1SFVE5I3m7uOx/ahoFhsa+SIKGmvosBHhNqzs18P8zYYOiNi14urJG3oR+0Qz/sbjXzbAzkUYnRIH5J7FXeJd0nNsSUB6ViRBGLMOUOTxHfePk7oYrnjwegJnam2gayZVRIViUeKHvIyutvSOd3qpM819G5f2R/K6mLBVtH9A=="
        private {
            key "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCWptrVJnD+oLXtCRp593Ku8dsnYGyHMi0ohr1bdhjB5xWvt/zLCYII3Ub3C+t+QSqVfpc9tQR5niS7WlqCqxCfwCvmsJE74aidZKNbG+E807GcUKr2bNhiFInPeUSz20zikxOIXCrdrQ/uFlGtor4nJGuGL05wNfrDySnqzBdRDhm5tPkSN7oeMVZuxDOSjnBClNT4Np6v8ENtFlDSu+dUpeWutO2eK0VcycuzHgxMWc4/kVW8q1DpNsOrdhmd3K5CxLqR5C290XlDFL2Yiv43scZh9wvPuioULbRV6qS48Renxe0LBZhafMJCHr0aLFzkW96m3gl52hcvPXG2FlzTAgMBAAECggEAJ+jM6RGVdob5mvFB79SjL4BHx98t8QTUXLuRF1UqStfecV4C3IDIz3NbNOAWAyzdTJwsEb9OD6/a2D0f5CTQMxnUJ3lYCC6IHiYGdoDkwtnr39ao67469oStW2arUiBC9nTzBDkya+ZIZZDJE4Ac8r6ds379vxE1vL8iWR63AJQc+e9i2C1qlB5OpMB7sE3Z3tdBMbmeU4+1IKO408VSx5JX9OKV6U/QCF0IyN9OOUoX7IvphmCyyPWoWhIJDEVzbx4y9xngWOCv9hVxEGmDIIXT7DZsCYEbblnWUCnpneK0EiSIsNA8s0Sqv08sXxd3kafVgK0HNlWkLBVyoniA+QKBgQDP0YhTcxns+ayCbag8ianMQ+mXkOEx3ilntt0ddae42NCLbjkl/25bSD9UMxOD6MxM7k6J/iznkH3I7j1R040rM3vDqusKa3SNyUFri0xj2Y5qJnGc+dNgTW8NUCi5Spe5F3IKebiGHUa/d7Iaiev47nobo0hj9sbNIWBQLhXsuwKBgQC5lFtgwpyfIwvHxbLckA/7VAUiRcxf2SvJbg/zhEUAnr+WjoHqs1k5UZe6XSy0GY5qjHVOA6kaok1ks+Hgn8kGUjJ0X2hTUFektZboLs+fRR+Z3fylD/dc4hX8eotIx2nGLlnnT3jMUwdP+aWyUJ0CsQXc/NaQcWuIQPY1n3WayQKBgD7BGReJ9FQ4+LzR/DF7qIiEIW+hUj9KxNoKwC57LtCEuETCXgN5ZIuv/1+fpM76Z2b7tz+4PzsVyMX6Gw4wgbp/62mknSEiXanLEjQ1djXYpkaroTczwX6dI2GzyPha7AH6cHd1ViE5ifmbXW7iIx2idcEOx3dYN6QN5hWQNRKtAoGATRNL3GUXjZSNqPv4LFj8+kJMG47nsgtNf0xh/Z661eYY5lvro2G3tfGoVbOrBGX021XYxn0It9Ie2KtJLfTPFfv/joutlaSxsevlcCs4+gpIdKxY6Ok3sHEJ9qGixahkyvWnS0WbgykcyV+DLQsEGwEQ0VaFetpQcfehCmZe/tkCgYEAjp7sCFQJ9UCc8DYpb2BFkuWjbDXK6Z/r+Wkmp+GYrmVVyVpTRVgO0ASXzTV+VbUqprMYTldZv8QE86cz/dtavMu/qzd3JP/gx1h4CZpsoGi2YcZmjImFPL1hkLzF7D2XJaNMsSPTtd+B6vKm6I/q3B4vhS5Ad94SMpoYR/tXkfE="
        }
    }
}
service {
    https {
        allow-client {
            address "127.0.0.1/32"
        }
        api {
            keys {
                id MY-HTTPS-API-ID {
                    key "MY-HTTPS-API-PLAINTEXT-KEY"
                }
            }
            rest {
            }
        }
        certificates {
            ca-certificate "my-ca"
            certificate "api-cert"
        }
        listen-address "127.0.0.1"
        port "443"
    }
    ntp {
        allow-client {
            address "127.0.0.0/8"
            address "169.254.0.0/16"
            address "10.0.0.0/8"
            address "172.16.0.0/12"
            address "192.168.0.0/16"
            address "::1/128"
            address "fe80::/10"
            address "fc00::/7"
        }
        server time1.vyos.net {
        }
        server time2.vyos.net {
        }
        server time3.vyos.net {
        }
    }
    ssh {
        port "22"
    }
}
system {
    config-management {
        commit-revisions "100"
    }
    conntrack {
        modules {
            ftp
            h323
            nfs
            pptp
            sip
            sqlnet
            tftp
        }
    }
    host-name "vyos"
    login {
        operator-group default {
            command-policy {
                allow "*"
            }
        }
        user vyos {
            authentication {
                encrypted-password "$6$QxPS.uk6mfo$9QBSo8u1FkH16gMyAVhus6fU3LOzvLR9Z9.82m3tiHFAxTtIkhaZSWssSgzt4v4dGAL8rhVQxTg0oAG9/q11h/"
                plaintext-password ""
            }
        }
    }
    name-server "8.8.8.8"
    name-server "eth0"
    syslog {
        local {
            facility all {
                level "info"
            }
            facility local7 {
                level "debug"
            }
        }
    }
}

// Warning: Do not remove the following line.
// vyos-config-version: "bgp@6:broadcast-relay@1:cluster@2:config-management@1:conntrack@6:conntrack-sync@2:container@3:dhcp-relay@2:dhcp-server@11:dhcpv6-server@6:dns-dynamic@4:dns-forwarding@4:firewall@20:flow-accounting@2:https@7:ids@2:interfaces@33:ipoe-server@4:ipsec@13:isis@3:l2tp@9:lldp@3:mdns@1:monitoring@2:nat@8:nat66@3:nhrp@1:ntp@3:openconnect@3:openvpn@4:ospf@2:pim@1:policy@9:pppoe-server@11:pptp@5:qos@3:quagga@12:reverse-proxy@3:rip@1:rpki@2:salt@1:snmp@3:ssh@2:sstp@6:system@29:vpp@1:vrf@3:vrrp@4:vyos-accel-ppp@2:wanloadbalance@4:webproxy@2"
// Release version: 2025.09.10-0018-rolling
