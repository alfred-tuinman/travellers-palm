package TravellersPalm::Functions;

use strict;
use warnings FATAL => 'all';

use DateTime;
use Date::Calc qw/Delta_Days check_date check_time/;
use Data::Dumper qw(Dumper);
use Date::Manip::Date;
use Data::FormValidator;
use Email::Valid;
use Exporter 'import';
use Geo::Location::TimeZone;
use HTML::LinkExtor;
use HTML::Strip;
use HTTP::BrowserDetect;
use HTTP::Request;
use LWP::UserAgent;
use POSIX qw(strftime);
use Time::Local qw(timelocal);
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
    weeknumber
};

# -----------------------------
# Safe optional Model::Cities module
# -----------------------------
my $has_cities;
my $cities_module;
my $has_web;
my $web_module;

# -----------------------------
# Text Utilities
# -----------------------------
sub addptags {
    my ($str) = @_;
    return '<p></p>' unless defined $str && length $str;

    # Split on any line break (\n, \r\n, \r)
    my @lines = grep { /\S/ } split /\R/, $str;  # remove empty lines

    return '<p>' . join('</p><p>', @lines) . '</p>';
}

sub boldify {
    my ($str) = @_;
    return '' unless defined $str;

    # Replace {…} with <strong>…</strong>
    $str =~ s/\{(.*?)\}/<strong>$1<\/strong>/g;

    return $str;
}


sub clean_text {
    my $t = shift // '';
    
    # Trim leading/trailing spaces
    $t =~ s/^\s+|\s+$//g;

    # Optional: collapse multiple spaces/tabs inside the string to a single space
    $t =~ s/\s+/ /g;

    return $t;
}

sub cutpara {
    my ($para, $size) = @_;
    return '' unless defined $para && defined $size && $size > 0;

    # Decode in case we get UTF-8 bytes
    use Encode qw(decode);
    $para = decode('UTF-8', $para) unless utf8::is_utf8($para);

    # Trim to $size but try not to cut mid-word
    if (length($para) > $size) {
        my $cut = substr($para, 0, $size);
        $cut =~ s/\s+\S*$//;   # remove incomplete trailing word
        $para = $cut . '...';  # indicate truncation
    }

    return $para;
}

sub domain {
    my $c = shift;

    # Use base URL from request or fallback to the app's configured URL
    # Ensures you’re working on a copy, not modifying the live request object by accident.
    my $url  = $c->req->url->base->clone; 
    my $host = $url->host // '';

    # Normalize and strip common prefixes
    $host =~ s/^(?:www\.|m\.|dev\.)//i;
    return lc $host;
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

    # Basic sanity checks
    for ($name, $email, $reference, $message) {
        return { error => 'Missing parameter(s)' } unless defined $_ && length $_;
    }

    # Simple email format sanity check
    unless ($email =~ /^[^\s@]+@[^\s@]+\.[^\s@]+$/) {
        return { error => 'Invalid email format' };
    }

    # Placeholder for actual mail sending logic
    # (e.g., using Email::Stuffer, Mojo::Mail, or MIME::Lite)
    # my $result = send_mail(...);

    return 1;
    # better would be   return { success => 1 };
}



my $hs;  # reuse object to avoid recreating it every call

sub html_strip {
    my ($html) = @_;
    return '' unless defined $html && length $html;

    # Lazily initialize the HTML::Strip object
    $hs //= HTML::Strip->new(emit_spaces => 0);

    my $text = $hs->parse($html);
    $hs->eof;  # reset internal buffer
    return $text;
}


sub linkExtor {
    my $urlfile = 'url-report.txt';
    return unless -f $urlfile;

    open my $fh, '<:encoding(UTF-8)', $urlfile
      or warn "Could not open file '$urlfile': $!" and return;

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);  # avoid hanging requests
    $ua->agent("linkExtor/1.0");

    while (my $url = <$fh>) {
        chomp $url;
        next unless $url;

        my @imgs;
        my $callback = sub {
            my ($tag, %attr) = @_;
            return unless $tag eq 'img';
            push @imgs, $attr{src} if exists $attr{src};
        };

        my $p = HTML::LinkExtor->new($callback);

        my $res = eval { $ua->request(HTTP::Request->new(GET => $url), sub { $p->parse($_[0]) }) };
        if ($@) {
            warn "Failed to fetch $url: $@";
            next;
        }

        if ($res->is_success) {
            print "Images from $url:\n";
            print join("\n", @imgs), "\n\n" if @imgs;
        } else {
            warn "Request failed for $url: " . $res->status_line;
        }
    }

    close $fh;
}


# -----------------------------
# Linkify with safe city lookup
# -----------------------------
sub linkify {
    my ($str, $c) = @_;
    my $lstr   = '';
    my $cities = [];

    while ($str =~ /(.*?)\[(.*?)\](.*)/sm) {
        my ($name, $id) = split /-/, $2;

        # Safe call: stub if Cities module not available
        my $city = eval { TravellersPalm::Database::Cities::city($id, $c) } || {
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
    my ($tz) = @_;
    $tz //= 'Asia/Kolkata';
    return DateTime->now(time_zone => $tz);
    # for logging use  DateTime->now(time_zone => $tz)->strftime('%Y-%m-%d %H:%M:%S');
}


# -----------------------------
# SEO helper
# -----------------------------
sub seo {
    my ($url, $data) = @_;
    $data //= {};

    # Ensure values are defined strings
    my %fields = map { $_ => ($data->{$_} // '') } qw(meta_title meta_descr meta_keywords);

    # Map keys to user-friendly labels
    my %labels = (
        meta_title    => 'title',
        meta_descr    => 'description',
        meta_keywords => 'keywords',
    );

    my $out = "$url\n";
    for my $key (qw(meta_title meta_descr meta_keywords)) {
        $out .= sprintf "   %-12s = %s\n", $labels{$key}, $fields{$key};
    }
    $out .= "\n";

    return $out;
}


sub trim {
    my ($str) = @_;
    return '' unless defined $str && length $str;

    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub validate_date {
    my ($date) = @_;
    return 0 unless defined $date && length $date;

    my $dd  = Date::Manip::Date->new;
    my $err = $dd->parse($date);

    return $err ? 0 : 1;
}

sub valid_email {
    my ($address, $c) = @_;
    return 0 unless defined $address ;
    return Email::Valid->address($address) ? 1 : 0;
}

sub url2text {
    my ($text) = @_;
    return '' unless defined $text && length $text;

    $text =~ tr/-_/  /;                 # also treat underscores as spaces
    $text =~ s/\s+/ /g;                 # collapse multiple spaces
    # $text =~ s/([\w']+)/\u\L$1/g;       # Title Case
    $text =~ s/\s+$//;                  # trim trailing space

    return $text;
}

sub user_is_registered {
    my ($c) = @_;
    return !!$c->session('username'); 
}

sub user_register {
    my ($email, $c) = @_;          # $c is the Mojolicious controller
    return unless valid_email($email);
    $c->session(username => $email);  # set session in Mojolicious
}

sub user_email {
    my ($c) = @_;
    return $c->session('username') // '';
}

sub weeknumber {
    my $date = shift // '';
    return undef unless $date =~ m{^(\d{1,2})/(\d{1,2})/(\d{4})$};
    
    my ($month, $day, $year) = ($1, $2, $3);
    
    my $epoch = eval { timelocal(0,0,0, $day, $month-1, $year-1900) };
    return undef if $@;
    
    return strftime("%U", localtime($epoch));  # week starting Sunday
}


1;