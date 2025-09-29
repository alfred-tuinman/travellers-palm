package TravellersPalm::Database::Currencies;

use strict;
use warnings;
use Dancer2 appname => 'TravellersPalm';
use TravellersPalm::Database::Connector qw();
use Exporter 'import';

our @EXPORT_OK = qw( 
    currencies 
    currency 
    exchangerate 
    exchange_rates 
    exchange_rates_historical 
    exchange_rates_update
    );


sub currencies {

    my $currencycode = shift // '';
       $currencycode = uc $currencycode ;
    my $option       = (length $currencycode > 0 ) ? " AND currencycode like '$currencycode' " : '';

    my $qry = qq/
        SELECT currencycode, currency, symbol, c.currencies_id, wef 
        FROM 
        (
            SELECT   currencies_id, max(wef) wef
            FROM     currencydetails
            GROUP BY currencies_id
        ) temp  
        JOIN currencies c ON c.currencies_id = temp.currencies_id 
        WHERE c.hdfccode IS NOT NULL $option 
        ORDER BY currencycode;/;

        return database('sqlserver')->selectall_arrayref( $qry, { Slice => {} } );
}

sub currency {
    my $newcurrency = shift ;
    my $currency    = 'USD';

    if ( defined $newcurrency ) {
        my $exist = currencies($newcurrency);
        if (scalar $exist) {
            $currency = $newcurrency;
        }
    }
    return $currency;
}


sub exchangerate {

    my $currencycode = shift;

    return 0 unless $currencycode;

    my $qry = "
        SELECT  exchangerate 
        FROM    currencydetails d
                RIGHT JOIN currencies c ON c.currencies_id = d.currencies_id
        WHERE   currencycode = '$currencycode'
        ORDER   BY wef DESC
                LIMIT 1;";

        my $data = database('sqlserver')->selectrow_array( $qry, { Slice => {} } );
        return $data;
}

sub exchange_rates {

    my $qry = "
        SELECT  currency, exchange_rate, strftime('%d/%m/%Y',datetime(date, 'unixepoch')) as date
        FROM    exchange_rates
        WHERE   strftime('%d/%m/%Y',datetime(date, 'unixepoch')) = strftime('%d/%m/%Y','now')
        ORDER BY currency DESC;";

    return database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ); 
}

sub exchange_rates_historical {

    my $qry = "
        SELECT  currency, strftime('%d/%m/%Y',datetime(date, 'unixepoch')) as date, exchange_rate 
        FROM    exchange_rates
        WHERE   currency = ?
        ORDER   BY date DESC";

    my $data;
    $data->{AUD} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'AUD');
    $data->{EUR} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'EUR');
    $data->{GBP} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'GBP');
    $data->{USD} = database('sqlite')->selectall_arrayref( $qry, { Slice => {} } ,'USD');
    
    return $data;
}

sub exchange_rates_update {

    my $rates = shift;

    # create table exchange_rates (exchange_rates_id integer primary key, currency text NOT NULL, date text NOT NULL, exchange_rate text NOT NULL);

    my $qry = qq(INSERT INTO exchange_rates (currency,date,exchange_rate) VALUES (?,(strftime('%s','now')),?);); 

    my $sth = database('sqlite')->prepare($qry);
    $sth->execute( 'AUD',$rates->{AUD} );
    $sth->execute( 'EUR',$rates->{EUR} );
    $sth->execute( 'GBP',$rates->{GBP} );
    $sth->execute( 'USD',$rates->{USD} );
    $sth->finish;

    return exchange_rates();
}

1;
