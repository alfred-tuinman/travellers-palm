package TravellersPalm::Database::Users;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw();

our @EXPORT_OK = qw( 
    user_exist
    user_insert
    user_ok
    user_update 
    update_password 
    generate_pasword 
    update_password 
    register_email);

sub generate_password {

}

sub update_password {

}

sub register_email {

}


sub user_exist {

    my $user = shift;

    my $sql = "
            SELECT  rowid,
                    username 
            FROM    users 
            WHERE   username LIKE ? ";

       return TravellersPalm::Database::Connector::fetch_row( $sql, [$user]);
}

sub user_insert {

    use DateTime;

    my $emailid = shift;

    my $now = DateTime->now->datetime;
    $now =~ y/T/ /;

    my $sql = "INSERT INTO users ( username, active, registeredon ) VALUES ( ?, ?, ? )";
    my $sth = database('sqlserver')->prepare($sql);

    print STDERR Dumper( [ $emailid, 1, $now, ] );

    $sth->execute( $emailid, 1, $now, );

    return;
}

sub user_ok {

    my $username = shift;
    my $password = shift;

    my $sql = "
            SELECT  rowid as rowid 
            FROM    users 
            WHERE   username LIKE ? AND 
                    password LIKE ?";

      my $row = TravellersPalm::Database::Connector::fetch_row( $sql, [$username, $password],,'NAME_lc');
      return $row ? $row : 0;
}

sub user_update {

    my ( $userid, $md5passwd ) = @_;

    my $sql = "UPDATE users SET password = ? WHERE rowid = ?";

    my $sth = database('sqlserver')->prepare($sql);
    $sth->execute( $md5passwd, $userid );
    $sth->finish;

    return 1;
}

1;