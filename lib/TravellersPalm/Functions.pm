package TravellersPalm::Functions;

use strict;
use warnings FATAL => 'all';
use Exporter 'import';

use Email::Valid;
use Geo::Location::TimeZone;
use HTTP::BrowserDetect;
use DateTime;
use Time::Local;
use Date::Calc qw/ Delta_Days check_date check_time /;
use Data::Dumper;
use POSIX qw(strftime);
use HTML::Strip;

our @EXPORT_OK = qw{
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

our $VERSION = '1.00';

# ---------------------------
# Text utility functions
# ---------------------------

sub addptags {
    my $str = shift or return '<p></p>';
    my @lines = split /\r?\n|\x0C|\x{2028}|\x{2029}/, $str;
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

sub trim {
    my $str = shift;
    $str =~ s/^\s+|\s+$//g;
    return $str;
}

sub html_strip {
    my $html = shift;
    my $hs   = HTML::Strip->new(emit_spaces => 0);
    my $text = $hs->parse($html);
    $hs->eof;
    return $text;
}

sub url2text {
    my $text = shift;
    $text =~ tr/-/ /;
    $text =~ s/([\w']+)/\u\L$1/g;
    return $text;
}

# ---------------------------
# Time / Date utilities
# ---------------------------

sub ourtime {
    return DateTime->now(time_zone => 'Asia/Kolkata');
}

sub weeknumber {
    my $date = shift;
    my ($month, $day, $year) = split '/', $date;
    my $epoch = timelocal(0, 0, 0, $day, $month - 1, $year - 1900);
    return strftime("%U", localtime($epoch));
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

# ---------------------------
# User session helpers (Mojolicious requires passing $c)
# ---------------------------

sub user_is_registered {
    my $c = shift;  # Mojolicious controller
    return $c->session('username') ? 1 : 0;
}

sub user_register {
    my ($c, $email) = @_;
    return unless valid_email($email);
    $c->session(username => $email);
}

sub user_email {
    my $c = shift;
    return $c->session('username');
}

# ---------------------------
# SEO & web text helpers
# ---------------------------

sub seo {
    my ($url, $data) = @_;
    $data //= {};
    return sprintf(
        "%s\n   title       = %s\n   description = %s\n   keywords    = %s\n\n",
        $url,
        $data->{meta_title} // '',
        $data->{meta_descr} // '',
        $data->{meta_keywords} // ''
    );
}

# ---------------------------
# Other utilities
# ---------------------------

sub addptags {
    # replace certain characters with <p> tags
    return '<p></p>' unless ( my $str = shift );

    my @lines = split m { (?:\x0D \x0A | \x0A | \x0D | \x0C | \x{2028} | \x{2029} ) }x, $str;

    return '<p>' . join( '</p><p>', @lines ) . '</p>';
}

sub elog  {

    my $url = shift;

    my @imgnames = ();
    my $log      = '/var/log/nginx/travellers-palm/error.log';

    open(my $fh, '<:encoding(UTF-8)', $log) || die "Cannot open log file: $!";

    while(my $line = <$fh>) {

        if ($line =~ /failed/) {
            my @result = split(/"/,$line);
            push(@imgnames,{ message => $result[1] });
        }
    }

    close($fh);
    return \@imgnames;
}

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
# maybe pass $c above if needed

1;
