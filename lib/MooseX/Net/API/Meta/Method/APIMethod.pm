package MooseX::Net::API::Meta::Method::APIMethod;

# ABSTRACT: declare API method

use Moose::Role;
use MooseX::Net::API::Error;
use MooseX::Net::API::Meta::Method;
use MooseX::Types::Moose qw/Str ArrayRef/;

has local_api_methods => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => ArrayRef [Str],
    required   => 1,
    default    => sub { [] },
    auto_deref => 1,
    handles    => {
        find_api_method_by_name => 'grep',
        add_api_method          => 'push',
        get_all_api_methods     => 'elements',
    },
);

before add_net_api_method => sub {
    my ($meta, $name) = @_;
    if (my @method = $meta->find_api_method_by_name(sub {/^$name$/})) {
        die MooseX::Net::API::Error->new(
            reason => "method '$name' is already declared in " . $meta->name);
    }
};

sub add_net_api_method {
    my ($meta, $name, %options) = @_;

    # XXX accept blessed method

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
    $meta->add_api_method($name);
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

sub remove_net_api_method {
    my ($meta, $name) = @_;
    my @methods = grep { !/$name/ } $meta->get_all_api_methods;
    $meta->local_api_methods(\@methods);
    $meta->remove_method($name);
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION
