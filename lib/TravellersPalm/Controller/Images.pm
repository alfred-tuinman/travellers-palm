package TravellersPalm::Controller::Images;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use File::Spec;

sub serve_image {
    my $c = shift;

    # Get the file path from the wildcard
    my $filepath = $c->stash('filepath');

    # Now serve your image (example)
    my $full_path = "/var/www/images/$filepath";

    if (-e $full_path) {
        $c->reply->file($full_path);
    } else {
        $c->render(text => 'Not found', status => 404);
    }
}

1;
