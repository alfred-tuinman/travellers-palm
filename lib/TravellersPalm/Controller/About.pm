package TravellersPalm::Controller::About;
use strict;
use warnings;
use Template;

sub show {
    my ($class, $env, $match) = @_;

    my $tt = Template->new({ INCLUDE_PATH => 'views' });
    my $output = '';
    $tt->process('about.tt', { title => 'About Us' }, \$output)
        or return [500, ['Content-Type'=>'text/plain'], ["Template error: " . $tt->error]];

    return [200, ['Content-Type'=>'text/html'], [$output]];
}

1;
