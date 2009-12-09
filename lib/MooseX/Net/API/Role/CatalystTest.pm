package MooseX::Net::API::Role::CatalystTest;

use lib ('t/lib');

use Moose::Role; with qw/
    MooseX::Net::API::Role::Serialize 
    MooseX::Net::API::Role::Deserialize/;

my $list_content_type = {
    'json' => 'application/json',
    'yaml' => 'text/x-yaml',
    'xml'  => 'text/xml',
};

after qw/test_api_declare/ => sub {
    my $caller  = shift;
    my $name    = shift;
    my %options = @_;

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
                    my $content = _do_serialization($class, $args, $format);
                    $req->content( $content );
                    $res = request($req);
                }
                return $res;
            }
        );
    }
};

1;
