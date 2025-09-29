package TravellersPalm::Database::Users;

use strict;
use warnings;
use Dancer2 appname => 'TravellersPalm';
use TravellersPalm::Database::Connector qw();
use Exporter 'import';

our @EXPORT_OK = qw( 
    user_exist
    user_insert
    user_ok
    user_update   
    );

=cut
sub user_exist {

    my $user = shift;

    my $qry = "
            SELECT  rowid,
                    username 
            FROM    users 
            WHERE   username LIKE ? ";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($user);
            my $rows = $sth->rows;
            $sth->finish;

            return $rows;
}
=cut

sub user_insert {

    use DateTime;

    my $emailid = shift;

    my $qry = "INSERT INTO users ( username, active, registeredon ) VALUES ( ?, ?, ? )";
    my $sth = database('sqlserver')->prepare($qry);

    my $now = DateTime->now->datetime;
    $now =~ y/T/ /;

    print STDERR Dumper( [ $emailid, 1, $now, ] );

    $sth->execute( $emailid, 1, $now, );

    return;
}

sub user_ok {

    my $username = shift;
    my $password = shift;

    my $qry = "
            SELECT  rowid as rowid 
            FROM    users 
            WHERE   username LIKE ? AND 
                    password LIKE ?";

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute( $username, $password );
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row ? $row : 0;
}

sub user_update {

    my ( $userid, $md5passwd ) = @_;

    my $qry = "UPDATE users SET password = ? WHERE rowid = ?";

    my $sth = database('sqlserver')->prepare($qry);
    $sth->execute( $md5passwd, $userid );
    $sth->finish;

    return 1;
}

1;