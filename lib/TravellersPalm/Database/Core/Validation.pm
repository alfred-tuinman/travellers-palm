package TravellersPalm::Database::Core::Validation;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
    validate_string 
    validate_integer
    validate_filter
    validate_order
    validate_array
);

# Validate string input
sub validate_string {
    my ($value, $required, $max_length) = @_;
    $max_length //= 255;
    
    # Return undef if value not required and empty
    return undef if !$required && (!defined $value || $value eq '');
    
    # Die if value required but empty
    die "Required string parameter missing\n" 
        if $required && (!defined $value || $value eq '');
    
    # Trim and validate length
    $value =~ s/^\s+|\s+$//g if defined $value;
    die "String parameter too long (max $max_length chars)\n" 
        if defined $value && length($value) > $max_length;
        
    return $value;
}

# Validate integer input
sub validate_integer {
    my ($value, $required, $min, $max) = @_;
    $min //= 0;
    $max //= 2**31 - 1;
    
    # Return undef if value not required and empty
    return undef if !$required && (!defined $value || $value eq '');
    
    # Die if value required but empty
    die "Required integer parameter missing\n"
        if $required && (!defined $value || $value eq '');
    
    # Validate integer format and range
    die "Invalid integer parameter\n" 
        unless defined $value && $value =~ /^-?\d+$/;
    die "Integer parameter out of range ($min-$max)\n"
        if $value < $min || $value > $max;
        
    return $value + 0; # Force numeric context
}

# Validate filter values
# Returns normalized uppercase value if valid, undef otherwise
sub validate_filter {
    my ($value) = @_;
    return undef unless defined $value;
    
    my %valid_filters = (
        'LIMIT' => 1,
        'EXTENDED' => 1
    );
    
    my $upper = uc($value);
    return $upper if exists $valid_filters{$upper};
    return undef;
}

# Validate order column 
sub validate_order {
    my ($value, $default, $allowed) = @_;
    $default //= 'id';
    $allowed //= {};
    
    return $default unless defined $value;
    return exists $allowed->{$value} ? $value : $default;
}

# Validate array of values using a provided element validator callback
# Usage: validate_array(\@ids, "ids", sub { my ($val, $idx) = @_; validate_integer($val, "id[$idx]", 1); })
sub validate_array {
    my ($aref, $name, $elem_validator) = @_;
    die "$name must be an array reference\n" unless ref $aref eq 'ARRAY';
    die "Element validator callback required for $name\n" unless ref $elem_validator eq 'CODE';
    for my $i (0..$#$aref) {
        $elem_validator->($aref->[$i], $i);
    }
    return $aref;
}

1;
