package TravellersPalm::Mailer::OAuth2::Transport;

use strict;
use warnings;
use base 'Email::Sender::Transport';
use Email::Sender::Success;

sub new {
    my ($class, $oauth_mailer) = @_;
    my $self = { oauth_mailer => $oauth_mailer };
    return bless $self, $class;
}

sub send_email {
    my ($self, $email, $envelope) = @_;
    
    # Extract email details from the Email::Abstract object
    my $from = $envelope->{from} || $email->get_header('From');
    my $to_list = $envelope->{to} || [$email->get_header('To')];
    my $to = ref($to_list) eq 'ARRAY' ? join(', ', @$to_list) : $to_list;
    my $subject = $email->get_header('Subject') || '';
    my $body = $email->get_body();
    
    # Determine content type
    my $content_type = $email->get_header('Content-Type') || '';
    my $body_type = $content_type =~ /html/i ? 'html' : 'text';
    
    # Send via our OAuth2 mailer
    $self->{oauth_mailer}->send_email(
        from      => $from,
        to        => $to,
        subject   => $subject,
        body      => $body,
        body_type => $body_type,
    );
    
    return Email::Sender::Success->new();
}

1;

__END__

=head1 NAME

TravellersPalm::Mailer::OAuth2::Transport - Email::Sender transport wrapper for OAuth2

=head1 DESCRIPTION

This module provides an Email::Sender::Transport wrapper that allows the OAuth2 
mailer to be used with Email::Stuffer and other Email::Sender-based modules.

=head1 METHODS

=head2 new($oauth_mailer)

Creates a new transport instance wrapping the given OAuth2 mailer.

=head2 send_email($email, $envelope)

Sends an email using the wrapped OAuth2 mailer. This method is called by 
Email::Sender framework.

=cut