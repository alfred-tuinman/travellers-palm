package TravellersPalm::Model::Web;

use strict;
use warnings FATAL => 'all';
use Exporter 'import';

our @EXPORT_OK = qw(web);

# Stub: returns sample structure expected by Functions::webtext
sub web {
    my $id = shift;

    # Simulate a database/web fetch
    return {
        rows => 1,
        data => {
            writeup => "Sample writeup for web id $id",
            title   => "Sample Title",
            meta_title => "Meta Title",
            meta_descr => "Meta description",
            meta_keywords => "keyword1, keyword2",
        }
    };
}

1;
