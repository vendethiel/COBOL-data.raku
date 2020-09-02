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

my $CNT;
my class Decl {
  has $.lvl;
  has $.name;
  has Decl @.children;

  has $!KLASS;
  method klass() {
    return $!KLASS with $!KLASS;
    my $self = self;

    my $class = Metamodel::ClassHOW.new_type(name => $!name ~ "#" ~ $CNT++);
    my %child-types; # .klass is supposed to be cached, but for some reason it doesnt work
    $class.^add_method("LEVEL", method () { $self.lvl });
    $class.^add_method("receive", method (%data) {
      my %new;
      for $self.children {
        die "Attribute " ~ .name ~ " of " ~ $self.name ~ " is not present." unless %data{.name}:exists;
        %new{.name} = %child-types{.name}.receive(%data{.name}:delete);
      }
      die "Extraneous attributes: $(%data.keys) for " ~ $self.name if %data;
      $class.new(|%new);
    });
    for @!children {
      # TODO infer sigil n stuff
      $class.^add_attribute(Attribute.new(
        :name('$.' ~ .name),
        :type(%child-types{.name} = .klass),
        :has_accessor(1),
        :package($class),
        :required,
      ));
    }
    $class.^compose;
    $!KLASS = $class;
    return $!KLASS
  }
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
  @stack[0]
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
