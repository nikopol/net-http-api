package MooseX::Net::API::Role::UserAgent;

use Moose::Role;
use LWP::UserAgent;

has api_useragent => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $ua   = $self->meta->get_option('useragent');
        return $ua->() if $ua;
        $ua = LWP::UserAgent->new();
        $ua->agent(
            "MooseX::Net::API " . $MooseX::Net::API::VERSION . " (Perl)");
        $ua->env_proxy;
        return $ua;
    }
);

1;
__END__

=head1 NAME

MooseX::Net::API::Role::UseAgent

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 ATTRIBUTES

=over 4

=item B<api_useragent>

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
