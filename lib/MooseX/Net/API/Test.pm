package MooseX::Net::API::Test;

use lib ('t/lib');
use Try::Tiny;

use Test::More;
use Moose;
use Moose::Exporter;
use MooseX::Net::API::Meta::Class;
use MooseX::Net::API::Meta::Method;

with qw/MooseX::Net::API::Role::CatalystTest/;

Moose::Exporter->setup_import_methods(
    with_caller => [qw/test_api_method test_api_declare run/] );

my $api_to_test;

sub init_meta {
    my ( $me, %options ) = @_;

    my $for = $options{for_class};
    Moose::Util::MetaRole::apply_metaclass_roles(
        for_class       => $for,
        metaclass_roles => ['MooseX::Net::API::Meta::Class'],
    );
}

sub test_api_declare {
    my $caller  = shift;
    my $name    = shift;
    my %options = @_;

    unless ( Class::MOP::is_class_loaded($name) ) {
        Class::MOP::load_class($name);
    }

    $api_to_test = $name;
}

sub test_api_method {
    my $caller  = shift;
    my $name    = shift;
    my %options = @_;

    my $meta   = $api_to_test->meta;
    my $method = $meta->find_method_by_name($name);

    if ( !$method ) {
        die "method $name does not exists\n";
    }

    my $class = Moose::Meta::Class->initialize($caller);
    foreach my $test_name ( keys %{ $options{tests} } ) {
        foreach my $test ( @{ $options{tests}{$test_name} } ) {
            __PACKAGE__->meta->add_method(
                $test_name => sub {
                    my $res    = $method->execute( $api_to_test->new );
                    if (ref $test eq 'HASH') {
                        my $action = $test->{test};
                        my $result = $test->{expected};
                        # XXX sucky sucky sucky
                        if ( $action eq 'is_deeply' ) {
                            is_deeply( $res, $result );
                        }
                    }else{
                        if ($test eq 'ok') {
                            ok $res;
                        }
                    }
                }
            );
            $class->_add_api_test_method($test_name);
        }
    }
}

sub run {
    my $caller = shift;

    my $class = Moose::Meta::Class->initialize($caller);
    my @test_methods = $class->local_api_test_methods();
    foreach my $m (@test_methods) {
        my $method = __PACKAGE__->meta->find_method_by_name($m);
        $method->execute();
    }
}

1;
