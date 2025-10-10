package TravellersPalm::Model::Web;

use strict;
use warnings FATAL => 'all';
use Data::Dumper qw(Dumper);
use Exporter 'import';
use TravellersPalm::Database::General qw(web);

our @EXPORT_OK = qw(web);

# Stub: returns sample structure expected by Functions::webtext
sub web {
    my $id = shift;
    return unless $id;

    my $data = web($id);

    print "WEB $id is ".Dumper($data);
    
    return {
        rows => 1,
        data => {
            writeup => $data->{writeup},
            title   => $data->{title},
            pagename => $data->{pagename},
            webpages_id => $data->{webpages_id},
        }
    };
}

1;
