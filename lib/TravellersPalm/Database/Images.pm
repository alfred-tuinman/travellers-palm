package TravellersPalm::Database::Images;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw();

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


sub imageproperties {
    my ( $imgcat, $imgtype ) = @_;

    if ( defined($imgcat) and defined($imgtype) ) {

        my $sql = '
                SELECT  imageproperties_id  as imagecategories_id,
                        imagetypes_id       as imagetypes_id, 
                        imagepattern        as imagepattern, 
                        imagewidth          as imagewidth, 
                        imageheight         as imageheight,
                        imagecategories_id  as imagecategories_id
                FROM    imageproperties 
                WHERE   imagecategories_id = ? AND 
                        imagetypes_id = ?';

      return TravellersPalm::Database::Connector::fetch_row( $sql, [$imgcat, $imgtype],,'NAME_lc');
    }
    return 0;
}

sub imageproperties_id {
    my $id = shift // 0;

    my $sql = '
            SELECT  imageproperties_id  as imagecategories_id,
                    imagetypes_id       as imagetypes_id, 
                    imagepattern        as imagepattern, 
                    imagewidth          as imagewidth, 
                    imageheight         as imageheight,
                    imagecategories_id  as imagecategories_id
            FROM    imageproperties 
            WHERE   imageproperties_id = ?';

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$id],,'NAME_lc');
}

sub image {

    my $imagename = shift;

    my $sql = '
            SELECT  images_id,
                    imagename           as imagename, 
                    width               as width, 
                    height              as height,
                    category            as category,
                    title               as title,
                    alttag              as alttag,
                    srno                as srno,
                    imagecategories_id  as imagecategories_id,
                    filesize            as filesize,
                    type                as type,
                    imageobjectid       as imageobjectid,
                    imagetypes_id       as imagetypes_id
            FROM    images 
            WHERE   imagename like ?';

    return TravellersPalm::Database::Connector::fetch_row( $sql, [$imagename],,'NAME_lc');
    
    return 0;
}


sub images {

    my $id       = shift // 0;
    my $category = shift // 0;
    my $type     = shift // 0;

    my $row;

    $category = 1 if ( lc($category) eq q/city/ );
    $category = 2 if ( lc($category) eq q/hotel/ );
    $category = 3 if ( lc($category) eq q/module/ );
    $category = 4 if ( lc($category) eq q/ready tour/ );
    $category = 5 if ( lc($category) eq q/state/ );
    $type     = 2 if ( lc($type)     eq q/collage/ );
    $type     = 3 if ( lc($type)     eq q/defaulthotel/ );
    $type     = 4 if ( lc($type)     eq q/large/ );
    $type     = 5 if ( lc($type)     eq q/main/ );
    $type     = 6 if ( lc($type)     eq q/small/ );

    eval {
        my $sql = qq/ 
             SELECT  width                as width,
                     height               as height,
                     title                as title,
                     alttag               as alttag,
                     filesize             as filesize,
                     imagename            as imagename,
                     imageobjectid        as imageobjectid,
                     imagecategories_id   as imagecategories_id,
                     imagetypes_id        as imagetypes_id 
             FROM    images 
             WHERE   imageobjectid = ? AND 
                     imagecategories_id = ? AND 
                     imagetypes_id = ? 
             ORDER   BY imagename
             LIMIT   10 ; /;

        return TravellersPalm::Database::Connector::fetch_all( $sql, [$id, $category, $type] );
    };

    print "An error occurred: $@\n" if $@;
    return $row;
}

sub imagesall {

    my $id  = shift // 0;
    my $sql = qq/
            SELECT  imagename       as imagename, 
                    ImageName2      as imagename2
            FROM    images 
            WHERE   ImageCategories_id = $id 
            ORDER   BY imagename/;

    return TravellersPalm::Database::Connector::fetch_all( $sql);
}

sub images_delete {

    my $imagename = shift // 0 ;
    my $sql       = qq/DELETE FROM images WHERE imagename like '$imagename'/ ;
    TravellersPalm::Database::Connector::fetch_row( $sql);
    return;
}

sub images_dropdown 
{
    # used by upload.travellers-palm.com
    # , imagetype, t.imagetypes_id,ImagePattern,imagewidth,imageheight
    my $sql = " SELECT  imagefolder, 
                        (SELECT imagetype FROM imagetypes WHERE imagetypes_id =p.imagetypes_id) as imagetype, 
                        ImageCategories_Id, 
                        ImagePattern,
                        ImageWidth,
                        ImageHeight,
                        ImageProperties_id
                FROM    ImageProperties p 
                ORDER BY imagefolder;";

    return TravellersPalm::Database::Connector::fetch_all( $sql);
}


sub images_update {

    my %args = (
        alttag              => '',
        filesize            => 0,
        height              => 0,
        imagecategories_id  => 0,
        imagename           => '',
        imageobjectid       => 0,
        images_id           => 0,
        imagetypes_id       => 0,
        srno                => 0,
        title               => '',
        tineye              => 0,
        width               => 0,
        @_ ,
        );


    my $onfile = image( lc $args{imagename} );

    if ( ref $onfile eq ref {} ) {

        my $sql = qq(UPDATE images SET imagefolder = ? );
        my @val = () ; 
        push(@val,q/NULL/);

        if (length $args{imagename}    > 0 )   { $sql .= qq( ,imagename           = ? );  push(@val, lc qq($args{imagename})    );} 
        if ($args{imagecategories_id}  > 0 )   { $sql .= qq( ,imagecategories_id  = ? );  push(@val, $args{imagecategories_id}  );}
        if ($args{imagetypes_id}       > 0 )   { $sql .= qq( ,imagetypes_id       = ? );  push(@val, $args{imagetypes_id}       );}
        if ($args{width}               > 0 )   { $sql .= qq( ,width               = ? );  push(@val, $args{width}               );}
        if ($args{height}              > 0 )   { $sql .= qq( ,height              = ? );  push(@val, $args{height}              );}
        if ($args{filesize}            > 0 )   { $sql .= qq( ,filesize            = ? );  push(@val, $args{filesize}            );}
        if (length($args{alttag})      > 0 )   { $sql .= qq( ,alttag              = ? );  push(@val, qq($args{alttag})          );}
        if (length($args{title})       > 0 )   { $sql .= qq( ,title               = ? );  push(@val, qq($args{title})           );} 
        if ($args{srno}                > 0 )   { $sql .= qq( ,srno                = ? );  push(@val, $args{srno}                );}
        if ($args{imageobjectid}       > 0 )   { $sql .= qq( ,imageobjectid       = ? );  push(@val, $args{imageobjectid}       );} 
        if ($args{tineye}             != 0 )   { $sql .= qq( ,tineye              = ? );  push(@val, ($args{tineye} < 0) ? 0: $args{tineye} );} 
        
        if (($args{imagecategories_id} == 1) && length($args{title}) == 0 )  
        { $sql .= qq( ,title  = ? );  push(@val, qq($args{alttag}) );}

        $sql .= qq( WHERE images_id = ?) ;
        push(@val, $onfile->{images_id});

        my $sth = database('sqlserver')->prepare($sql);
        $sth->execute( @val );
        $sth->finish;
        return {
            status  => 1,
            message => lc $args{imagename} . q( updated),
        };
    }
    else {
        # insert
        if (length $args{imagename} > 0) {

            my $sql  = q/imagename/;
            my @val  = (lc qq($args{imagename}) );
            my $plh  = qq(?);
=head
            my @columns = split ( /\s+/, 'imagecategories_id imagetypes_id width height filesize alttag title srno imageobjectid tineye');
            while $column in @columns{
                if( $column eq 'alttag'|| $column eq 'title'){
                    if (length $args{alttag} > 0) 
                        $sql .= qq(,$column);
                        $plh .= q(,?); 
                        push(@val,qq('$args{$column}'));
                    }
                }
                elsif ($args{$column} > 0)   {
                    $sql .= qq(,$column);
                    $plh .= q(,?); 
                    push(@val,$args{$column});
                }; 
            };
=cut
            if ($args{imagecategories_id}   > 0)   {  $sql .= q(,imagecategories_id)    ;  $plh .= q(,?); push(@val,$args{imagecategories_id});    }; 
            if ($args{imagetypes_id}        > 0)   {  $sql .= q(,imagetypes_id)         ;  $plh .= q(,?); push(@val,$args{imagetypes_id});         };
            if ($args{width}                > 0)   {  $sql .= q(,width)                 ;  $plh .= q(,?); push(@val,$args{width});                 };
            if ($args{height}               > 0)   {  $sql .= q(,height)                ;  $plh .= q(,?); push(@val,$args{height});                };
            if ($args{filesize}             > 0)   {  $sql .= q(,filesize)              ;  $plh .= q(,?); push(@val,$args{filesize});              };
            if (length $args{alttag}        > 0)   {  $sql .= q(,alttag)                ;  $plh .= q(,?); push(@val,qq($args{alttag}));            };
            if (length $args{title}         > 0)   {  $sql .= q(,title)                 ;  $plh .= q(,?); push(@val,qq($args{title}));             };
            if ($args{srno}                 > 0)   {  $sql .= q(,srno)                  ;  $plh .= q(,?); push(@val,$args{srno});                  };
            if ($args{imageobjectid}        > 0)   {  $sql .= q(,imageobjectid)         ;  $plh .= q(,?); push(@val,$args{imageobjectid});         };
            if ($args{tineye}              != 0)   {  $sql .= q(,tineye)                ;  $plh .= q(,?); push(@val,($args{tineye} < 0 ) ? 0 : $args{tineye}); };

            $sql = qq(INSERT INTO images ($sql) VALUES ($plh);); 

            my $sth = database('sqlserver')->prepare($sql);
            $sth->execute( @val );
            $sth->finish;
            return {
                status  => 1,
                message => lc $args{imagename} . q( inserted),
            };
        }
        return {
            status  => 0,
            message => 'Request to insert failed: no image name passed',
        };
    }
}


sub imgupload_type {
    my $imgcat = shift // 0;
    my $option = shift // 0;
    
    my $sql = "SELECT t.imagetypes_id,t.imagetype FROM imagetypes t";

    if ($imgcat > 0) {
        $sql .= ' INNER JOIN imageproperties p on t.imagetypes_id=p.imagetypes_id 
        WHERE p.imagecategories_id = ' . $imgcat;
    }

    my $sth = database('sqlserver')->prepare($sql);
    $sth->execute();

    my @results = ();
    while ( my $row = $sth->fetchrow_hashref ) {
        push @results, $row;
    }
    $sth->finish();

    return @results;
}

1;