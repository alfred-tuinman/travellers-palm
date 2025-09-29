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

get '/about-us' => sub {
   
    template about => {
        metatags                => metatags('about-us'),
        totalcities             => totalcities(),
        totalitineraries        => totalitineraries(),
        totaltrains             => totaltrains(),
        intro                   => webtext(9),
        philosophy              => webtext(170),
        sustainable_tourism     => webtext(171),
        responsible_tourism     => webtext(172),
        meet_the_team           => webtext(31),
        why_travel_with_us      => webtext(12),
        what_is_travellers_palm => webtext(8),
        hans                    => webtext(164),
        sucheta                 => webtext(165),
        phil                    => webtext(166),
        shalome                 => webtext(167),
        crumb                   => ' <li class="active">About Us</li>',
        page_title              => 'About Us',
    };
};

1;
