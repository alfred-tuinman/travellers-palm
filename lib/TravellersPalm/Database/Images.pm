package TravellersPalm::Database::Images;

use strict;
use warnings;

use Data::Dumper;
use Exporter 'import';
use TravellersPalm::Database::Connector qw( delete_row fetch_all fetch_row insert_row update_row);

our @EXPORT_OK = qw(
    imageproperties
    imageproperties_id
    image
    images
    imagesall
    images_delete
    images_dropdown
    images_update
    imgupload_type
);


# -----------------------------
# Get image properties by category and type
# -----------------------------
sub imageproperties {
    my ($imgcat, $imgtype, $c) = @_;
    return {} unless defined $imgcat && defined $imgtype;

    my $sql = q{
        SELECT imageproperties_id AS imagecategories_id,
               imagetypes_id,
               imagepattern,
               imagewidth,
               imageheight,
               imagecategories_id
        FROM imageproperties
        WHERE imagecategories_id = ? AND imagetypes_id = ?
    };
    return fetch_row($sql, [$imgcat, $imgtype], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get image properties by ID
# -----------------------------
sub imageproperties_id {
    my ($id, $c) = @_;
    return {} unless defined $id;

    my $sql = q{
        SELECT imageproperties_id AS imagecategories_id,
               imagetypes_id,
               imagepattern,
               imagewidth,
               imageheight,
               imagecategories_id
        FROM imageproperties
        WHERE imageproperties_id = ?
    };
    return fetch_row($sql, [$id], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get single image by name
# -----------------------------
sub image {
    my ($image_name, $c) = @_;
    return {} unless defined $image_name;

    my $sql = q{
        SELECT images_id,
               imagename,
               width,
               height,
               category,
               title,
               alttag,
               srno,
               imagecategories_id,
               filesize,
               type,
               imageobjectid,
               imagetypes_id
        FROM images
        WHERE imagename LIKE ?
        LIMIT 1
    };
    return fetch_row($sql, [$image_name], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get multiple images by object/category/type
# -----------------------------
sub images {
    my ($id, $category, $type, $c) = @_;
    $id       //= 0;
    $category //= 0;
    $type     //= 0;

    # Map string names to category/type IDs
    my %cat_map = (
        city       => 1,
        hotel      => 2,
        module     => 3,
        'ready tour' => 4,
        state      => 5,
    );
    my %type_map = (
        collage      => 2,
        defaulthotel => 3,
        large        => 4,
        main         => 5,
        small        => 6,
    );

    $category = $cat_map{lc $category} // $category;
    $type     = $type_map{lc $type}    // $type;

    my $sql = q{
        SELECT width, height, title, alttag, filesize, imagename,
               imageobjectid, imagecategories_id, imagetypes_id
        FROM images
        WHERE imageobjectid = ? AND imagecategories_id = ? AND imagetypes_id = ?
        ORDER BY imagename
        LIMIT 10
    };
    return fetch_all($sql, [$id, $category, $type], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get all images in a category
# -----------------------------
sub imagesall {
    my ($id, $c) = @_;
    return [] unless defined $id;

    my $sql = q{
        SELECT imagename AS imagename, ImageName2 AS imagename2
        FROM images
        WHERE ImageCategories_id = ?
        ORDER BY imagename
    };
    return fetch_all($sql, [$id], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Delete image by name
# -----------------------------
sub images_delete {
    my ($image_name, $c) = @_;
    return unless defined $image_name;

    my $res = TravellersPalm::Database::Connector::delete_row(
      "DELETE FROM images WHERE imagename LIKE ?", 
      [$image_name], 'NAME', 'jadoo', $c
    );
}

# -----------------------------
# Get images for dropdown
# -----------------------------
sub images_dropdown {
    my ($c) = @_;
    my $sql = q{
        SELECT imagefolder,
               (SELECT imagetype FROM imagetypes WHERE imagetypes_id = p.imagetypes_id) AS imagetype,
               ImageCategories_Id,
               ImagePattern,
               ImageWidth,
               ImageHeight,
               ImageProperties_id
        FROM ImageProperties p
        ORDER BY imagefolder
    };
    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Insert or update image
# -----------------------------
sub images_update {
    my (%args, $c) = @_;

    # defaults
    %args = (
        alttag             => '',
        filesize           => 0,
        height             => 0,
        imagecategories_id => 0,
        imagename          => '',
        imageobjectid      => 0,
        images_id          => 0,
        imagetypes_id      => 0,
        srno               => 0,
        title              => '',
        tineye             => 0,
        width              => 0,
        %args,
    );

    return { status => 0, message => 'Missing image name' } unless $args{imagename};

    my $onfile = image(lc $args{imagename});

    # -----------------------------
    # UPDATE
    # -----------------------------
    if ($onfile && ref $onfile eq 'HASH' && $onfile->{images_id}) {
        my @fields;
        my @values;

        for my $col (qw(imagename imagecategories_id imagetypes_id width height filesize alttag title srno imageobjectid tineye)) {
            next unless defined $args{$col};
            push @fields, "$col = ?";
            push @values, $args{$col};
        }

        push @values, $onfile->{images_id};

        my $res = TravellersPalm::Database::Connector::update_row(
          "UPDATE images SET " . join(", ", @fields) . " WHERE images_id = ?", 
          \@values, 'NAME', 'jadoo', $c
        );
        return { status => $res, message => lc $args{imagename} . ' updated' };
    }

    # -----------------------------
    # INSERT
    # -----------------------------
    my @cols;
    my @placeholders;
    my @values;

    for my $col (qw/imagename imagecategories_id imagetypes_id width height filesize 
                    alttag title srno imageobjectid tineye/) {
        next unless defined $args{$col};
        push @cols, $col;
        push @placeholders, '?';
        push @values, $args{$col};
    }

    my $sql = sprintf("INSERT INTO images (%s) VALUES (%s)", join(',', @cols), join(',', @placeholders));
    my $res = TravellersPalm::Database::Connector::insert_row($sql, \@values, 'NAME', 'jadoo', $c);

    return { status => $res, message => lc $args{imagename} . ' inserted' };
}

# -----------------------------
# Get image upload types for a category
# -----------------------------
sub imgupload_type {
    my ($imgcat, $c) = @_;
    return [] unless defined $imgcat;

    my $sql = qq/SELECT t.imagetypes_id, t.imagetype FROM imagetypes t/;
    if ($imgcat > 0) {
        $sql .= qq/ INNER JOIN imageproperties p ON t.imagetypes_id = p.imagetypes_id 
        WHERE p.imagecategories_id = ?/;
        return fetch_all($sql, [$imgcat]);
    }

    return fetch_all($sql,[], 'NAME', 'jadoo', $c);
}

1;
