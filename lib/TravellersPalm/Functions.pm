package TravellersPalm::Functions;

use strict;
use warnings FATAL => 'all';

use DateTime;
use Date::Calc qw/Delta_Days check_date check_time/;
use Date::Manip::Date;
use Data::FormValidator;
use Email::Valid;
use Exporter 'import';
use Geo::Location::TimeZone;
use HTML::LinkExtor;
use HTML::Strip;
use HTTP::BrowserDetect;
use LWP::UserAgent;
use POSIX qw(strftime);
use Time::Local;
use TravellersPalm::Model::Cities;
# use URI;

our @EXPORT = qw{
    addptags
    boldify
    clean_text
    cutpara
    domain
    elog
    email_request
    html_strip
    linkExtor
    linkify
    ourtime
    seo
    trim
    url2text
    user_is_registered
    user_register
    user_email
    validate_date
    valid_email
    webtext
    weeknumber
};


# -----------------------------
# Safe optional Model::Cities module
# -----------------------------
my $has_cities;
my $cities_module;

eval {
    TravellersPalm::Model::Cities->import(qw(city web));
    $has_cities = 1;
    $cities_module = 'TravellersPalm::Model::Cities';
};
if ($@) {
    warn "Model::Cities not available: $@";
    $has_cities = 0;
}

# -----------------------------
# Text Utilities
# -----------------------------
sub addptags { 
    my $str = shift or return '<p></p>';
    my @lines = split /\R/, $str;
    return '<p>' . join('</p><p>', @lines) . '</p>';
}

sub boldify {
    my $str = shift;
    $str =~ s/\{/<strong>/g;
    $str =~ s/\}/<\/strong>/g;
    return $str;
}

sub clean_text {
    my $t = shift // '';
    $t =~ s/^\s+|\s+$//g;
    return $t;
}

sub cutpara {
    my ($para, $size) = @_;
    return substr($para, 0, $size);
}

sub domain {
    my $c = shift;
    my $url = $c->req->url->base;
    my $host = $url->host;
    $host =~ s!^(?:www\.)?!!i;
    return $host;
}


sub elog {
    my $log = '/var/log/nginx/travellers-palm/error.log';
    my @imgnames;

    open(my $fh, '<:encoding(UTF-8)', $log) or die "Cannot open log file: $!";
    while (my $line = <$fh>) {
            if ( $line =~ /failed/i ) {
                # Option A: split using q{} so editors don't get confused
                # my @parts = split q{"}, $line;
                # push @imgnames, { message => $parts[1] // $line };

                # -- or Prefer Option B (recommended) --
                if ( $line =~ /"([^"]+)"/ ) {
                  push @imgnames, { message => $1 };
                }
        }
    }
    close($fh);
    return \@imgnames;
}

sub email_request {
    my ($name, $email, $reference, $message) = @_;
    return 1;  # placeholder, email sending logic removed
}

sub html_strip {
    my $html = shift;
    my $hs = HTML::Strip->new(emit_spaces => 0);
    my $text = $hs->parse($html);
    $hs->eof;
    return $text;
}

sub linkExtor {
    my $urlfile = 'url-report.txt';
    return unless -f $urlfile;

    open(my $fh, '<:encoding(UTF-8)', $urlfile) or warn "Could not open file '$urlfile' $!" and return;
    while (my $url = <$fh>) {
        chomp $url;
        my $ua = LWP::UserAgent->new;
        my @imgs;

        my $callback = sub {
            my ($tag, %attr) = @_;
            return unless $tag eq 'img';
            push @imgs, values %attr;
        };

        my $p = HTML::LinkExtor->new($callback);
        my $res = $ua->request(HTTP::Request->new(GET => $url), sub { $p->parse($_[0]) });
        print join("\n", @imgs), "\n";
    }
    close($fh);
}

# -----------------------------
# Linkify with safe city lookup
# -----------------------------
sub linkify {
    my ($c, $str) = @_;
    my $lstr   = '';
    my $cities = [];

    while ($str =~ /(.*?)\[(.*?)\](.*)/sm) {
        my ($name, $id) = split /-/, $2;

        # Safe call: stub if Cities module not available
        my $city = eval { TravellersPalm::Database::Cities::city($id) } || {
            id   => $id,
            name => $name,
            url  => "#",
        };
        push @$cities, $city;

        my $url = $city->{url} // "#";
        $lstr .= $1 . qq{ <a class="writeup popup-gallery" href="$url">$name</a>};
        $str = $3;
    }
    $lstr .= $str;
    return ($lstr, $cities);
}

sub moneyfy { return; }

sub ourtime { 
    return DateTime->now(time_zone => 'Asia/Kolkata'); 
}

# -----------------------------
# SEO helper
# -----------------------------
sub seo {
    my ($url, $data) = @_;
    $data //= {};
    my $line = "$url\n"
             . "   title       = " . ($data->{meta_title} // '') . "\n"
             . "   description = " . ($data->{meta_descr} // '') . "\n"
             . "   keywords    = " . ($data->{meta_keywords} // '') . "\n\n";
    return $line;
}

sub trim {
    my $str = shift;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub validate_date {
    my $d = shift;
    my $dd = Date::Manip::Date->new;
    my $err = $dd->parse($d);
    return !$err;
}

sub valid_email {
    my $a = shift;
    return Email::Valid->address($a) ? 1 : 0;
}

sub url2text {
    my $text = shift;
    $text =~ tr/-/ /;
    $text =~ s/([\w']+)/\u\L$1/g;
    return $text;
}

sub user_is_registered {
    my $c = shift;
    return $c->session('username') ? 1 : 0;
}

sub user_register {
    my ($c, $email) = @_;          # $c is the Mojolicious controller
    return unless valid_email($email);
    $c->session(username => $email);  # set session in Mojolicious
}

sub user_email {
    my $c = shift;
    return $c->session('username');
}

# -----------------------------
# webtext using safe Model::Cities call
# -----------------------------
sub webtext {
    my $id = shift;
    my $text = {};
    if ($has_cities && $cities_module->can('web')) {
        my $data = $cities_module->web($id);
        my $rows = $data->{rows} // 0;
        $text = $data->{data} // {};
        $text->{writeup} = $rows > 0 ? boldify(addptags($text->{writeup})) : '';
    }
    return $text;
}

sub weeknumber {
    my $date = shift;
    my ($month, $day, $year) = split '/', $date;
    my $epoch = timelocal(0,0,0, $day, $month-1, $year-1900);
    return strftime("%U", localtime($epoch));
}

1;