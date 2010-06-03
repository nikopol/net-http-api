package MooseX::Net::API::Parser::XML;

use XML::Simple;
use Moose;
extends 'MooseX::Net::API::Parser';

has _xml_parser(
    is      => 'rw',
    isa     => 'XML::Simple',
    lazy    => 1,
    default => sub { XML::SImple->new(ForceArray => 0) }
);

sub encode {
    my ($self, $content) = @_;
    return $self->_xml_parser->XMLin($content);
}

sub decode {
    my ($self, $content) = @_;
    return $self->_xml_parser->XMLout($content);
}

1;
__END__

=head1 NAME

MooseX::Net::API::Parser::XML

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright 2010 by Linkfluence

http://linkfluence.net

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
