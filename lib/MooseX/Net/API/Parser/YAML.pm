package MooseX::Net::API::Parser::YAML;

# ABSTRACT: Parse YAML

use YAML::Syck;
use Moose;
extends 'MooseX::Net::API::Parser';

sub encode {
    my ($self, $content) = @_;
    return Dump($content);
}

sub decode {
    my ($self, $content) = @_;
    return Load($content);
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION
