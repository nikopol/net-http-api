package MooseX::Net::API::Meta::Method;

use Moose;
extends 'Moose::Meta::Method';

has description => ( is => 'ro', isa => 'Str' );
has path        => ( is => 'ro', isa => 'Str', required => 1 );
has method      => ( is => 'ro', isa => 'Str', required => 1 );
has params      => ( is => 'ro', isa => 'ArrayRef', required => 0 );
has required    => ( is => 'ro', isa => 'ArrayRef', required => 0 );
has expected    => ( is => 'ro', isa => 'ArrayRef', required => 0 );

sub new {
    my $class = shift;
    my %args  = @_;
    $class->SUPER::wrap(@_);
}

1;
