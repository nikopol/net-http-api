package MooseX::Net::API::Meta::Method::APIDeclare;

use Moose::Role;
use MooseX::Net::API::Error;

has options => (
    is      => 'ro',
    traits  => ['Hash'],
    isa     => 'HashRef[Str|CodeRef]',
    default => sub { {} },
    lazy    => 1,
    handles => {
        set_option => 'set',
        get_option => 'get',
    },
);

sub add_net_api_declare {
    my ($meta, $name, %options) = @_;

    if ($options{useragent}) {
        die MooseX::Net::API::Error->new(
            reason => "'useragent' must be a CODE ref")
          unless ref $options{useragent} eq 'CODE';
        $meta->set_option(useragent => delete $options{useragent});
    }

    # XXX custom authentication_method (replace with before request !)

    # XXX for backward compatibility
    for my $attr (qw/base_url format username password/) {
        my $attr_name = "api_" . $attr;
        if (exists $options{$attr} && !exists $options{$attr_name}) {
            $options{$attr_name} = delete $options{$attr};
        }
    }

    for my $attr (qw/api_base_url api_format api_username api_password authentication/) {
        $meta->set_option($attr => $options{$attr}) if defined $options{$attr};
    }

    # XXX before_request after_request

    if (keys %options) {
        # XXX croak
    }
}

1;
