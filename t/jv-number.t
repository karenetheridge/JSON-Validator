use lib '.';
use t::Helper;

my $schema = {
  type => 'object',
  properties =>
    {mynumber => {type => 'number', minimum => -0.5, maximum => 2.7}}
};

validate_ok {mynumber => 1},   $schema;
validate_ok {mynumber => '2'}, $schema,
  E('/mynumber', 'Expected number - got string.');

for my $x ([-0.5, 2.7], [true, true]) {
  $schema->{properties}{mynumber}{exclusiveMaximum} = $x->[1];
  $schema->{properties}{mynumber}{exclusiveMinimum} = $x->[0];
  validate_ok {mynumber => 2.7}, $schema, E('/mynumber', '2.7 >= maximum(2.7)');
  validate_ok {mynumber => -0.5}, $schema,
    E('/mynumber', '-0.5 <= minimum(-0.5)');
}
delete @{$schema->{properties}{mynumber}}{qw(exclusiveMaximum exclusiveMinimum)};

validate_ok 4, { exclusiveMaximum => 3 }, E('/', '4 >= maximum(3)');

my $numeric_constant = {type => 'number', const => 2.1};
validate_ok 2.1, $numeric_constant;
validate_ok 1, $numeric_constant, E('/', q{Does not match const: 2.1.});

# WARNING! coercions are on for the remainder of this test!
jv->coerce('numbers');
validate_ok '2.1', $numeric_constant;
validate_ok '1', $numeric_constant, E('/', q{Does not match const: 2.1.});

validate_ok {mynumber => '-0.5'}, $schema;
validate_ok {mynumber => -0.6}, $schema, E('/mynumber', '-0.6 < minimum(-0.5)');
validate_ok {mynumber => '2.7'}, $schema;
validate_ok {mynumber => '2.8'}, $schema, E('/mynumber', '2.8 > maximum(2.7)');
validate_ok {mynumber => '0.1e+1'}, $schema;
validate_ok {mynumber => '2xyz'},   $schema,
  E('/mynumber', 'Expected number - got string.');
validate_ok {mynumber => '.1'}, $schema,
  E('/mynumber', 'Expected number - got string.');
validate_ok {validNumber => 2.01},
  {
  type       => 'object',
  properties => {validNumber => {type => 'number', multipleOf => 0.01}}
  };

done_testing;
