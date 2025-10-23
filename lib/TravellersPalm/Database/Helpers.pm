package TravellersPalm::Database::Helpers;
use strict;
use warnings;
use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row);
use Data::Dumper;

our @EXPORT_OK = qw(_fetch_row _fetch_all);

sub _fetch_row {
    my ($sql, $bind_ref, $key_style, $dbkey) = @_;
    $bind_ref  //= [];
    $key_style //= 'NAME_lc';
    warn "[DB::Helpers] fetch_row $sql " . Dumper($bind_ref);
    return fetch_row($sql, $bind_ref, $key_style, $dbkey);
}

sub _fetch_all {
    my ($sql, $bind_ref, $dbkey) = @_;
    $bind_ref //= [];
    warn "[DB::Helpers] fetch_all $sql " . Dumper($bind_ref);
    return fetch_all($sql, $bind_ref, $dbkey);
}

sub _execute {
    my ($sql, $bind_ref) = @_;
    $bind_ref //= [];
    warn "[Currencies] execute SQL: $sql, Bind: " . Dumper($bind_ref);
    return execute($sql, $bind_ref);
}

1;
