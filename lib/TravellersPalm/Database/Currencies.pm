package TravellersPalm::Database::Currencies;

use strict;
use warnings;

use Exporter 'import';
use TravellersPalm::Database::Connector qw(fetch_all fetch_row execute);
use TravellersPalm::Database::Helpers qw(_fetch_row _fetch_all _execute);
use Data::Dumper;

our @EXPORT_OK = qw(
    currencies
    currency
    exchangerate
    exchange_rates
    exchange_rates_historical
    exchange_rates_update
);

# -----------------------------
# List currencies
# -----------------------------
sub currencies {
    my ($currencycode) = @_;
    $currencycode = '' unless defined $currencycode;
    $currencycode = uc $currencycode;

    my @bind;
    my $sql = q{
        SELECT currencycode, currency, symbol, c.currencies_id, wef
        FROM (
            SELECT currencies_id, MAX(wef) AS wef
            FROM currencydetails
            GROUP BY currencies_id
        ) temp
        JOIN currencies c ON c.currencies_id = temp.currencies_id
        WHERE c.hdfccode IS NOT NULL
    };

    if (length $currencycode) {
        $sql .= ' AND currencycode LIKE ?';
        push @bind, $currencycode;
    }

    $sql .= ' ORDER BY currencycode';
    return _fetch_all($sql, \@bind);
}

# -----------------------------
# Get or default currency
# -----------------------------
sub currency {
    my ($newcurrency) = @_;
    my $currency = 'USD';

    if (defined $newcurrency) {
        my $exist = currencies($newcurrency);
        $currency = $newcurrency if scalar @$exist;
    }

    return $currency;
}

# -----------------------------
# Latest exchange rate for a currency
# -----------------------------
sub exchangerate {
    my ($currencycode) = @_;
    return 0 unless $currencycode;

    my $sql = q{
        SELECT exchangerate
        FROM currencydetails d
        RIGHT JOIN currencies c ON c.currencies_id = d.currencies_id
        WHERE currencycode = ?
        ORDER BY wef DESC
        LIMIT 1
    };

    my $row = _fetch_row($sql, [$currencycode]);
    return $row ? $row->{exchangerate} : 0;
}

# -----------------------------
# Today's exchange rates
# -----------------------------
sub exchange_rates {
    my $sql = q{
        SELECT currency, exchange_rate, strftime('%d/%m/%Y', datetime(date, 'unixepoch')) AS date
        FROM exchange_rates
        WHERE strftime('%d/%m/%Y', datetime(date, 'unixepoch')) = strftime('%d/%m/%Y','now')
        ORDER BY currency DESC
    };

    return _fetch_all($sql, []);
}

# -----------------------------
# Historical exchange rates for key currencies
# -----------------------------
sub exchange_rates_historical {
    my $sql = q{
        SELECT currency, strftime('%d/%m/%Y', datetime(date, 'unixepoch')) AS date, exchange_rate
        FROM exchange_rates
        WHERE currency = ?
        ORDER BY date DESC
    };

    my @currencies = qw(AUD EUR GBP USD);
    my %data;

    foreach my $cur (@currencies) {
        $data{$cur} = _fetch_all($sql, [$cur]);
    }

    return \%data;
}

# -----------------------------
# Insert new exchange rates
# -----------------------------
sub exchange_rates_update {
    my ($rates) = @_;

    my $sql = q{
        INSERT INTO exchange_rates (currency, date, exchange_rate)
        VALUES (?, strftime('%s','now'), ?)
    };

    foreach my $cur (qw(AUD EUR GBP USD)) {
        _execute($sql, [$cur, $rates->{$cur}]);
    }

    return exchange_rates();
}

1;
