package TravellersPalm::Database::Initializer;
use strict;
use warnings;
use File::Copy qw(copy);
use File::Spec;

sub setup {
    my ($app) = @_;

    my $config = $app->config;
    my $dbs = $config->{databases} || {};
    my ($db_key) = keys %$dbs;
    my $dsn = $dbs->{$db_key}{dsn} or die "No DSN for $db_key";

    $dsn =~ m{dbname=(.+)$} or die "Invalid DSN format: $dsn";
    my $seed_db = $1;
    my ($db_name) = $seed_db =~ m{([^/]+)$};
    my $data_db = "data/$db_name";
    my $version_file = "data/db_version.txt";
    my $seed_version = '2025.10.26';

    my $needs_seed = !-f $data_db
      || !-f $version_file
      || do {
          open my $fh, '<', $version_file;
          my $v = <$fh>;
          chomp $v if defined $v;
          close $fh;
          !$v || $v ne $seed_version;
      };

    if ($needs_seed) {
        copy($seed_db, $data_db)
            or die "Failed to initialize DB from $seed_db to $data_db: $!";
        open my $vf, '>', $version_file or die "Cannot write $version_file: $!";
        print $vf $seed_version;
        close $vf;
        $app->log->info("Database initialized (version $seed_version)");
    }
}

1;
