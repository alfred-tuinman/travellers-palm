package TravellersPalm::Database::Images;

use strict;
use warnings;
use Dancer2 appname => 'TravellersPalm';
use TravellersPalm::Database::Connector qw();
use Exporter 'import';

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

        my $qry = '
                SELECT  imageproperties_id  as imagecategories_id,
                        imagetypes_id       as imagetypes_id, 
                        imagepattern        as imagepattern, 
                        imagewidth          as imagewidth, 
                        imageheight         as imageheight,
                        imagecategories_id  as imagecategories_id
                FROM    imageproperties 
                WHERE   imagecategories_id = ? AND 
                        imagetypes_id = ?';

                my $sth = database('sqlserver')->prepare($qry);
                $sth->execute( $imgcat, $imgtype );
                my $row = $sth->fetchrow_hashref('NAME_lc');
                $sth->finish;

                return $row;
    }
    return 0;
}

sub imageproperties_id {
    my $id = shift // 0;

    my $qry = '
            SELECT  imageproperties_id  as imagecategories_id,
                    imagetypes_id       as imagetypes_id, 
                    imagepattern        as imagepattern, 
                    imagewidth          as imagewidth, 
                    imageheight         as imageheight,
                    imagecategories_id  as imagecategories_id
            FROM    imageproperties 
            WHERE   imageproperties_id = ?';

    my $sth = database('sqlserver')->prepare($qry);
    $sth->execute( $id );
    my $row = $sth->fetchrow_hashref('NAME_lc');
    $sth->finish;

    return $row;
}

sub image {

    my $imagename = shift;

    my $qry = '
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

            my $sth = database('sqlserver')->prepare($qry);
            $sth->execute($imagename);
            my $row = $sth->fetchrow_hashref('NAME_lc');
            $sth->finish;

            return $row;
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
        my $qry = qq/ 
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

             my $sth = database('sqlserver')->prepare($qry);
             $sth->execute( $id, $category, $type );
             $row = $sth->fetchall_arrayref( {} );
             $sth->finish;
    };

    print "An error occurred: $@\n" if $@;
    return $row;
}

sub imagesall {

    my $id  = shift // 0;
    my $qry = qq/
            SELECT  imagename       as imagename, 
                    ImageName2      as imagename2
            FROM    images 
            WHERE   ImageCategories_id = $id 
            ORDER   BY imagename/;

            return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub images_delete {

    my $imagename = shift // 0 ;
    my $qry       = qq/DELETE FROM images WHERE imagename like '$imagename'/ ;
    my $sth       = database('sqlserver')->prepare($qry);
    my $ok        = $sth->execute();
    $sth->finish;
    return;
}

sub images_dropdown 
{
    # used by upload.travellers-palm.com
    # , imagetype, t.imagetypes_id,ImagePattern,imagewidth,imageheight
    my $qry = " SELECT  imagefolder, 
                        (SELECT imagetype FROM imagetypes WHERE imagetypes_id =p.imagetypes_id) as imagetype, 
                        ImageCategories_Id, 
                        ImagePattern,
                        ImageWidth,
                        ImageHeight,
                        ImageProperties_id
                FROM    ImageProperties p 
                ORDER BY imagefolder;";

    my $data = database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
    return $data;
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

        my $qry = qq(UPDATE images SET imagefolder = ? );
        my @val = () ; 
        push(@val,q/NULL/);

        if (length $args{imagename}    > 0 )   { $qry .= qq( ,imagename           = ? );  push(@val, lc qq($args{imagename})    );} 
        if ($args{imagecategories_id}  > 0 )   { $qry .= qq( ,imagecategories_id  = ? );  push(@val, $args{imagecategories_id}  );}
        if ($args{imagetypes_id}       > 0 )   { $qry .= qq( ,imagetypes_id       = ? );  push(@val, $args{imagetypes_id}       );}
        if ($args{width}               > 0 )   { $qry .= qq( ,width               = ? );  push(@val, $args{width}               );}
        if ($args{height}              > 0 )   { $qry .= qq( ,height              = ? );  push(@val, $args{height}              );}
        if ($args{filesize}            > 0 )   { $qry .= qq( ,filesize            = ? );  push(@val, $args{filesize}            );}
        if (length($args{alttag})      > 0 )   { $qry .= qq( ,alttag              = ? );  push(@val, qq($args{alttag})          );}
        if (length($args{title})       > 0 )   { $qry .= qq( ,title               = ? );  push(@val, qq($args{title})           );} 
        if ($args{srno}                > 0 )   { $qry .= qq( ,srno                = ? );  push(@val, $args{srno}                );}
        if ($args{imageobjectid}       > 0 )   { $qry .= qq( ,imageobjectid       = ? );  push(@val, $args{imageobjectid}       );} 
        if ($args{tineye}             != 0 )   { $qry .= qq( ,tineye              = ? );  push(@val, ($args{tineye} < 0) ? 0: $args{tineye} );} 
        
        if (($args{imagecategories_id} == 1) && length($args{title}) == 0 )  
        { $qry .= qq( ,title  = ? );  push(@val, qq($args{alttag}) );}

        $qry .= qq( WHERE images_id = ?) ;
        push(@val, $onfile->{images_id});

        my $sth = database('sqlserver')->prepare($qry);
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

            my $qry  = q/imagename/;
            my @val  = (lc qq($args{imagename}) );
            my $plh  = qq(?);
=head
            my @columns = split ( /\s+/, 'imagecategories_id imagetypes_id width height filesize alttag title srno imageobjectid tineye');
            while $column in @columns{
                if( $column eq 'alttag'|| $column eq 'title'){
                    if (length $args{alttag} > 0) 
                        $qry .= qq(,$column);
                        $plh .= q(,?); 
                        push(@val,qq('$args{$column}'));
                    }
                }
                elsif ($args{$column} > 0)   {
                    $qry .= qq(,$column);
                    $plh .= q(,?); 
                    push(@val,$args{$column});
                }; 
            };
=cut
            if ($args{imagecategories_id}   > 0)   {  $qry .= q(,imagecategories_id)    ;  $plh .= q(,?); push(@val,$args{imagecategories_id});    }; 
            if ($args{imagetypes_id}        > 0)   {  $qry .= q(,imagetypes_id)         ;  $plh .= q(,?); push(@val,$args{imagetypes_id});         };
            if ($args{width}                > 0)   {  $qry .= q(,width)                 ;  $plh .= q(,?); push(@val,$args{width});                 };
            if ($args{height}               > 0)   {  $qry .= q(,height)                ;  $plh .= q(,?); push(@val,$args{height});                };
            if ($args{filesize}             > 0)   {  $qry .= q(,filesize)              ;  $plh .= q(,?); push(@val,$args{filesize});              };
            if (length $args{alttag}        > 0)   {  $qry .= q(,alttag)                ;  $plh .= q(,?); push(@val,qq($args{alttag}));            };
            if (length $args{title}         > 0)   {  $qry .= q(,title)                 ;  $plh .= q(,?); push(@val,qq($args{title}));             };
            if ($args{srno}                 > 0)   {  $qry .= q(,srno)                  ;  $plh .= q(,?); push(@val,$args{srno});                  };
            if ($args{imageobjectid}        > 0)   {  $qry .= q(,imageobjectid)         ;  $plh .= q(,?); push(@val,$args{imageobjectid});         };
            if ($args{tineye}              != 0)   {  $qry .= q(,tineye)                ;  $plh .= q(,?); push(@val,($args{tineye} < 0 ) ? 0 : $args{tineye}); };

            $qry = qq(INSERT INTO images ($qry) VALUES ($plh);); 

            my $sth = database('sqlserver')->prepare($qry);
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
    
    my $qry = "SELECT t.imagetypes_id,t.imagetype FROM imagetypes t";

    if ($imgcat > 0) {
        $qry .= ' INNER JOIN imageproperties p on t.imagetypes_id=p.imagetypes_id 
        WHERE p.imagecategories_id = ' . $imgcat;
    }

    my $sth = database('sqlserver')->prepare($qry);
    $sth->execute();

    my @results = ();
    while ( my $row = $sth->fetchrow_hashref ) {
        push @results, $row;
    }
    $sth->finish();

    return @results;
}

1;