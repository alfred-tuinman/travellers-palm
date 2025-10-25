package TravellersPalm::Logger;
use strict;
use warnings;
use Mojo::File 'path';
use Mojo::Log;
use POSIX qw(strftime);

sub setup {
    my ($self) = @_;

    my $log_conf = $self->config->{log} // {};
    $log_conf->{path}  //= path($self->home, 'log', 'travellers_palm.log')->to_string;
    $log_conf->{level} //= 'debug';

    my $log_path = path($log_conf->{path});
    $log_path->dirname->make_path;

    my $logger = Mojo::Log->new(
        path  => $log_conf->{path},
        level => $log_conf->{level},
    );

    $logger->format(sub {
        my ($time, $level, @lines) = @_;
        my $ts = strftime("%Y-%m-%d %H:%M:%S %Z", localtime($time));
        my $msg = join('', @lines);
        $msg =~ s/^\s+|\s+$//g;
        return sprintf("[%s] [pid:%d] %s %s\n", $ts, $$, uc($level), $msg);
    });

    $self->log($logger);
    $self->log->debug("Logger initialized at $log_conf->{path}");
}

1;
