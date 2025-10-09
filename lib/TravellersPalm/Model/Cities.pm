# TravellersPalm/Model/Cities.pm
package TravellersPalm::Model::Cities;
use strict;
use warnings FATAL => 'all';
use Exporter 'import';

our @EXPORT_OK = qw(city web);

sub city {
    my $id = shift;
    # Return safe structure if database not loaded
    return {
        id => $id,
        name => "City $id",
        url => "/cities/city-$id.html",
        latitude => 0,
        longitude => 0,
        writeup => "Writeup for city $id",
    };
}

sub web {
    my $id = shift;
    return {
        rows => 1,
        data => {
            writeup => "Sample writeup for web($id)",
            title   => "Web page $id",
            url     => "/web/$id.html",
        },
    };
}

1;
