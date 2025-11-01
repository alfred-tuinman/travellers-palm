# cpanfile for Perl module dependencies
# See https://metacpan.org/pod/distribution/cpanminus/bin/cpanfile

requires 'Cache::Memcached';
requires 'CHI';
requires 'CHI::Driver::Memcached';
requires 'DateTime';
requires 'DateTime::TimeZone';
requires 'Date::Calc';
requires 'Date::Manip::Date';
requires 'Data::FormValidator';
requires 'Data::Dumper';
requires 'DBI';
requires 'DBD::SQLite';
requires 'Email::Stuffer';
requires 'Email::Valid';
requires 'Email::Sender::Transport::SMTP';
requires 'Email::Sender';
# SMTP Authentication modules (may require system libraries)
requires 'Digest::HMAC_MD5';
requires 'Digest::MD5';
requires 'MIME::Base64';
requires 'Net::SMTP';
requires 'Email::MIME';
requires 'MIME::QuotedPrint';
# Note: Authen::SASL modules installed separately due to system dependencies
# requires 'Authen::SASL::Perl';
# requires 'Authen::SASL';
requires 'MIME::Base32';
requires 'Digest::SHA';
requires 'URI::Escape';
requires 'Exporter';
requires 'File::Copy';
requires 'File::Spec';
requires 'Geo::Location::TimeZone';
requires 'HTML::LinkExtor';
requires 'HTML::Strip'; 
requires 'HTTP::BrowserDetect';
requires 'HTTP::Request';
requires 'JSON';
requires 'LWP::UserAgent';
requires 'Math::Polygon';
requires 'Mojo::JSON';
requires 'Mojo::Log';
requires 'Mojolicious';
requires 'Mojolicious::Plugin::Cache';
requires 'Mojolicious::Plugin::TtRenderer';
requires 'Mojolicious::Plugin::YamlConfig';
requires 'POSIX';
requires 'Sys::Hostname';
requires 'Template::Plugin::Comma';
requires 'Term::ANSIColor';
requires 'Time::HiRes';
requires 'Time::Local';
requires 'YAML::XS';
requires 'Try::Tiny';

# Optional SASL authentication modules (recommended for Gmail SMTP)
# These may fail to install in some environments but email can still work
feature 'sasl', 'SASL authentication for email' => sub {
    requires 'Authen::SASL';
    requires 'Authen::SASL::Perl';
};
