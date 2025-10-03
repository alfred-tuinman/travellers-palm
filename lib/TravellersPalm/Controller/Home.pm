package TravellersPalm::Controller::Home;

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);  # for password/email handling
use MIME::Lite; 

use Data::FormValidator;
use Date::Manip::Date;
use DateTime::Format::Strptime;
use URI::http;  # obtain the URI base
use JSON qw();

use Template;
use Dancer2 ':syntax';
use TravellersPalm::Database::Connector qw(dbh);
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Functions qw/
                  clean_text 
                  email_request 
                  ourtime 
                  user_email 
                  user_is_registered 
                  valid_email
                  webtext/;

#--------------------------------------------------
# Actions
#--------------------------------------------------


sub index {
    my $slidetext = TravellersPalm::Database::General::web(163);
    my @slides    = $slidetext->{data}->{writeup} =~ /\G(?=.)([^\n]*)\n?/sg;
    unshift @slides, 'dummy item';

    template('home') => {
        title                => 'Home Page',
        metatags             => TravellersPalm::Database::General::webpages(6),
        themes               => TravellersPalm::Database::Themes::themes('LIMIT'),
        tripideas            => TravellersPalm::Database::Themes::themes('TRIPIDEAS'),
        country              => 'india',
        slides               => \@slides,
        the_travel_experts1  => webtext(119),
        the_travel_experts2  => webtext(120),
        the_travel_experts3  => webtext(121),
        tailor_made_tours    => webtext(187),
        mini_itineraries     => webtext(188),
        best_places_to_visit => webtext(189),
        about                => webtext(60),
        home                 => 1
    };
};

sub before_you_go {

  warn "[DEBUG] Before you go ". TravellersPalm->config->{views} . "\n";
    template 'before_you_go' => {
        metatags        => TravellersPalm::Database::General::metatags('before-you-go'),
        before_you_go   => webtext(17),
        getting_ready   => webtext(168),
        right_attitude  => webtext(169),
        page_title      => 'Before You Go',
        crumb           => '<li class="active">Before You Go</li>',
    };
}

sub contact_us {
    my $ourtime = ourtime();
    my $params  = params();
    my ($error, $err_msg, $ok) = (0, '', 0);
    my $crumb = "<li><a href='".request->uri_base. request->path . "'>Contact Us</a></li>";

    if ( request->is_post ) {
        my $name      = clean_text($params->{name});
        my $message   = clean_text($params->{message});
        my $reference = clean_text($params->{reference});
        my $email     = clean_text($params->{email});

        if (!$name)        { $err_msg = 'Please give me a name' }
        elsif (!$message)  { $err_msg = 'You forgot your message!' }
        elsif (!$reference){ $err_msg = 'You forgot your reference.' }
        elsif (!$email)    { $err_msg = 'You forgot your email id!' }
        elsif (!valid_email($email)) { $err_msg = 'Your email id appears to be wrong.' }

        if (!$err_msg) {
            $ok = email_request($name, $email, $reference, $message);
            $error = $ok ? 0 : 1;
            $err_msg = 'We are unable to send your message. Please try again later.' unless $ok;
        } else {
            $error = 1;
        }
    }

    return template('thankyou_for_request') => {
        metatags  => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        crumb     => $crumb,
        name      => $params->{name},
        email     => $params->{email},
        message   => $params->{message},
        reference => $params->{reference},
        page_title=> 'Thank You',
    } if $ok;

    template('contact') => {
        metatags        => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        travellers_palm => webtext(159),
        fast_replies    => webtext(160),
        ourtime         => $ourtime->strftime('%H:%M'),
        ourdate         => $ourtime->strftime('%d %B, %Y'),
        timediff        => 0,
        country         => 'India',
        crumb           => $crumb,
        error           => $error,
        err_msg         => $err_msg,
        name            => $params->{name},
        email           => $params->{email},
        message         => $params->{message},
        reference       => $params->{reference},
        page_title      => 'Contact Us',
    };
}

sub get_enquiry {
    template('enquiry') => {
        metatags => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        email    => (user_is_registered() ? 
                    user_email() : ''),
    };
}

sub post_enquiry {
    my $params  = params();
    template('enquiry') => {
        metatags => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        subject  => $params->{subject},
         email    => (user_is_registered() ? 
                    user_email() : ''),
    };
}

sub faq {
    template('faq') => {
        metatags   => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        crumb      => '<li class="active">FAQ</li>',
        page_title => 'FAQ',
    };
}

sub policies {
    my @fields = map { webtext($_) } (124..146,191);

    template ('policies') => {
        metatags   => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        conditions => webtext(15),
        terms      => webtext(35),
        privacy    => webtext(16),
        fields     => \@fields,
        about      => webtext(208),
        crumb      => '<li class="active">Our Policies</li>',
        page_title => 'Our Policies',
    };
}

sub search_results {
    template('search_results') => {
        metatags            => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        why_travel_with_us  => webtext(12),
        extensive_knowledge => webtext(153),
        highly_selective    => webtext(154),
        unbiased            => webtext(155),
        unrivalled_coverage => webtext(156),
        in_charge           => webtext(157),
        value_for_money     => webtext(158),
        crumb               => '<li class="active">Search Results</li>',
        page_title          => 'Search Results',
    };
}

sub site_map {
  my $app = Dancer2->runner->app('TravellersPalm');
    my $textfile = $app->config->{root}.'/url-report.txt';
    my @report;

    if (open my $fh, '<:encoding(UTF-8)', $textfile) {
        while (my $row = <$fh>) {
            chomp $row;
            next unless $row =~ /\S/;
            push @report, { url => $row };
        }
    }

    template('sitemap') => {
        metatags   => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        report     => \@report,
        crumb      => '<li class="active">Sitemap</li>',
        page_title => 'Sitemap',
    };
}

sub state {
   my $params  = params();
    redirect request->uri_base . "/destinations/india/explore-by-state/" . $params->{state} . "/list";
}

sub sustainable_tourism {
    my $sustainable = webtext(13);
    template('sustainable_tourism') => {
        metatags    => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        sustainable => $sustainable,
        crumb       => '<li class="active">'.$sustainable->{title}.'</li>',
        page_title  => $sustainable->{title},
    };
}

sub testimonials {
     template('testimonials') => {
        metatags   => TravellersPalm::Database::General::metatags('testimonials'),
        page_title => 'Testimonials',
        crumb      => '<li><a href="[% request.uri_base %]/about-us">About us</a></li><li class="active">Testimonials</li>',
    };
}

sub travel_ideas {
    template('travel_ideas') => {
        metatags   => TravellersPalm::Database::General::metatags('travel-ideas'),
        page_title => 'Travel Ideas',
        crumb      => '<li class="active">Travel Ideas</li>',
    };
}

sub what_to_expect {
    my $expect = webtext(21);
    template('what_to_expect') => {
        metatags        => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        what_to_expect  => $expect,
        special_hotels  => webtext(147),
        eat_drink       => webtext(148),
        private_car     => webtext(149),
        travel_by_train => webtext(150),
        fly_in_comfort  => webtext(151),
        delays          => webtext(152),
        before_you_go   => webtext(17),
        getting_ready   => webtext(168),
        right_attitude  => webtext(169),
        crumb           => '<li class="active">'.$expect->{title}.'</li>',
        page_title      => $expect->{title},
    };
}

sub why_travel_with_us {
    my $ourtime = ourtime();
    my $why     = webtext(12);

    template('why_travel_with_us') => {
        metatags            => TravellersPalm::Database::General::metatags( (split '/', request->path)[-1] ),
        why_travel_with_us  => $why,
        extensive_knowledge => webtext(153),
        highly_selective    => webtext(154),
        unbiased            => webtext(155),
        unrivalled_coverage => webtext(156),
        in_charge           => webtext(157),
        value_for_money     => webtext(158),
        totalcities         => totalcities(),
        ourtime             => $ourtime->strftime('%H:%M'),
        ourdate             => $ourtime->strftime('%d %B, %Y'),
        timediff            => 0,
        need_help           => webtext(176),
        crumb               => '<li class="active">'.$why->{title}.'</li>',
        page_title          => $why->{title},
    };
}

1;
