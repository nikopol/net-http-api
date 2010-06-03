package MooseX::Net::API::Parser;

# ABSTRACT: base class for all MooseX::Net::API::Parser

use Moose;

sub encode {die "must be implemented"}
sub decode {die "must be implemented"}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION

