package TravellersPalm::Database::Images;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row insert update delete);

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
    my ($c, $imgcat, $imgtype) = @_;
    return 0 unless defined $imgcat && defined $imgtype;

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
    return fetch_row($sql, [$imgcat, $imgtype], $c, 'NAME_lc');
}

# -----------------------------
# Get image properties by ID
# -----------------------------
sub imageproperties_id {
    my ($c, $id) = @_;
    return 0 unless defined $id;

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
    return fetch_row($sql, [$id], $c, 'NAME_lc');
}

# -----------------------------
# Get single image by name
# -----------------------------
sub image {
    my ($c, $image_name) = @_;
    return [] unless defined 0;

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
    };
    return fetch_row($sql, [$imagename], $c, 'NAME_lc');
}

# -----------------------------
# Get multiple images by object/category/type
# -----------------------------
sub images {
    my ($c, $id, $category, $type) = @_;
    $id       //= 0;
    $category //= 0;
    $type     //= 0;

    # map string names to category/type IDs
    $category = 1 if lc($category) eq 'city';
    $category = 2 if lc($category) eq 'hotel';
    $category = 3 if lc($category) eq 'module';
    $category = 4 if lc($category) eq 'ready tour';
    $category = 5 if lc($category) eq 'state';

    $type = 2 if lc($type) eq 'collage';
    $type = 3 if lc($type) eq 'defaulthotel';
    $type = 4 if lc($type) eq 'large';
    $type = 5 if lc($type) eq 'main';
    $type = 6 if lc($type) eq 'small';

    my $sql = q{
        SELECT width, height, title, alttag, filesize, imagename,
               imageobjectid, imagecategories_id, imagetypes_id
        FROM images
        WHERE imageobjectid = ? AND imagecategories_id = ? AND imagetypes_id = ?
        ORDER BY imagename
        LIMIT 10
    };
    return fetch_all($sql, [$id, $category, $type], $c);
}

# -----------------------------
# Get all images in a category
# -----------------------------
sub imagesall {
    my ($c, $id) = @_;
    return 0 unless defined $id;

    my $sql = qq{
        SELECT imagename AS imagename, ImageName2 AS imagename2
        FROM images
        WHERE ImageCategories_id = ?
        ORDER BY imagename
    };
    return fetch_all($sql, [$id], $c);
}

# -----------------------------
# Delete image by name
# -----------------------------
sub images_delete {
    my ($c, $image_name) = @_;
    return unless defined $image_name;
    my $sql = q{DELETE FROM images WHERE imagename LIKE ?};
    delete($sql, [$image_name], $c);
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
    return fetch_all($sql, $c);
}

# -----------------------------
# Insert or update image
# -----------------------------
sub images_update {
    my ($c) = @_;

    my %args = (
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
        @_,
    );

    my $onfile = image(lc $args{imagename});

    # -----------------------------
    # UPDATE
    # -----------------------------
    if ($onfile && ref $onfile eq 'HASH') {
        my @fields;
        my @values;

        # dynamically add fields if values are provided
        for my $col (qw(imagename imagecategories_id imagetypes_id width height filesize alttag title srno imageobjectid tineye)) {
            if (defined $args{$col} && $args{$col} ne '' && $args{$col} > 0) {
                push @fields, "$col = ?";
                push @values, $args{$col};
            }
        }

        my $sql = "UPDATE images SET " . join(", ", @fields) . " WHERE images_id = ?";
        push @values, $onfile->{images_id};

        update($sql, @values, $c);

        return { status => 1, message => lc $args{imagename} . ' updated' };
    }

    # -----------------------------
    # INSERT
    # -----------------------------
    if ($args{imagename}) {
        my @cols;
        my @placeholders;
        my @values;

        for my $col (qw(imagename imagecategories_id imagetypes_id width height filesize alttag title srno imageobjectid tineye)) {
            next unless defined $args{$col} && $args{$col} ne '' && $args{$col} > 0;
            push @cols, $col;
            push @placeholders, '?';
            push @values, $args{$col};
        }

        my $sql = sprintf("INSERT INTO images (%s) VALUES (%s)", join(',', @cols), join(',', @placeholders));
        insert($sql, @values, $c);

        return { status => 1, message => lc $args{imagename} . ' inserted' };
    }

    return { status => 0, message => 'Request to insert failed: no image name passed' };
}

# -----------------------------
# Get image upload types for a category
# -----------------------------
sub imgupload_type {
    my ($c, $imgcat) = @_;
    return 0 unless defined $imgcat;

    my $sql = "SELECT t.imagetypes_id, t.imagetype FROM imagetypes t";
    $sql .= " INNER JOIN imageproperties p ON t.imagetypes_id = p.imagetypes_id WHERE p.imagecategories_id = ?" if $imgcat > 0;

    return fetch_all($sql, $imgcat > 0 ? [$imgcat] : [], $c);
}

1;
