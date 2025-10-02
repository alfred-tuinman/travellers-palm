package TravellersPalm::Database::Currencies;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw();

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
    $currencycode = uc $currencycode;

    my @bind;  # values for placeholders
    my $sql = qq/
        SELECT currencycode, currency, symbol, c.currencies_id, wef 
        FROM 
        (   SELECT currencies_id, max(wef) AS wef
            FROM currencydetails
            GROUP BY currencies_id
        ) temp
        JOIN currencies c ON c.currencies_id = temp.currencies_id
        WHERE c.hdfccode IS NOT NULL
    /;

    if (length $currencycode) {
        $sql .= ' AND currencycode LIKE ?';
        push @bind, $currencycode;
    }

    $sql .= ' ORDER BY currencycode';

    return TravellersPalm::Database::Connector::fetch_all( $sql, [@bind]);
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

    my $sql = \q/
        SELECT  exchangerate 
        FROM    currencydetails d
                RIGHT JOIN currencies c ON c.currencies_id = d.currencies_id
        WHERE   currencycode = ?
        ORDER   BY wef DESC
                LIMIT 1;/;

    return TravellersPalm::Database::Connector::fetch_all( $sql, [$currencycode]);
}

sub exchange_rates {

    my $sql = "
        SELECT  currency, exchange_rate, strftime('%d/%m/%Y',datetime(date, 'unixepoch')) as date
        FROM    exchange_rates
        WHERE   strftime('%d/%m/%Y',datetime(date, 'unixepoch')) = strftime('%d/%m/%Y','now')
        ORDER BY currency DESC;";

    return TravellersPalm::Database::Connector::fetch_all( $sql);
}

sub exchange_rates_historical {

    my $sql = "
        SELECT  currency, strftime('%d/%m/%Y',datetime(date, 'unixepoch')) as date, exchange_rate 
        FROM    exchange_rates
        WHERE   currency = ?
        ORDER   BY date DESC";

    my $data;
    $data->{AUD} = database('sqlite')->selectall_arrayref( $sql, { Slice => {} } ,'AUD');
    $data->{EUR} = database('sqlite')->selectall_arrayref( $sql, { Slice => {} } ,'EUR');
    $data->{GBP} = database('sqlite')->selectall_arrayref( $sql, { Slice => {} } ,'GBP');
    $data->{USD} = database('sqlite')->selectall_arrayref( $sql, { Slice => {} } ,'USD');
    
    return $data;
}

sub exchange_rates_update {

    my $rates = shift;

    # create table exchange_rates (exchange_rates_id integer primary key, currency text NOT NULL, date text NOT NULL, exchange_rate text NOT NULL);

    my $sql = q/
      INSERT INTO exchange_rates (currency,date,exchange_rate) 
      VALUES (?,(strftime('%s','now')),?); /; 

    my $sth = database('sqlite')->prepare($sql);
       $sth->execute( 'AUD',$rates->{AUD} );
       $sth->execute( 'EUR',$rates->{EUR} );
       $sth->execute( 'GBP',$rates->{GBP} );
       $sth->execute( 'USD',$rates->{USD} );
       $sth->finish;

    return exchange_rates();
}

1;
