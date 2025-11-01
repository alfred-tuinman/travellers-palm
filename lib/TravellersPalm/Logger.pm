package TravellersPalm::Logger;

use strict;
use warnings;

use Mojo::File 'path';
use Mojo::Log;
use POSIX qw(strftime);
use DateTime;
use DateTime::TimeZone;

sub setup {
    my ($self) = @_;

    my $log_conf = $self->config->{log} // {};
    $log_conf->{path}     //= path($self->home, 'log', 'app.log')->to_string;
    $log_conf->{level}    //= 'debug';
    $log_conf->{timezone} //= 'UTC';

    my $log_path = path($log_conf->{path});
    $log_path->dirname->make_path;

    # Get timezone object
    my $tz = DateTime::TimeZone->new(name => $log_conf->{timezone});

    my $logger = Mojo::Log->new(
        path  => $log_conf->{path},
        level => $log_conf->{level},
    );

    $logger->format(sub {
        my ($time, $level, @lines) = @_;
        
        # Convert UTC time to configured timezone
        my $dt = DateTime->from_epoch(epoch => $time, time_zone => 'UTC');
        $dt->set_time_zone($tz);
        my $ts = $dt->strftime("%Y-%m-%d %H:%M:%S %Z");
        
        my $msg = join('', @lines);
        $msg =~ s/^\s+|\s+$//g;
        return sprintf("[%s] [pid:%d] %s %s\n", $ts, $$, uc($level), $msg);
    });

    $self->log($logger);
    $self->log->debug("Logger initialized at $log_conf->{path} with timezone $log_conf->{timezone}");
}

1;
