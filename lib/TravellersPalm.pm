package TravellersPalm;

use Mojo::Base 'Mojolicious', -signatures;
use File::Copy qw(copy);

use TravellersPalm::Cache;
use TravellersPalm::Database::Connector;
use TravellersPalm::Helpers;
use TravellersPalm::Hooks;
use TravellersPalm::Logger;
use TravellersPalm::Mailer;
use TravellersPalm::Routes;

sub startup ($self) {

    # Load configuration
    my $config = $self->plugin('yaml_config' => {
        file      => 'config.yml',
        stash_key => 'conf',
        class     => 'YAML::XS',
    });
    $self->config($config);
    $self->secrets($config->{secrets});

    # ---------------------------------------------------------------
    # Determine the main (first) database entry dynamically
    # ---------------------------------------------------------------
    my $dbs = $config->{databases} || {};
    my ($db_key) = keys %$dbs;
    die "No databases configured in config.yml" unless $db_key;

    my $dsn = $dbs->{$db_key}{dsn};
    die "Invalid DSN for '$db_key'" unless $dsn =~ m{dbname=(.+)$};

    my $seed_db = $1;                       # e.g. /usr/src/app/localdb/Jadoo_2006.db
    my ($db_name) = $seed_db =~ m{([^/]+)$};# e.g. Jadoo_2006.db
    my $data_db  = "data/$db_name";
    my $version_file = "data/db_version.txt";
    my $seed_version = '2025.10.26';         # bump manually when schema changes

    # ---------------------------------------------------------------
    # Initialize database (copy seed if missing or outdated)
    # ---------------------------------------------------------------
    my $needs_seed = 0;
    if ( !-f $data_db ) {
        $needs_seed = 1;
    }
    elsif ( -f $version_file ) {
        open my $fh, '<', $version_file;
        my $current_version = <$fh>;
        chomp $current_version if defined $current_version;
        close $fh;
        $needs_seed = 1 if !$current_version || $current_version ne $seed_version;
    }
    else {
        $needs_seed = 1;
    }

    if ($needs_seed) {
        copy($seed_db, $data_db)
            or die "Failed to initialize DB from $seed_db to $data_db: $!";

        open my $vf, '>', $version_file
            or die "Cannot write $version_file: $!";
        print $vf $seed_version;
        close $vf;

        warn "[TravellersPalm] Database initialized (version $seed_version)\n";
    }

    # ---------------------------------------------------------------
    # Core services
    # ---------------------------------------------------------------
    TravellersPalm::Logger::setup($self);
    TravellersPalm::Database::Connector->setup($self);
    TravellersPalm::Mailer::setup($self);
    TravellersPalm::Cache::setup($self);

    # Helpers, hooks, routes
    TravellersPalm::Helpers::register($self);
    TravellersPalm::Hooks::register($self);
    TravellersPalm::Routes::register($self);

    $self->log->debug("TravellersPalm application started with database '$db_name'");
}

1;
