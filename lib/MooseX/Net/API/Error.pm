package MooseX::Net::API::Error;

use Moose;
use JSON::XS;
use Moose::Util::TypeConstraints;
use overload '""' => \&error;

subtype error => as 'Str';
coerce error => from 'HashRef' => via { encode_json $_};

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

__END__
