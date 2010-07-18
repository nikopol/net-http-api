package Net::HTTP::API::Parser::JSON;

# ABSTRACT: Parse JSON

use JSON;
use Moose;
extends 'Net::HTTP::API::Parser';

has _json_parser => (
    is      => 'rw',
    isa     => 'JSON',
    lazy    => 1,
    default => sub { JSON->new->allow_nonref },
);

sub encode {
    my ($self, $content) = @_;
    $self->_json_parser->encode($content);
}

sub decode {
    my ($self, $content) = @_;
    $self->_json_parser->decode($content);
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION
