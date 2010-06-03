package MooseX::Net::API::Role::Format;

use Moose::Role;
use Moose::Util::TypeConstraints;

sub content_type {
    {   json => {value => 'application/json', module => 'JSON',},
        yaml => {value => 'text/x-yaml',      module => 'YAML'},
        xml  => {value => 'text/xml',         module => 'XML::Simple'},
    };
}

subtype Format => as 'Str' => where {
    my $format = shift;
    grep {/^$format$/} keys %{content_type()};
};

enum 'FormatMode' => qw(content-type append);

has api_format => (
    is      => 'rw',
    isa     => 'Format',
    lazy    => 1,
    default => sub {
        my $self = shift;
        $self->meta->get_option('api_format');
    }
);

has api_format_mode => (
    is      => 'rw',
    isa     => 'FormatMode',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $mode = $self->meta->get_option('api_format_mode');
        $mode || 'append';
    }
);

1;
__END__

=head1 NAME

MooseX::Net::API::Role::Format

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 METHODS

=over 4

=item B<content_type>

=back

=head2 ATTRIBUTES

=over 4

=item B<api_format>

=item B<api_format_mode>

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
