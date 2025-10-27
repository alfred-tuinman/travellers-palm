package TravellersPalm::Database::Currencies;

use strict;
use warnings;

use Data::Dumper;
use Exporter 'import';
use TravellersPalm::Database::Core::Connector qw(fetch_all fetch_row insert_row);
use TravellersPalm::Database::Core::Validation qw(
    validate_string
    validate_integer
);

# -----------------------------
# List currencies
# -----------------------------
sub currencies {
    my ($currencycode, $c) = @_;
    
    # Validate currency code
    eval {
        $currencycode = validate_string($currencycode, 0, 3);  # Optional, max 3 chars
        $currencycode = uc $currencycode if defined $currencycode;
    };
    if ($@) {
        warn "Input validation failed in currencies(): $@";
        return [];
    }

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
    return fetch_all($sql, \@bind, 'NAME', 'jadoo', $c);
}

# -----------------------------
# Get or default currency
# -----------------------------
sub currency {
    my ($newcurrency, $c) = @_;
    
    # Validate new currency code
    eval {
        if (defined $newcurrency) {
            $newcurrency = validate_string($newcurrency, 0, 3);  # Optional, max 3 chars
            $newcurrency = uc $newcurrency if defined $newcurrency;
        }
    };
    if ($@) {
        warn "Input validation failed in currency(): $@";
        return 'USD';  # Safe default
    }
    
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
    my ($currencycode, $c) = @_;
    
    # Validate currency code
    eval {
        $currencycode = validate_string($currencycode, 1, 3);  # Required, max 3 chars
        $currencycode = uc $currencycode;
        
        # Additional validation for currency code format
        die "Invalid currency code format (must be 3 letters)\n"
            unless $currencycode =~ /^[A-Z]{3}$/;
    };
    if ($@) {
        warn "Input validation failed in exchangerate(): $@";
        return 0;  # Safe default for invalid input
    }

    my $sql = q{
        SELECT exchangerate
        FROM currencydetails d
        RIGHT JOIN currencies c ON c.currencies_id = d.currencies_id
        WHERE currencycode = ?
        ORDER BY wef DESC
        LIMIT 1
    };

    my $row = fetch_row($sql, [$currencycode], 'NAME', 'jadoo', $c);
    return $row ? $row->{exchangerate} : 0;
}

# -----------------------------
# Today's exchange rates
# -----------------------------
sub exchange_rates {
    my ($c) = @_;
    my $sql = q{
        SELECT currency, exchange_rate, strftime('%d/%m/%Y', datetime(date, 'unixepoch')) AS date
        FROM exchange_rates
        WHERE strftime('%d/%m/%Y', datetime(date, 'unixepoch')) = strftime('%d/%m/%Y','now')
        ORDER BY currency DESC
    };

    return fetch_all($sql, [], 'NAME', 'jadoo', $c);
}

# -----------------------------
# Historical exchange rates for key currencies
# -----------------------------
sub exchange_rates_historical {
    my ($c) = @_;
    my $sql = q{
        SELECT currency, strftime('%d/%m/%Y', datetime(date, 'unixepoch')) AS date, exchange_rate
        FROM exchange_rates
        WHERE currency = ?
        ORDER BY date DESC
    };

    my @currencies = qw(AUD EUR GBP USD);
    my %data;

    foreach my $cur (@currencies) {
        $data{$cur} = fetch_all($sql, [$cur], 'NAME', 'jadoo', $c);
    }

    return \%data;
}

# -----------------------------
# Insert new exchange rates
# -----------------------------
sub exchange_rates_update {
    my ($rates, $c) = @_;

    foreach my $cur (qw(AUD EUR GBP USD)) {
    TravellersPalm::Database::Core::Connector::insert_row(
        "INSERT INTO exchange_rates (currency, date, exchange_rate) VALUES (?, strftime('%s','now'), ?)", 
        [$cur, $rates->{$cur}], 'NAME', 'jadoo', $c
      );
    }

    return exchange_rates();
}

1;
