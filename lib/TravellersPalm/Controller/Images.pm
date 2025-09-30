package TravellersPalm::Controller::Images;
use Dancer2;
use File::Spec;

# Catch all image requests under / (like /home/sucheta.jpg)
get qr{^/([^/]+/.+)} => sub {
    my $path = $1;  # e.g., home/sucheta.jpg
    my $file = File::Spec->catfile(config->{public_dir}, 'images', $path);

    if (-f $file) {
        return send_file $file;
    }
    status 'not_found';
    return "File not found";
};

1;
