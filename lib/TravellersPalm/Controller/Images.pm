package TravellersPalm::Controller::Images;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use File::Spec;

sub serve_image ($self) {
    # Get the requested path from the wildcard
    my ($path) = @{ $self->stash('splat') // [] };
    return $self->render(text => 'No image specified', status => 400) unless $path;

    # Construct full file path under public/images
    my $file = File::Spec->catfile($self->app->home, 'public', 'images', $path);

    if (-f $file) {
        return $self->reply->file($file);
    } else {
        $self->render(template => '404', status => 404);
    }
}

1;
