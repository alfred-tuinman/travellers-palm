package TravellersPalm::Database::Core::Initializer;
use strict;
use warnings;
use File::Copy qw(copy move);
use File::Spec;
use File::Temp qw(tempfile);
use File::Path qw(make_path);
use Cwd qw(abs_path);

sub setup {
    my ($app) = @_;

    my $config = $app->config;
    my $dbs = $config->{databases} || {};
    my ($db_key) = keys %$dbs;
    my $dsn = $dbs->{$db_key}{dsn} or die "No DSN for $db_key";

    $dsn =~ m{dbname=(.+)$} or die "Invalid DSN format: $dsn";
    my $seed_db = $1;

    # Resolve and validate seed DB path: must live under localdb/ to avoid accidental copying
    my $seed_abs = abs_path($seed_db) || $seed_db;
    unless ($seed_abs =~ m{\b/localdb/} || $seed_abs =~ m{\blocaldb\b}) {
        die "Refusing to initialize from seed DB outside 'localdb': $seed_db";
    }

    my ($db_name) = $seed_db =~ m{([^/]+)$};
    my $data_db = File::Spec->catfile('data', $db_name);
    my $version_file = File::Spec->catfile('data', 'db_version.txt');

    # Ensure data directory exists with safe permissions
    my $data_dir = File::Spec->catdir('data');
    unless (-d $data_dir) {
        make_path($data_dir, {mode => 0755})
            or die "Failed to create data directory '$data_dir': $!";
    }
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
        # Copy via a temporary file then atomically rename into place to avoid partial files
        my ($tfh, $tmpfile) = tempfile( SUFFIX => '.dbtmp', DIR => $data_dir );
        close $tfh;
        eval {
            copy($seed_db, $tmpfile)
                or die "Failed to copy DB from $seed_db to temp file $tmpfile: $!";
            # try to atomically replace
            rename $tmpfile, $data_db
                or do {
                    # If rename fails (cross-filesystem), try a move (copy+unlink)
                    move($tmpfile, $data_db)
                        or die "Failed to move temp DB $tmpfile to $data_db: $!";
                };
        };
        if ($@) {
            # cleanup temp file if it still exists
            unlink $tmpfile if $tmpfile && -f $tmpfile;
            die $@;
        }

        open my $vf, '>', $version_file or die "Cannot write $version_file: $!";
        print $vf $seed_version;
        close $vf;
        $app->log->info("Database initialized (version $seed_version)");
    }
}

1;
