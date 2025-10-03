package TravellersPalm::Controller::MyAccount;

use strict;
use warnings;

# use Digest::MD5 qw(md5_hex);
use MIME::Lite;

use Exporter 'import';
use Template;
use TravellersPalm::Database::Connector qw(dbh);
use TravellersPalm::Database::General;
use TravellersPalm::Constants qw(:all);
use TravellersPalm::Functions qw(user_email user_is_registered valid_email);

# ------------------------------------
# Actions
# ------------------------------------

sub login {
    my $msg;

    if ( user_is_registered() ) {
        $msg = 'You are already logged in. 
                Please logout first should you wish to login as a different user';
    }

    template('login') => {
        metatags => TravellersPalm::Database::General::metatags( ( split '/', request->path )[-1] ),
        message  => $msg,
    };
}

sub register {
    my $params = params();
    my $email  = $params->{email};
    my $pwd    = $params->{passw0rd};  # currently unused?

    my $msg;

    if (user_is_registered() ) {

        if ( $email eq user_email() ) {
            $msg = 'You are already registered';
        } else {
            $msg = 'You are already logged in as a different user. Please log out first.';
        }

    } else {

        if ( valid_email($email) ) {

            register_user($email);
            $msg = 'You have been succesfully registered. Please check your mail box for our message.';

            my $passwd    = TravellersPalm::Database::Users::generate_password();
            my $md5passwd = Digest::MD5::md5_hex($passwd);

            my $success   = TravellersPalm::Database::Users::update_password($email); # consider passing $md5passwd

            # --- send email ---
            my $email_msg = MIME::Lite->new(
                From    => q{Traveller's Palm Administrator <admin@travellers-palm.com>},
                To      => $email,
                Subject => 'Your request for a Password',
                Data    => <<"END_MESSAGE"
Dear User,

Thank you for registering with Traveller's Palm.
Following your request, we have generated a password for your use.
Please use $passwd to login and use our services.

Happy Traveling!
Traveller's Palm Administrator
END_MESSAGE
            );

            MIME::Lite->send(
                'smtp',
                'mail.travellers-palm.com',
                Timeout  => 30,
                AuthUser => 'admin+travellers-palm.com',
                AuthPass => 'ip31415',
                Debug    => 1,
            );

            $email_msg->send;

            return redirect uri_for('/my-account/wish-list');

        } else {
            $msg = 'You have entered an invalid e-mail id';
        }
    }

    template('login') => {
        metatags => TravellersPalm::Database::General::metatags('login'),
        error    => $msg,
    };
}

sub mail_password {
    my $params    = params();
    my $email     = $params->{email};
    my $passwd    = TravellersPalm::Database::Users::generate_password();
    my $md5passwd = Digest::MD5::md5_hex($passwd);
    my $success   = TravellersPalm::Database::Users::user_update( $email, $md5passwd );

    if ( $success == 1 ) {

        my $msg = MIME::Lite->new(
            From    => q{Traveller's Palm Administrator <admin@travellers-palm.com>},
            To      => $email,
            Subject => 'Your request for a Password',
            Data    => <<"END_MESSAGE"
Dear User,

Thank you for registering with Traveller's Palm.
Following your request, we have generated a password for your use.
Please use $passwd to login and use our services.

Happy Traveling!
Traveller's Palm Administrator
END_MESSAGE
        );

        MIME::Lite->send(
            'smtp',
            'mail.travellers-palm.com',
            Timeout  => 30,
            AuthUser => 'admin+travellers-palm.com',
            AuthPass => 'ip31415',
            Debug    => 1,
        );

        $msg->send;
    }

    # optionally render a confirmation template or redirect
    template('login') => {
        metatags => TravellersPalm::Database::General::metatags('login'),
        message  => 'If your email exists in our records, a new password has been sent.',
    };
}

1;  
