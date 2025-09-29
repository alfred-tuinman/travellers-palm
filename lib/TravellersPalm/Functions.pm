package TravellersPalm::Functions;

use strict;
use warnings FATAL => 'all';

use Dancer2;

use Email::Valid;
use Geo::Location::TimeZone;
use HTTP::BrowserDetect;
#use WWW::ipinfo;
use DateTime;
#use DateTime::TimeZone;
use Time::Local;
use Date::Calc qw/ Delta_Days check_date check_time /;
use Data::Dumper;
use Exporter qw{import};
use POSIX qw(strftime);

our @EXPORT = qw{
    addptags
    boldify
    cutpara
    domain
    email_request
    html_strip
    linkExtor
    linkify
    ourtime
    seo
    trim
    validate_date
    valid_email
    url2text
    user_is_registered
    user_register
    user_email
    webtext
    weeknumber
};

our $VERSION = '1.00';    

sub addptags {
    # replace certain characters with <p> tags
    return '<p></p>' unless ( my $str = shift );

    my @lines = split m { (?:\x0D \x0A | \x0A | \x0D | \x0C | \x{2028} | \x{2029} ) }x, $str;

    return '<p>' . join( '</p><p>', @lines ) . '</p>';
}

sub boldify {
    # replace curly braces with <strong> tags to make text appear bold
    my $str = shift;
    $str =~ s/\{/\<strong\>/gm;  $str =~ s/\}/\<\/strong\>/gm;
    return $str;
}

sub cutpara {
    my $para = shift;
    my $size = shift;
    return substr( $para, 0, $size );
}

sub domain {
  my $url = URI->new( request->uri_base );
  my $domain = $url->host;
  $domain =~ s!^(?:www\.)?!!i;
  return $domain;

  # /(?<=\.)[a-z0-9-]*\.com/gm ;
};


sub email_request {

    my ($name, $email, $reference, $message) = @_;
=head
    use Email::Send::SMTP::Gmail;

     my $vars = {
         name => $name,
         email => $email,
         reference => $reference,
         message => $message,
     };

     my $mail=Email::Send::SMTP::Gmail->new(-smtp  => 'smtp.googlemail.com',
                                            -login => 'info@travellers-palm.com',
                                            -pass  => 'ip31415O');

     $mail->send(-to         => $email,
                 -cc         => 'info@travellers-palm.com',
                 -subject    => 'Your enquiry',
                 -verbose    => '1',
                 -body       => template('email_request_mime', $vars ),-contenttype=>'multipart/alternative; boundary=odyssey');

     $mail->bye;
=cut
        return 1;
    };
#

sub html_strip {

    my $html = shift;

    use HTML::Strip;

    my $hs   = HTML::Strip->new(emit_spaces => 0);
    my $text = $hs->parse( $html );
    $hs->eof;

return $text;
}

sub linkExtor {
    use LWP::UserAgent;
    use HTML::LinkExtor;
    use URI::URL;

    my $urlfile  = 'url-report.txt';

    if (open(my $fh, '<:encoding(UTF-8)', $urlfile)) {
      while (my $url = <$fh>) {
        chomp $url;
            #my $content = get $url;
            #die "Can't download $url" unless defined $content;

            print "$url\n";
            my $ua = LWP::UserAgent->new;

            my @imgs = ();

            #sub callback {
                my($tag, %attr) = @_;
                return if $tag ne 'img'; 
                push(@imgs, values %attr);
            #}

            my $p = HTML::LinkExtor->new(\&callback);
            my $res = $ua->request(HTTP::Request->new(GET => $url), sub {$p->parse($_[0])});

            my $base = $res->base;
            @imgs = map { $_ = url($_, $base)->abs; } @imgs;

            print join("\n", @imgs), "\n";

        }
    } else {
      warn "Could not open file '$urlfile' $!";
    } 
}

sub linkify {
    # replace text in square brackets with anchor links
    my $str = shift;
    #my $sid = shift;

    my $lstr = '';
    my $cities;

    while ( $str =~ /(.*?)\[(.*?)\](.*)/sm ) {
        my ( $name, $id ) = split( /\-/, $2 );
        my $city = city($id);
        push( @{$cities}, $city );
        my $url = $city->{url};
        $lstr
        = $lstr
        . $1
        . ' <a class="writeup popup-gallery" href="'
        . request->uri_base. '/ajax/slideshow-city-'. $id. '.html">'
        . $name . '</a>';
        $str = $3;
    }
    $lstr = $lstr . $str;

    return $lstr, $cities;
}

sub moneyfy {
    #my $number = sprintf "%.2f", shift @_;
    #1 while $number =~ s/^(-?\d+)(\d\d\d)/$1,$2/;
    #return $number;
    return;
}

sub ourtime {
    return DateTime->now( time_zone => 'Asia/Kolkata' );
}

sub seo {

    my $url  = shift;
    my $data = shift // '';

    my $line = "$url\n"
    . "   title       = " . (defined $data->{meta_title}       ? $data->{meta_title}       : '') . "\n"
    . "   description = " . (defined $data->{meta_descr}       ? $data->{meta_descr} : '') . "\n"
    . "   keywords    = " . (defined $data->{meta_keywords}    ? $data->{meta_keywords}    : '') . "\n\n";

#    my $line; 
#    $line->{url}         = $url;
#    $line->{title}       = (defined $data->{meta_title}       ? $data->{meta_title}       : '');
#    $line->{description} = (defined $data->{meta_description} ? $data->{meta_description} : '');
#    $line->{keywords}    = (defined $data->{meta_keywords}    ? $data->{meta_keywords}    : '');

return $line;
}

sub trim {
    # trim remove white space from both ends of a string
    my $str = shift;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub validate_date {
    my $d   = pop;
    my $dd  = new Date::Manip::Date;
    my $err = $dd->parse($d);
    return !$err;
}

sub valid_email {
    my $a = shift;

    # if ( $a =~ m/\s/ ) {        return 0;    }
    if ( Email::Valid->address($a) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub url2text{
 my $text = shift;
 $text =~ tr/-/\ /;
 $text =~ s/([\w']+)/\u\L$1/g;
 return $text;
}

sub user_is_registered { 
    return session('username') ? true : false;
}

sub user_register {
    my $email = shift;
    return unless Email::Valid->address($email);
    session username => $email;
}

sub user_email {  
    return session('username');
}

sub webtext {
    my $id   = shift;
    my $data = web($id);

    my $rows = $data->{rows};
    my $text = $data->{data};

    $text->{writeup} = ($rows > 0) ? boldify( addptags( $text->{writeup} )) : '';

    return $text;
}

sub weeknumber {
    
    my $date = shift;

    my ($month, $day, $year) = split '/', $date;
    my $epoch = timelocal( 0, 0, 0, $day, $month - 1, $year - 1900 );
    return strftime( "%U", localtime( $epoch ) );
}

1;