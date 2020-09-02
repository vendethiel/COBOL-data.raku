unit module COBOL::Data;

my grammar P {

  token TOP { <decl>+ }

  rule decl {
    <.ws>
    $<lvl>=[\d+] { $<lvl> > 0 or die "Invalid level" }
    <name> '.'
    <.ws>
  }

  token name { <[A..Z a..z]>+ }

}

my class Decl {
  has $.lvl;
  has $.name;
  has Decl @.children;
}

my class A {
  method TOP($/) {
    make $<decl>>>.made;
  }

  method decl($/) {
    make Decl.new(lvl => +$<lvl>, name => $<name>.made)
  }

  method name($/) {
    make ~$/
  }
}

sub nest(@decls) {
  my @stack = Decl.new(lvl => 0, name => "ROOT");
  my sub cur() { @stack[*-1] }
  for @decls {
    @stack.pop while cur.lvl >= .lvl;
    cur.children.push: $_;
    @stack.push: $_;
  }
  @stack[0].children
}

sub parse(Str $data) is export {
  return nest(P.parse($data, :actions(A.new)).made);
}

multi sub stringify(Decl @decl) is export {
  join "\n---\n", @decl.map(&stringify);
}

multi sub stringify(Decl $decl) is export {
  my sub pp($decl, $lvl) {
    take " " xx $lvl ~ "- " ~ $decl.name;
    pp($_, $lvl + 1) for $decl.children;
  }
  join "\n", gather pp($decl, 0);
}
