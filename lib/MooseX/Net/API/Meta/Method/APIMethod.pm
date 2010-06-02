package MooseX::Net::API::Meta::Method::APIMethod;

use Moose::Role;
use MooseX::Net::API::Error;
use MooseX::Net::API::Meta::Method;
use MooseX::Types::Moose qw/Str ArrayRef/;

has local_api_methods => (
    traits     => ['Array'],
    is         => 'ro',
    isa        => ArrayRef [Str],
    required   => 1,
    default    => sub { [] },
    auto_deref => 1,
    handles    => {
        _get_api_method  => 'grep',
        _add_api_method  => 'push',
        _all_api_methods => 'elements',
    },
);

before add_net_api_method => sub {
    my ($meta, $name) = @_;
    if (my @method = $meta->_get_api_method(sub {/^$name$/})) {
        die MooseX::Net::API::Error->new(
            reason => "method '$name' is already declared in " . $meta->name);
    }
};

sub add_net_api_method {
    my ($meta, $name, %options) = @_;

    my $code = delete $options{code};
    $meta->add_method(
        $name,
        MooseX::Net::API::Meta::Method->wrap(
            name         => $name,
            package_name => $meta->name,
            body         => $code,
            %options
        ),
    );
    $meta->_add_api_method($name);
}

after add_net_api_method => sub {
    my ($meta, $name, %options) = @_;
    $meta->add_before_method_modifier(
        $name,
        sub {
            my $self = shift;
            die MooseX::Net::API::Error->new(
                reason => "'api_base_url' have not been defined")
              unless $self->api_base_url;
        }
    );
};

1;
