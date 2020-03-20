use lib '.';
use t::Helper;

my $schema1 = {
  '$schema' => 'http://json-schema.org/draft-07/schema#',
  '$id' => 'http://127.0.0.1:50754/json_schema/refs/self with spaces/1',
  type => 'object',
  properties => {
    a => { type => 'string', minLength => 4 },
    b => { allOf => [
      { minLength => 3 },
      { '$ref' => '#/properties/a' },
    ] },
    'space age' => { type => 'number' },
    # to_abs = http://127.0.0.1:50754/json_schema/refs/self with spaces/1#new_base
    new_base => {
      '$id' => '#new_base',
      type => 'null',
    },
  },
};

my $schema2 = {
  '$schema' => 'http://json-schema.org/draft-07/schema#',
  '$id' => 'http://127.0.0.1:50754/json_schema/refs/other/1',
  type => 'object',
  properties => {
    a => {
      allOf => [
        { minLength => 3 },
        { '$ref' => '/json_schema/refs/self with spaces/1#/properties/a' },
        { '$ref' => '/json_schema/refs/self with spaces/1#/properties/space age' },
        { '$ref' => 'new_base#' },  # this resolves to our document at /properties/new_base
        { '$ref' => 'http://127.0.0.1:50754/json_schema/refs/self with spaces/1#new_base' },
        # we should also reference a plain-name fragment in our own doc.
        # and maybe we haven't gotten there yet! :o
        { '$ref' => '#new_local_base' },  # this resolves to our document at /properties/zz...
      ] },
    # to_abs = http://127.0.0.1:50754/json_schema/refs/other/new_base
    new_base => {
      '$id' => 'new_base',
      type => 'boolean',
    },
    zz_new_local_base => {
      '$id' => '#new_local_base',
      type => 'array',
    },
  },
};

jv()->version(7);

validate_ok { a => 'hi' }, $schema1,
  E('/a', 'String is too short: 2/4.');

is_deeply
  [ sort keys %{ jv()->{schemas} } ],
  [
    'http://127.0.0.1:50754/json_schema/refs/self with spaces/1',
    'http://127.0.0.1:50754/json_schema/refs/self with spaces/1#new_base',
  ],
  'all schemas have been registered with the correct name';

validate_ok { a => 'hi' }, $schema2,
  E('/a', '/allOf/0 String is too short: 2/3.'),
  E('/a', '/allOf/1 String is too short: 2/4.'),
  E('/a', '/allOf/2 Expected number - got string.'),
  E('/a', '/allOf/3 Expected boolean - got string.'),
  E('/a', '/allOf/4 Not null.'),
  E('/a', '/allOf/5 Expected array - got string.');  # XXX not sure if this will always work!


is_deeply
  [ sort keys %{ jv()->{schemas} } ],
  [
    'http://127.0.0.1:50754/json_schema/refs/other/1',
    'http://127.0.0.1:50754/json_schema/refs/other/1#new_local_base',
    'http://127.0.0.1:50754/json_schema/refs/other/new_base',
    'http://127.0.0.1:50754/json_schema/refs/self with spaces/1',
    'http://127.0.0.1:50754/json_schema/refs/self with spaces/1#new_base',
  ],
  'all schemas have been registered with the correct name';


my $schema3 = {
  '$schema' => 'http://json-schema.org/draft-07/schema#',
  type => 'object',
  properties => {
    a => { '$ref' => 'data://main/hello.json#my_anchor' },
    b => { '$ref' => 'data://main/hello.json#/properties/my_property' },
  },
};
jv()->version(7);

jv()->{schemas} = undef;
validate_ok { a => 'hi' }, $schema3,
  E('/a', 'Expected boolean - got string.');

jv()->{schemas} = undef;
validate_ok { b => 'hi' }, $schema3,
  E('/b', 'Expected boolean - got string.');

jv()->{schemas} = undef;
validate_ok 123, 'data://main/hello.json#my_anchor',
  E('/', 'Expected boolean - got number.');

jv()->{schemas} = undef;
validate_ok 123, 'data://main/hello.json#/properties/my_property',
  E('/', 'Expected boolean - got number.');

done_testing;

__DATA__
@@ hello.json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "my_property": {
      "$id": "#my_anchor",
      "type": "boolean"
    }
  }
}
