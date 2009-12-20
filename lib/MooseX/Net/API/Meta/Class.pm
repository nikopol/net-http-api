package MooseX::Net::API::Meta::Class;

use Moose::Role;
use Moose::Meta::Class;
use MooseX::Types::Moose qw(Str ArrayRef ClassName Object);

has local_api_methods => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    required   => 1,
    default    => sub { [] },
    auto_deref => 1,
    handles    => { '_add_api_method' => 'push' },
);

sub _build_meta_class {
    my $self = shift;
    return Moose::Meta::Class->create_anon_class(
        superclasses => [ $self->method_metaclass ],
        cache        => 1,
    );
}

1;
