package TravellersPalm;

use Mojo::Base 'Mojolicious', -signatures;
use TravellersPalm::Database::Core::Connector;
use TravellersPalm::Database::Core::Initializer;
use TravellersPalm::Logger;
use TravellersPalm::Mailer;
use TravellersPalm::Cache;
use TravellersPalm::Routes;
use TravellersPalm::Helpers;
use TravellersPalm::Hooks;

sub startup ($self) {
    my $config = $self->plugin('yaml_config' => {
        file      => 'config.yml',
        stash_key => 'conf',
        class     => 'YAML::XS',
    });

    $self->config($config);
    $self->secrets($config->{secrets});
    $self->plugin('TtRenderer' => {
        template_extension => '.tt',
        template_options   => { ENCODING => 'utf8' },
    });
    $self->renderer->default_handler('tt');

    # Initialize database
    TravellersPalm::Database::Core::Connector->setup($self);
    TravellersPalm::Database::Core::Initializer::setup($self);

    # Core services
    TravellersPalm::Logger::setup($self);
    TravellersPalm::Mailer::setup($self);
    TravellersPalm::Cache::setup($self);
    TravellersPalm::Helpers::register($self);
    TravellersPalm::Hooks::register($self);
    TravellersPalm::Routes::register($self);

    $self->log->debug("TravellersPalm app started successfully");
}

1;
