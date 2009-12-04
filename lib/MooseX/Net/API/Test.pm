package MooseX::Net::API::Test;

use lib ('t/lib');
use Try::Tiny;

use Test::More;
use Moose;
use Moose::Exporter;
use MooseX::Net::API::Meta::Class;
use MooseX::Net::API::Meta::Method;

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

my $list_content_type = {
    'json' => 'application/json',
    'yaml' => 'text/x-yaml',
    'xml'  => 'text/xml',
};

my $tests_count = 0;

sub test_api_declare {
    my $caller  = shift;
    my $name    = shift;
    my %options = @_;

    unless ( Class::MOP::is_class_loaded($name) ) {
        Class::MOP::load_class($name);
    }

    $api_to_test = $name;

    if ( $options{catalyst} ) {
        my $app = $options{catalyst_app_name};

        Class::MOP::load_class("HTTP::Request");
        Class::MOP::load_class("Catalyst::Test");

        Catalyst::Test->import($app);

        my $res = __PACKAGE__->meta->remove_method('_request');
        MooseX::Net::API->meta->add_method(
            '_request' => sub {
                my ( $class, $format, $options, $uri, $args ) = @_;
                my $method = $options->{method};

                my $res;
                if (   $method =~ /^(?:GET|DELETE)$/
                    || $options->{params_in_url} )
                {
                    $uri->query_form(%$args);
                    my $req = HTTP::Request->new( $method => $uri );
                    $req->header(
                        'Content-Type' => $list_content_type->{$format} );
                    $res = request($req);
                }
                else {
                    my $req = HTTP::Request->new( $method => $uri );
                    $req->header(
                        'Content-Type' => $list_content_type->{$format} );
                    $req->header( 'Content' => Dump $args);
                    $res = request($req);
                }
                return $res;
            }
        );
    }
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
