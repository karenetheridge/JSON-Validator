use Mojo::Base -strict;
use JSON::Validator;
use Test::Mojo;
use Test::More;
use Mojo::JSON 'encode_json';
use Scalar::Util 'refaddr';

my ($base_url, $jv, $t, @e);

use Mojolicious::Lite;
get '/person'           => 'person';
get '/invalid-relative' => 'invalid-relative';
get '/relative-to-the-root' => 'relative-to-the-root';

$t  = Test::Mojo->new;
$jv = JSON::Validator->new(ua => $t->ua);
$t->get_ok('/relative-to-the-root.json')->status_is(200);

$base_url = $t->tx->req->url->to_abs->path('/');
like $base_url, qr{^http}, 'got base_url to web server';

eval {
  $jv->load_and_validate_schema("${base_url}person.json",
    {schema => 'http://json-schema.org/draft-07/schema'});
};
ok !$@, "${base_url}schema.json" or diag $@;

is $jv->version, 7,     'detected version from draft-07';
is $jv->_id_key, '$id', 'detected id_key from draft-07';

eval { $jv->load_and_validate_schema("${base_url}invalid-relative.json") };
like $@, qr{cannot have a relative}, 'Root id cannot be relative' or diag $@;

SKIP: {
  skip 'not yet detecting $schema from document!', 0;
  delete $jv->{version};
}

eval { $jv->load_and_validate_schema("${base_url}relative-to-the-root.json") };
ok !$@, "${base_url}relative-to-the-root.json" or diag $@;
is $jv->{version}, 7, 'detected version from draft-07';

my $schema = $jv->schema;
is $schema->get('/$id'), 'http://example.com/relative-to-the-root.json',
  'get /$id';
is $schema->get('/definitions/B/$id'), 'b.json', 'id /definitions/B/$id';
is $schema->get('/definitions/B/definitions/X/$id'), '#bx',
  'id /definitions/B/definitions/X/$id';
is $schema->get('/definitions/B/definitions/Y/$id'), 't/inner.json',
  'id /definitions/B/definitions/Y/$id';
is $schema->get('/definitions/C/definitions/X/$id'),
  'urn:uuid:ee564b8a-7a87-4125-8c96-e9f123d6766f',
  'id /definitions/C/definitions/X/$id';
is $schema->get('/definitions/C/definitions/Y/$id'), '#cy',
  'id /definitions/C/definitions/Y/$id';

my $ref = $schema->get('/definitions/R1');
ok $ref->{$_}, "got $_" for qw($ref %%fqn %%schema);
is encode_json($ref), '{"$ref":"b.json#bx"}', 'ref encode_json';
$ref = tied %$ref;
is $ref->ref, 'b.json#bx',                    'ref ref';
is $ref->fqn, 'http://example.com/b.json#bx', 'ref fqn';
is encode_json($ref->schema), '{"$id":"#bx"}', 'ref schema';

is
  refaddr($jv->{schemas}{'http://example.com/b.json#bx'}),
  refaddr($jv->{schemas}{'http://example.com/relative-to-the-root.json'}{definitions}{B}{definitions}{X}),
  'registered #bx properly';


done_testing;

__DATA__
@@ invalid-relative.json.ep
{"$id": "whatever"}
@@ person.json.ep
{
  "$id": "http://example.com/person.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "definitions": {
    "Person": {
      "type": "object",
      "properties": {
        "firstName": { "type": "string" }
      }
    }
  }
}
@@ relative-to-the-root.json.ep
{
  "$id": "http://example.com/relative-to-the-root.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "definitions": {
    "A": { "$id": "#a" },
    "B": {
      "$id": "b.json",
      "definitions": {
        "X": { "$id": "#bx" },
        "Y": { "$id": "t/inner.json" }
      }
    },
    "C": {
      "$id": "c.json",
      "definitions": {
        "X": { "$id": "urn:uuid:ee564b8a-7a87-4125-8c96-e9f123d6766f" },
        "Y": { "$id": "#cy" }
      }
    },
    "R1": { "$ref": "b.json#bx" },
    "R2": { "$ref": "#a" },
    "R3": { "$ref": "urn:uuid:ee564b8a-7a87-4125-8c96-e9f123d6766f" }
  }
}
