package TestApp::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller::REST/;

sub foo : Local : ActionClass('REST') {
    my ( $self, $c ) = @_;
}

sub foo_GET {
    my ( $self, $c ) = @_;
    $self->status_ok( $c, entity => { status => 1 } );
}

1;
