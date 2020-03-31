use lib '.';
use t::Helper;

my $schema = {
  type       => 'object',
  properties => {mynumber => {type => 'integer', minimum => 1, maximum => 4}}
};

validate_ok {mynumber => 1},   $schema;
validate_ok {mynumber => 4},   $schema;
validate_ok {mynumber => 2},   $schema;
validate_ok {mynumber => 0},   $schema, E('/mynumber', '0 < minimum(1)');
validate_ok {mynumber => -1},  $schema, E('/mynumber', '-1 < minimum(1)');
validate_ok {mynumber => 5},   $schema, E('/mynumber', '5 > maximum(4)');
validate_ok {mynumber => '2'}, $schema,
  E('/mynumber', 'Expected integer - got string.');

$schema->{properties}{mynumber}{multipleOf} = 2;
validate_ok {mynumber => 3}, $schema, E('/mynumber', 'Not multiple of 2.');

my $int_constant = {type => 'integer', const => 2};
validate_ok 2, $int_constant;
validate_ok 1, $int_constant, E('/', q{Does not match const: 2.});

# WARNING! coercions are on for the remainder of this test!
jv->coerce('num');
validate_ok {mynumber => '2'},    $schema;
validate_ok {mynumber => '2xyz'}, $schema,
  E('/mynumber', 'Expected integer - got string.');

$schema->{properties}{mynumber}{minimum} = -3;
validate_ok {mynumber => '-2'}, $schema;

validate_ok '2', $int_constant;
validate_ok '1', $int_constant, E('/', q{Does not match const: 2.});

done_testing;
