package TravellersPalm::Functions;

use strict;
use warnings FATAL => 'all';

use Exporter 'import';
use Email::Valid;
use Geo::Location::TimeZone;
use HTTP::BrowserDetect;
use DateTime;
use Time::Local;
use Date::Calc qw/Delta_Days check_date check_time/;
use Data::Dumper;
use POSIX qw(strftime);
use URI;

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
    require TravellersPalm::Model::Cities;
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
    my @lines = split m{ (?:\x0D\x0A|\x0A|\x0D|\x0C|\x{2028}|\x{2029}) }x, $str;
    return '<p>' . join('</p><p>', @lines) . '</p>';
}

sub boldify {
    my $str = shift;
    $str =~ s/\{/<strong>/gm;
    $str =~ s/\}/<\/strong>/gm;
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
    my $url = URI->new(request->url_base);
    my $domain = $url->host;
    $domain =~ s!^(?:www\.)?!!i;
    return $domain;
}

sub elog {
    my $log = '/var/log/nginx/travellers-palm/error.log';
    my @imgnames;

    open(my $fh, '<:encoding(UTF-8)', $log) or die "Cannot open log file: $!";
    while (my $line = <$fh>) {
            if ( $line =~ /failed/i ) {
                # Option A: split using q{} so editors don't get confused
                # my @parts = split q{"}, $line;
                # push @entries, { message => $parts[1] // $line };

                # -- or Prefer Option B (recommended) --
                if ( $line =~ /"([^"]+)"/ ) {
                  push @entries, { message => $1 };
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
    require HTML::Strip;
    my $hs = HTML::Strip->new(emit_spaces => 0);
    my $text = $hs->parse($html);
    $hs->eof;
    return $text;
}

sub linkExtor {
    require LWP::UserAgent;
    require HTML::LinkExtor;

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
    my $str = shift;
    my $lstr = '';
    my $cities;

    while ($str =~ /(.*?)\[(.*?)\](.*)/sm) {
        my ($name, $id) = split /-/, $2;

        my $city;
        if ($has_cities) {
            $city = $cities_module->city($id);
        } else {
            $city = { id => $id, name => $name, url => "#" };
        }

        push @$cities, $city;
        my $url = $city->{url} // '#';
        $lstr .= $1 . ' <a class="writeup popup-gallery" href="' . request->url_base . $url . '">' . $name . '</a>';
        $str = $3;
    }
    $lstr .= $str;
    return ($lstr, $cities);
}

sub moneyfy { return; }
sub ourtime { return DateTime->now(time_zone => 'Asia/Kolkata'); }

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
    require Date::Manip::Date;
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

sub user_is_registered { return session('username') ? 1 : 0; }
sub user_register { my $email = shift; return unless valid_email($email); session username => $email; }
sub user_email { return session('username'); }

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
