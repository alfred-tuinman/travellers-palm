package TravellersPalm;

use Mojo::Base 'Mojolicious', -signatures;
use Dotenv -load;

use TravellersPalm::Database::Connector;
use TravellersPalm::Logger;
use TravellersPalm::Mailer;
use TravellersPalm::Helpers;
use TravellersPalm::Hooks;
use TravellersPalm::Cache;
use TravellersPalm::Routes;

sub startup ($self) {

    # Load config
    my $config = $self->plugin('yaml_config' => {
        file      => 'config.yml',
        stash_key => 'conf',
        class     => 'YAML::XS',
    });
    $self->config($config);
    $self->secrets($config->{secrets});

    # Core services
    TravellersPalm::Logger::setup($self);
    TravellersPalm::Database::Connector->setup($self);
    TravellersPalm::Mailer::setup($self);
    TravellersPalm::Cache::setup($self);

    # Helpers and hooks
    TravellersPalm::Helpers::register($self);
    TravellersPalm::Hooks::register($self);

    # Routes
    TravellersPalm::Routes::register($self);

    $self->log->debug('TravellersPalm application started successfully');
}

1;
