package MooseX::Net::API::Error;

# ABSTRACT: Throw error

use Moose;
use JSON;
use Moose::Util::TypeConstraints;
use overload '""' => \&error;

subtype error => as 'Str';
coerce error => from 'HashRef' => via { JSON::encode_json $_};

has http_error => (
    is      => 'ro',
    isa     => 'HTTP::Response',
    handles => { http_message => 'message', http_code => 'code' }
);
has reason => (
    is        => 'ro',
    isa       => 'error',
    predicate => 'has_reason',
    coerce    => 1
);

sub error {
    my $self = shift;
    return
           ( $self->has_reason && $self->reason )
        || ( $self->http_message . ": " . $self->http_code )
        || 'unknown';
}

1;

=head1 SYNOPSIS

    MooseX::Net::API::Error->new(reason => "'useragent' is required");

or

    MooseX::Net::API::Error->new()

=head1 DESCRIPTION
