package TravellersPalm::Controller::Users;
use strict;
use warnings;
use DBI;
use Template;

sub profile {
    my ($class, $env, $match) = @_;
    my $id = $match->{id};

    my $dbh = DBI->connect("dbi:SQLite:dbname=db/users.db","","",{ RaiseError => 1 });
    my $user = $dbh->selectrow_hashref("SELECT * FROM users WHERE id = ?", undef, $id);

    my $tt = Template->new({ INCLUDE_PATH => 'views' });
    my $output = '';
    $tt->process('user.tt', { user => $user }, \$output)
        or return [500, ['Content-Type'=>'text/plain'], ["Template error: " . $tt->error]];

    return [200, ['Content-Type'=>'text/html'], [$output]];
}

get '/my-account' => sub {

    my $msg;
    my $email;

    if ( user_is_registered() ) {
        $msg = 'You are already registered. 
        Please logout first should you wish to login as a different user';
    }

    template login => {
        metatags => metatags( ( split '/', request->path )[-1] ),
        message => $msg,
    };
};

post '/my-account/register' => sub {

    my $email = params->{email};
    my $pwd   = params->{passw0rd};

    my $msg;

    if ( user_is_registered() ) {
        if ( $email == user_email() ) {
            $msg = 'You are already registered';
        }
        else {
            $msg
            = 'You are already logged in as a different user. Please log out first.';
        }
    }
    else {
        unless ( valid_email($email) ) {
            register_user($email);
            $msg
            = 'You have been succesfully registered. Please check your mail box for our message.';

            my $passwd    = generate_password();
            my $md5passwd = md5_hex($passwd);
            my $success   = update_password($email);

            my $email_msg = MIME::Lite->new(
                                            From =>
                                            'Traveller\'s Palm Administrator <admin@travellers-palm.com>',
                                            To      => $email,
                                            Subject => 'Your request for a Password',
                                            Data    => "Dear User\n\n
                                            Thank you for registering with Traveller's Palm.\n
                                            Following your request, we have generated a password for your use.\n
                                            Please use $passwd to login and use our services.\n\n
                                            Happy Traveling!\n
                                            Traveller's Palm Administrator\n",
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

            return redirect uri_for('my-account/wish-list');
        }
        else {
            $msg = 'You have entered an invalid e-mail id';
        }
    }

    template login => {
        metatags => metatags('login'),
        error    => $msg,
    };
};

post '/my-account/mail-password' => sub {

    my $email = params->{email};

    #use Digest::MD5 qw{md5_hex};
    #use MIME::Lite;
    #use Email::Valid;

    my $passwd    = generate_password();
    my $md5passwd = md5_hex($passwd);

    my $success = user_update( $email, $md5passwd );

    if ( $success == 1 ) {

        my $msg = MIME::Lite->new(
                                  From =>
                                  'Traveller\'s Palm Administrator <admin@travellers-palm.com>',
                                  To      => $email,
                                  Subject => 'Your request for a Password',
                                  Data    => "Dear User\n\n
                                  Thank you for registering with Traveller's Palm.\n
                                  Following your request, we have generated a password for your use.\n
                                  Please use $passwd to login and use our services.\n\n
                                  Happy Traveling!\n
                                  Traveller's Palm Administrator\n",
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

};



1;
