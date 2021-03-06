package App::Netdisco::SSHCollector::Platform::ASA;


=head1 NAME

App::Netdisco::SSHCollector::Platform::ASA

=head1 DESCRIPTION

Collect IPv4 ARP and IPv6 neighbor entries from Cisco ASA devices.

You will need the following configuration for the user to automatically enter
C<enable> status after login:

 aaa authorization exec LOCAL auto-enable

To use an C<enable> password seaparate from the login password, add an
C<enable_password> under C<sshcollector> in your configuration file:

 sshcollector:
   - ip: '192.0.2.1'
     user: oliver
     password: letmein
     enable_password: myenablepass
     platform: IOS

=cut

use strict;
use warnings;

use Dancer ':script';
use Expect;
use Moo;

=head1 PUBLIC METHODS

=over 4

=item B<arpnip($host, $ssh)>

Retrieve ARP and neighbor entries from device. C<$host> is the hostname or IP
address of the device. C<$ssh> is a Net::OpenSSH connection to the device.

Returns a list of hashrefs in the format C<{ mac => MACADDR, ip => IPADDR }>.

=back

=cut

sub arpnip {
    my ($self, $hostlabel, $ssh, $args) = @_;

    debug "$hostlabel $$ arpnip()";

    my ($pty, $pid) = $ssh->open2pty or die "unable to run remote command";
    my $expect = Expect->init($pty);

    my ($pos, $error, $match, $before, $after);
    my $prompt;

    if ($args->{enable_password}) {
       $prompt = qr/>/;
       ($pos, $error, $match, $before, $after) = $expect->expect(10, -re, $prompt);

       $expect->send("enable\n");

       $prompt = qr/Password:/;
       ($pos, $error, $match, $before, $after) = $expect->expect(10, -re, $prompt);

       $expect->send( $args->{enable_password} ."\n" );
    }

    $prompt = qr/#/;
    ($pos, $error, $match, $before, $after) = $expect->expect(10, -re, $prompt);

    $expect->send("terminal pager 2147483647\n");
    ($pos, $error, $match, $before, $after) = $expect->expect(5, -re, $prompt);

    $expect->send("show arp\n");
    ($pos, $error, $match, $before, $after) = $expect->expect(60, -re, $prompt);

    my @arpentries = ();
    my @lines = split(m/\n/, $before);

    # ifname 192.0.2.1 0011.2233.4455 123
    my $linereg = qr/[A-z0-9\-\.]+\s([A-z0-9\-\.]+)\s
                     ([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})/x;

    foreach my $line (@lines) {
        if ($line =~ $linereg) {
            my ($ip, $mac) = ($1, $2);
            push @arpentries, { mac => $mac, ip => $ip };
        }
    }

    # start ipv6
    $expect->send("show ipv6 neighbor\n");
    ($pos, $error, $match, $before, $after) = $expect->expect(60, -re, $prompt);

    @lines = split(m/\n/, $before);

    # IPv6 age MAC state ifname
    $linereg = qr/([0-9a-fA-F\:]+)\s+[0-9]+\s
                     ([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})/x;

    foreach my $line (@lines) {
        if ($line =~ $linereg) {
            my ($ip, $mac) = ($1, $2);
            push @arpentries, { mac => $mac, ip => $ip };
        }
    }
    # end ipv6

    $expect->send("exit\n");
    $expect->soft_close();

    return @arpentries;
}

1;
