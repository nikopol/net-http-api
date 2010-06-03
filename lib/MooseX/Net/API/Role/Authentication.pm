package MooseX::Net::API::Role::Authentication;

use Moose::Role;

has api_username => (
    is      => 'rw',
    isa     => 'Str',
    predicate => 'has_api_username',
);

has api_password => (
    is      => 'rw',
    isa     => 'Str',
    predicate => 'has_api_password',
);

# ugly :(
after BUILDALL => sub {
    my $self = shift;

    for (qw/api_username api_password/) {
        my $predicate = 'has_' . $_;
        my $value     = $self->meta->get_option($_);
        $self->$_($value) if $value && !$self->$predicate;
    }

    if (my $has_auth = $self->meta->get_option('authentication')) {
        my $auth_method = $self->meta->get_option('authentication_method');
        if ($auth_method) {
            $self->api_useragent->add_handler(
                request_prepare => sub { $self->$auth_method(@_) });
        }
        else {
            if ($self->has_api_username && $self->has_api_password) {
                $self->api_useragent->add_handler(
                    request_prepare => sub {
                        my $req = shift;
                        $req->headers->authorization_basic($self->api_username,
                            $self->api_password);
                    }
                );
            }
        }
    }
};

1;
__END__

=head1 NAME

MooseX::Net::API::Role::Authentication

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item B<api_password>

=item B<api_username>

=back

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2009, 2010 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
