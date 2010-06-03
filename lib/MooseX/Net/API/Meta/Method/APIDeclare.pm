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
has accepted_options => (
    is      => 'ro',
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    default => sub {
        [   qw/api_base_url
              api_format
              api_username
              api_password
              authentication
              authentication_method/
        ];
    },
    lazy       => 1,
    auto_deref => 1,
);

sub add_net_api_declare {
    my ($meta, $name, %options) = @_;

    if ($options{useragent}) {
        die MooseX::Net::API::Error->new(
            reason => "'useragent' must be a CODE ref")
          unless ref $options{useragent} eq 'CODE';
        $meta->set_option(useragent => delete $options{useragent});
    }

    # XXX for backward compatibility
    for my $attr (qw/base_url format username password/) {
        my $attr_name = "api_" . $attr;
        if (exists $options{$attr} && !exists $options{$attr_name}) {
            $options{$attr_name} = delete $options{$attr};
        }
    }

    for my $attr ($meta->accepted_options) {
        $meta->set_option($attr => $options{$attr}) if defined $options{$attr};
    }

    # XXX before_request after_request
}

1;
__END__

=head1 NAME

MooseX::Net::API::Meta::Class::Method::APIDeclare

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2009, 2010 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
