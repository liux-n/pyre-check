(* Copyright (c) 2016-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree. *)

open OUnit2
open IntegrationTest

let test_check_undefined_type context =
  let assert_type_errors = assert_type_errors ~context in
  let assert_default_type_errors = assert_default_type_errors ~context in
  let assert_strict_type_errors = assert_strict_type_errors ~context in
  assert_default_type_errors
    {|
      def foo(x: Derp) -> Herp:
        pass
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];

  (* Don't crash when returning a bad type. *)
  assert_default_type_errors
    {|
      def foo(a: gurbage) -> None:
        return a
    |}
    ["Unbound name [10]: Name `gurbage` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      def foo(a: gurbage) -> int:
        a = 1
        return a
    |}
    ["Unbound name [10]: Name `gurbage` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      def foo(x: Derp, y: Herp) -> None:
        pass
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];
  assert_default_type_errors
    {|
      def foo(x: int) -> Herp:
        return x
    |}
    ["Unbound name [10]: Name `Herp` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      import typing
      def foo(x: typing.Union[Derp, Herp]) -> typing.List[Herp]:
        pass
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];
  assert_default_type_errors
    {|
      def foo(x: Derp[int]) -> None:
        pass
    |}
    ["Unbound name [10]: Name `Derp` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      def foo(x: Derp[int, str]) -> None:
        pass
    |}
    ["Unbound name [10]: Name `Derp` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      import typing
      def foo(x: typing.Optional[Derp[int]]) -> typing.List[Herp]:
        pass
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];
  assert_default_type_errors
    {|
      def foo(x: Optional) -> None:
        pass
    |}
    ["Unbound name [10]: Name `Optional` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      def foo(x: Optional[Any]) -> None:
        pass
    |}
    [
      "Unbound name [10]: Name `Optional` is used but not defined in the current scope.";
      "Unbound name [10]: Name `Any` is used but not defined in the current scope.";
    ];
  assert_default_type_errors
    {|
      def foo(x: Dict) -> None:
        pass
    |}
    ["Unbound name [10]: Name `Dict` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      def foo() -> None:
        x: undefined = 1
        return
    |}
    ["Unbound name [10]: Name `undefined` is used but not defined in the current scope."];
  assert_default_type_errors
    {|
      def foo(x: Derp) -> None:
        y: undefined = 1
        return
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Unbound name [10]: Name `undefined` is used but not defined in the current scope.";
    ];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar('T')
      def foo(x: T) -> typing.Union[str, T]:
        return x
    |}
    [];

  (* Ensure other errors are not missed when undefined type is thrown. *)
  assert_strict_type_errors
    {|
      class Bar:
          async def undefined(self, x: Derp) -> Derp:
              return x
      class Foo(Bar):
          def error(self) -> int:
              return None
          async def undefined(self, x: Herp) -> Herp:
              return x
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Incompatible return type [7]: Expected `int` but got `None`.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];
  assert_strict_type_errors
    {|
      import typing
      def foo() -> typing.Optional["Herp"]:
        return None
    |}
    ["Unbound name [10]: Name `Herp` is used but not defined in the current scope."];
  assert_strict_type_errors
    {|
      import typing
      class Foo:
        def __getitem__(self, other) -> typing.Any: ...

      def foo() -> Foo["Herp"]:
        return 1
    |}
    [
      "Missing return annotation [3]: Return type must be specified as type other than `Any`.";
      "Missing parameter annotation [2]: Parameter `other` has no type specified.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];

  (* Attributes *)
  assert_type_errors
    {|
      class Foo:
        x: int = 1
        y: Derp = 1

        def __init__(self) -> None:
          self.z: Herp = 1
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Unbound name [10]: Name `Herp` is used but not defined in the current scope.";
    ];

  (* Class bases *)
  assert_type_errors
    {|
      class Foo(Bar): ...
    |}
    ["Unbound name [10]: Name `Bar` is used but not defined in the current scope."];
  assert_type_errors
    {|
      import typing
      _T = typing.TypeVar('_T')
      class Foo(Generic[_T]): ...
    |}
    [
      "Unbound name [10]: Name `Generic` is used but not defined in the current scope.";
      "Invalid type variable [34]: The current class isn't generic with respect to the type \
       variable `Variable[_T]`.";
    ];
  assert_type_errors
    {|
      class AA: ...
      class CC: ...
      class Foo(AA, BB, CC, DD): ...
    |}
    [
      "Unbound name [10]: Name `BB` is used but not defined in the current scope.";
      "Unbound name [10]: Name `DD` is used but not defined in the current scope.";
    ];
  assert_type_errors
    {|
      class AA: ...
      class CC(BB): ...
      class Foo(AA, BB, CC, DD): ...
    |}
    [
      "Unbound name [10]: Name `BB` is used but not defined in the current scope.";
      "Unbound name [10]: Name `DD` is used but not defined in the current scope.";
    ];

  (* Globals *)
  assert_type_errors
    {|
      import typing
      x: Derp = 1
      y: typing.List[Derp] = 1
      z: Derp
    |}
    ["Unbound name [10]: Name `Derp` is used but not defined in the current scope."];

  (* Assigns *)
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: Derp = 1
        y: typing.List[Derp] = 1
        z: Derp
    |}
    ["Unbound name [10]: Name `Derp` is used but not defined in the current scope."];

  (* cast, isinstance *)
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: int = 1
        typing.cast(Derp, x)
    |}
    ["Unbound name [10]: Name `Derp` is used but not defined in the current scope."];
  assert_type_errors
    {|
      import typing
      Derp = typing.Any
      Herp = typing.List[typing.Any]
      def foo() -> None:
        x: int = 1
        typing.cast(Derp, x)
        typing.cast(Herp, x)
    |}
    [
      "Prohibited any [33]: `Derp` cannot alias to `Any`.";
      "Prohibited any [33]: `Herp` cannot alias to a type containing `Any`.";
    ];
  assert_strict_type_errors
    {|
      def foo() -> None:
        x: int = 1
        if isinstance(x, Derp):
          return x
        return

    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Incompatible return type [7]: Expected `None` but got `int`.";
    ]


let test_check_invalid_type context =
  let assert_type_errors = assert_type_errors ~context in
  let assert_strict_type_errors = assert_strict_type_errors ~context in
  assert_type_errors {|
      MyType = int
      x: MyType = 1
    |} [];
  assert_type_errors
    {|
      import typing
      MyType: typing.TypeAlias = int
      x: MyType = 1
    |}
    [];
  assert_type_errors
    {|
      import typing
      # Type aliases cannot be annotated
      MyType: typing.Type[int] = int
      x: MyType = 1
    |}
    ["Undefined or invalid type [11]: Annotation `MyType` is not defined as a type."];
  assert_type_errors
    {|
      x: MyType = 1
    |}
    ["Unbound name [10]: Name `MyType` is used but not defined in the current scope."];
  assert_type_errors
    {|
      MyType: int
      x: MyType = 1
    |}
    ["Undefined or invalid type [11]: Annotation `MyType` is not defined as a type."];
  assert_strict_type_errors
    {|
      MyType = 1
      x: MyType = 1
    |}
    ["Undefined or invalid type [11]: Annotation `MyType` is not defined as a type."];

  (* Type aliases cannot be nested *)
  assert_type_errors
    {|
        def foo() -> None:
          MyType = int
          x: MyType = 1
      |}
    ["Undefined or invalid type [11]: Annotation `foo.MyType` is not defined as a type."];
  assert_type_errors
    {|
      class Foo:
        X = int
      x: Foo.X = ...
    |}
    ["Undefined or invalid type [11]: Annotation `Foo.X` is not defined as a type."];
  assert_type_errors
    {|
        import typing
        def foo() -> None:
          MyType: typing.TypeAlias = int
          x: MyType = 1
      |}
    [
      "Invalid type [31]: Expression `MyType` is not a valid type. All type alias declarations \
       must be made in the module definition.";
      "Undefined or invalid type [11]: Annotation `foo.MyType` is not defined as a type.";
    ];

  (* Type aliases to Any *)
  assert_type_errors
    {|
      import typing
      MyType: typing.Any
      x: MyType = 1
    |}
    [
      "Missing global annotation [5]: Globally accessible variable `MyType` "
      ^ "must be specified as type other than `Any`.";
      "Undefined or invalid type [11]: Annotation `MyType` is not defined as a type.";
    ];
  assert_type_errors
    {|
      import typing
      MyType = typing.Any
      x: MyType = 1
    |}
    ["Prohibited any [33]: `MyType` cannot alias to `Any`."];
  assert_type_errors
    {|
      import typing
      MyType = typing.Any
      x: typing.List[MyType] = [1]
    |}
    ["Prohibited any [33]: `MyType` cannot alias to `Any`."];

  (* Un-parseable expressions *)
  assert_type_errors
    {|
      def foo() -> (int, str):
        return 1
    |}
    ["Invalid type [31]: Expression `(int, str)` is not a valid type."];
  assert_type_errors
    {|
      def foo(x: int + str) -> None:
        return
    |}
    ["Invalid type [31]: Expression `int.__add__(str)` is not a valid type."];

  (* Using expressions of type meta-type: only OK in isinstance *)
  assert_type_errors
    {|
      import typing
      def f(my_type: typing.Type[int]) -> None:
       x: my_type = ...
    |}
    ["Undefined or invalid type [11]: Annotation `my_type` is not defined as a type."];
  assert_type_errors
    {|
      import typing
      def f(my_type: typing.Type[int]) -> None:
       y = typing.cast(my_type, "string")
    |}
    ["Undefined or invalid type [11]: Annotation `my_type` is not defined as a type."];
  assert_type_errors
    {|
      import typing
      def f(my_type: typing.Type[int]) -> None:
       y = "string"
       assert isinstance(y, my_type)
       reveal_type(y)
    |}
    ["Revealed type [-1]: Revealed type for `y` is `int`."];
  assert_type_errors
    {|
      import typing
      def takes_exception(x: Exception) -> None: ...
      def f(e: typing.Type[Exception]) -> None:
       try:
         pass
       except e as myexception:
         takes_exception(myexception)
    |}
    [];
  assert_type_errors
    {|
      import typing
      x: typing.Dict[int, [str]]
    |}
    [
      "Invalid type parameters [24]: Single type parameter `Variable[_S]` expected, but a type \
       parameter group `[str]` was given for generic type dict.";
    ];
  assert_type_errors
    {|
      from typing import TypeVar, Generic

      TValue = TypeVar("TValue", bound=int)

      class Foo(Generic[TValue]): pass

      def foo() -> Foo[garbage]: ...
    |}
    ["Unbound name [10]: Name `garbage` is used but not defined in the current scope."];

  (* Malformed alias assignment *)
  assert_type_errors
    {|
      X, Y = int
      x: X = ...
    |}
    [
      "Missing global annotation [5]: Globally accessible variable `X` has no type specified.";
      "Unable to unpack [23]: Unable to unpack `typing.Type[int]` into 2 values.";
      "Missing global annotation [5]: Globally accessible variable `Y` has no type specified.";
      "Undefined or invalid type [11]: Annotation `X` is not defined as a type.";
    ];
  ()


let test_check_illegal_annotation_target context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
      class Bar:
        a: str = "string"
      class Foo:
        def foo(self) -> None:
          x = Bar()
          x.a: int = 1
          reveal_type(x.a)
    |}
    [
      "Illegal annotation target [35]: Target `x.a` cannot be annotated.";
      "Revealed type [-1]: Revealed type for `x.a` is `str`.";
    ];
  assert_type_errors
    {|
      class Bar: ...
      class Foo:
        def foo(self) -> None:
          Bar(): int = 1
    |}
    ["Illegal annotation target [35]: Target `Bar()` cannot be annotated."];
  assert_type_errors
    {|
      class Bar: ...
      class Foo:
        def foo(self, x: Bar) -> None:
          self.a: int = 1
          x.a: int = 1
    |}
    [
      "Undefined attribute [16]: `Foo` has no attribute `a`.";
      "Illegal annotation target [35]: Target `x.a` cannot be annotated.";
      "Undefined attribute [16]: `Bar` has no attribute `a`.";
    ];
  assert_type_errors
    {|
      class Foo:
        a: int = 1

      Foo.a: str = "string"
      reveal_type(Foo.a)
    |}
    [
      "Illegal annotation target [35]: Target `test.Foo.a` cannot be annotated.";
      "Revealed type [-1]: Revealed type for `test.Foo.a` is `int`.";
    ]


let test_check_missing_type_parameters context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("_T")
      class C(typing.Generic[T]): ...
      def f(c: C) -> None:
        return None
    |}
    ["Invalid type parameters [24]: Generic type `C` expects 1 type parameter."];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("_T")
      class C(typing.Generic[T]): ...
      def f(c: typing.List[C]) -> None:
        return None
    |}
    ["Invalid type parameters [24]: Generic type `C` expects 1 type parameter."];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("_T")
      class C(typing.Generic[T]): ...
      def f() -> typing.List[C]:
        return []
    |}
    ["Invalid type parameters [24]: Generic type `C` expects 1 type parameter."];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("_T")
      S = typing.TypeVar("_S")
      class C(typing.Generic[T, S]): ...
      def f() -> typing.List[C]:
        return []
    |}
    ["Invalid type parameters [24]: Generic type `C` expects 2 type parameters."]


let test_check_analysis_failure context =
  assert_type_errors
    ~context
    {|
      def foo() -> Derp:
        pass

      def bar(x: int = foo()) -> int:
        return x
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Incompatible variable type [9]: x is declared to have type `int` "
      ^ "but is used as type `unknown`.";
    ];
  assert_type_errors
    ~context
    {|
      def foo(x: int) -> None:
        pass

      def bar(x: Derp) -> None:
        test = foo( **x )
    |}
    [
      "Unbound name [10]: Name `Derp` is used but not defined in the current scope.";
      "Invalid argument [32]: Keyword argument `x` has type `unknown` "
      ^ "but must be a mapping with string keys.";
    ]


let test_check_immutable_annotations context =
  let assert_type_errors = assert_type_errors ~context in
  let assert_default_type_errors = assert_default_type_errors ~context in
  let assert_strict_type_errors = assert_strict_type_errors ~context in
  assert_type_errors
    {|
      a: int = None
      def foobar() -> None:
          b: int = None
    |}
    [
      "Incompatible variable type [9]: a is declared to have type `int` "
      ^ "but is used as type `None`.";
      "Incompatible variable type [9]: b is declared to have type `int` "
      ^ "but is used as type `None`.";
    ];
  assert_type_errors
    {|
      def foo() -> None:
        x: int = 1
        x = 'string'
    |}
    ["Incompatible variable type [9]: x is declared to have type `int` but is used as type `str`."];
  assert_type_errors
    {|
      from builtins import int_to_str
      def f(x: int) -> None:
        x: str = int_to_str(x)
    |}
    [];
  assert_type_errors
    {|
    constant: int
    def foo() -> None:
      global constant
      constant = "hi"
    |}
    [
      "Incompatible variable type [9]: constant is declared to have type `int` but is used as "
      ^ "type `str`.";
    ];
  assert_default_type_errors
    {|
      import typing
      def expects_str(x: str) -> None:
        pass

      def foo(x: int, y: typing.Any) -> None:
        x = y
        expects_str(x)
    |}
    [];
  assert_type_errors
    {|
      def foo(x: str = 1) -> str:
        return x
    |}
    [
      "Incompatible variable type [9]: x is declared to have type `str` but is used as "
      ^ "type `int`.";
    ];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar('T')
      def foo(x: T = 1) -> T:
        return x
    |}
    [];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar('T', int, float)
      def foo(x: T = 1) -> T:
        return x
    |}
    [];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar('T', int, float)
      def foo(x: T = "str") -> T:
        return x
    |}
    [
      "Incompatible variable type [9]: "
      ^ "x is declared to have type `Variable[T <: [int, float]]` but is used as type `str`.";
    ];
  assert_type_errors
    {|
      import typing
      class B: pass
      class C(B): pass
      T = typing.TypeVar('T', bound=B)
      def foo(x: T = C()) -> T:
        return x
    |}
    [];
  assert_type_errors
    {|
      import typing
      class O: pass
      class B: pass
      class C(B): pass
      T = typing.TypeVar('T', bound=B)
      def foo(x: T = O()) -> T:
        return x
    |}
    [
      "Incompatible variable type [9]: "
      ^ "x is declared to have type `Variable[T (bound to B)]` but is used as type `O`.";
    ];
  assert_type_errors
    {|
      import typing
      def bar() -> typing.Any:
        ...
      def foo(x: str = bar()) -> str:
        return x
    |}
    ["Missing return annotation [3]: Return type must be specified as type other than `Any`."];
  assert_type_errors
    {|
      constant: int
      def foo() -> None:
        constant = "hi"
    |}
    [];

  (* TODO (T56371223): Emit an invalid assignment error when trying to re-annotated a global like
     this *)
  assert_type_errors
    {|
      constant: int
      def foo() -> None:
        global constant
        constant: str
        constant = "hi"
    |}
    [
      "Incompatible variable type [9]: constant is declared to have type `int` but is used as type \
       `str`.";
    ];
  assert_type_errors
    {|
      import typing
      constant: typing.Union[int, str]
      def foo() -> None:
        global constant
        constant = 1
    |}
    [];
  assert_type_errors
    {|
      import typing
      constant: typing.Optional[int]
      def foo() -> int:
        if constant is not None:
          return constant
        return 0
    |}
    ["Incompatible return type [7]: Expected `int` but got `typing.Optional[int]`."];
  assert_type_errors
    {|
      import typing
      def foo() -> int:
        constant: typing.Optional[int]
        if constant is not None:
          return constant
        return 0
    |}
    [];
  assert_type_errors
    {|
      import typing
      def foo() -> int:
        constant: typing.Optional[str]
        if constant is not None:
          return constant
        return 0
    |}
    ["Incompatible return type [7]: Expected `int` but got `str`."];
  assert_type_errors
    {|
      import typing
      def foo() -> int:
        constant: typing.Optional[int]
        if constant is not None:
          return 0
        return constant
    |}
    ["Incompatible return type [7]: Expected `int` but got `None`."];

  assert_type_errors
    {|
      import typing
      constant: typing.Any
      def foo() -> None:
        global constant
        constant = 1
    |}
    [
      "Missing global annotation [5]: Globally accessible variable `constant` must be specified as \
       type other than `Any`.";
    ];
  assert_type_errors
    {|
      constant: int
      def foo(x: int) -> str:
        if x > 10:
          global constant
          constant: str
        return constant
    |}
    ["Incompatible return type [7]: Expected `str` but got `int`."];
  assert_type_errors
    {|
      def foo(x: int) -> None:
        x = "hi"
    |}
    [
      "Incompatible variable type [9]: x is declared to have type `int` but is used as "
      ^ "type `str`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo(x: typing.Optional[int]) -> None:
        x = 1
    |}
    [];
  assert_type_errors {|
      def foo(x: int) -> None:
        x: str
        x = "hi"
    |} [];
  assert_type_errors
    {|
      def foo() -> None:
        x = 1
        y: str
        y = x
        x = y
    |}
    [
      "Incompatible variable type [9]: y is declared to have type `str` but is used as "
      ^ "type `int`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo(any: typing.Any) -> None:
        x: int = any
    |}
    ["Missing parameter annotation [2]: Parameter `any` must have a type other than `Any`."];
  assert_strict_type_errors
    {|
      import typing
      def foo(any: typing.Any) -> None:
        x: int = any
    |}
    ["Missing parameter annotation [2]: Parameter `any` must have a type other than `Any`."];
  assert_type_errors
    {|
      def foo(x: int) -> None:
        if x > 10:
          y: int
        else:
          y: str

        y = "hi"
    |}
    [];
  assert_type_errors
    {|
      def foo(x: int) -> None:
        if x > 10:
          y: int
        else:
          y: str
        y = 1
    |}
    [];
  assert_type_errors
    {|
      class Foo():
        attribute = ...
      def bar() -> int:
        foo = Foo()
        foo.attribute = 1
        return foo.attribute
    |}
    [
      "Missing attribute annotation [4]: Attribute `attribute` of class `Foo` has no type specified.";
      "Incompatible return type [7]: Expected `int` but got `unknown`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.Dict[str, typing.Any] = {}
        x = { 'a': 'b' }
    |}
    [];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.Dict[str, typing.List[typing.Any]] = {}
    |}
    ["Prohibited any [33]: Explicit annotation for `x` cannot contain `Any`."];
  assert_default_type_errors
    {|
      constant = 1
      def foo() -> None:
        global constant
        constant = 1
    |}
    [];
  assert_type_errors
    {|
      class Foo():
        constant = ...
      def foo() -> None:
        foo = Foo()
        foo.constant = 1
    |}
    ["Missing attribute annotation [4]: Attribute `constant` of class `Foo` has no type specified."];
  assert_type_errors
    {|
      import typing
      x = 1
      y: typing.Any = 2
      z: typing.List[typing.Any] = [3]
      a: typing.Any

      def foo() -> int:
        global a
        a = 1
        return a
    |}
    [
      "Missing global annotation [5]: Globally accessible variable `y` has type `int` "
      ^ "but type `Any` is specified.";
      "Missing global annotation [5]: Globally accessible variable `z` must be specified "
      ^ "as type that does not contain `Any`.";
      "Missing global annotation [5]: Globally accessible variable `a` must be specified as type \
       other than `Any`.";
    ];
  assert_type_errors
    {|
      import typing
      class Foo():
        __slots__: typing.List[str] = ['name']
        def foo(self) -> str:
          return self.name
    |}
    ["Incompatible return type [7]: Expected `str` but got `unknown`."];
  assert_type_errors
    {|
      import typing
      class Foo():
        __slots__: typing.List[str] = ['name', 'attribute']
        def foo(self) -> str:
          return self.name + self.attribute + self.constant
    |}
    ["Undefined attribute [16]: `Foo` has no attribute `constant`."];
  assert_type_errors
    {|
      import typing
      class Foo():
        __slots__: typing.List[str] = ['name']
        def foo(self) -> str:
          return self.name
        def __init__(self) -> None:
          self.name: int = 1
    |}
    ["Incompatible return type [7]: Expected `str` but got `int`."]


let test_check_incomplete_annotations context =
  let assert_type_errors = assert_type_errors ~context in
  let assert_default_type_errors = assert_default_type_errors ~context in
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.Any = 1
    |}
    [
      "Prohibited any [33]: Expression `x` has type `int`; " ^ "given explicit type cannot be `Any`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.List[typing.Any] = []
    |}
    ["Prohibited any [33]: Explicit annotation for `x` cannot contain `Any`."];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x = 1
        typing.cast(typing.Any, x)
    |}
    ["Prohibited any [33]: Explicit annotation for `typing.cast` cannot be `Any`."];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x = 1
        typing.cast(typing.List[typing.Any], x)
    |}
    ["Prohibited any [33]: Explicit annotation for `typing.cast` cannot contain `Any`."];
  assert_default_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.Any = 1
    |}
    [];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.Dict[str, typing.Any] = {}
    |}
    [];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        x: typing.List[typing.Dict[str, typing.Any]] = []
    |}
    [];
  assert_default_type_errors
    {|
      import typing
      def foo() -> None:
        x = 1
        typing.cast(typing.Any, x)
    |}
    [];
  assert_type_errors {|
      import typing
      MyDict = typing.Dict[str, typing.Any]
    |} []


let test_check_incomplete_callable context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
      import typing
      def foo(x: int) -> str:
        return "foo"
      bar: typing.Callable[[int], bool] = foo
    |}
    [
      "Incompatible variable type [9]: bar is declared to have type `typing.Callable[[int], bool]` \
       but is used as type `typing.Callable(foo)[[Named(x, int)], str]`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo(x: int) -> str:
        return "foo"
      bar: typing.Callable[[int]] = foo

      def baz(x: typing.Callable[[int]]) -> typing.Callable[[int]]: ...
    |}
    [
      "Invalid type [31]: Expression `typing.Callable[[int]]` is not a valid type.";
      "Invalid type [31]: Expression `typing.Callable[[int]]` is not a valid type.";
      "Invalid type [31]: Expression `typing.Callable[[int]]` is not a valid type.";
    ];
  ()


let test_check_refinement context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
      def takes_int(a: int) -> None: pass
      def foo() -> None:
        x: float
        x = 1
        takes_int(x)
        x = 1.0
    |}
    [];

  (* List[Any] correctly can refine to List[int] *)
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        l: typing.List[typing.Any] = []
        l = [1]
        l.append('asdf')
    |}
    [
      "Prohibited any [33]: Explicit annotation for `l` cannot contain `Any`.";
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `list.append` but got `str`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        l: typing.List[int] = []
        l.append('a')
    |}
    [
      "Incompatible parameter type [6]: "
      ^ "Expected `int` for 1st positional only parameter to call `list.append` but got `str`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo() -> None:
        l: typing.List[int] = None
        l.append('a')
    |}
    [
      "Incompatible variable type [9]: l is declared to have type `typing.List[int]` "
      ^ "but is used as type `None`.";
      "Incompatible parameter type [6]: "
      ^ "Expected `int` for 1st positional only parameter to call `list.append` but got `str`.";
    ];
  assert_type_errors
    {|
      import typing
      def foo(x: typing.Optional[int]) -> int:
        if not x:
          return 1
        return x
    |}
    [];
  assert_type_errors
    {|
      import typing
      def foo(x: typing.Optional[int]) -> int:
        if not x:
          y = x
        return x
    |}
    ["Incompatible return type [7]: Expected `int` but got `typing.Optional[int]`."];
  assert_type_errors
    {|
      import typing
      class A:
          a: typing.Optional[int] = None
          def foo(self) -> None:
              if self.a is None:
                  self.a = 5
    |}
    [];
  assert_type_errors
    {|
      import typing
      class A:
          a: typing.Optional[int] = None
          def bar(self) -> int:
              if self.a is not None:
                  return self.a
              else:
                  return 1
    |}
    ["Incompatible return type [7]: Expected `int` but got `typing.Optional[int]`."];
  assert_type_errors
    {|
      from builtins import int_to_int
      import typing
      def bar(x: typing.Optional[int]) -> None:
          if x and int_to_int(x) < 0:
              y = 1
    |}
    [];
  assert_type_errors
    {|
      import typing
      def bar(input: typing.Optional[typing.Set[int]]) -> typing.Set[int]:
          if not input:
            input = set()
          return input
    |}
    [];
  ()


let test_check_invalid_type_variables context =
  let assert_type_errors = assert_type_errors ~context in
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T")
      def f(x: T) -> T:
        return x
    |}
    [];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T")
      def f() -> T:
        return T
    |}
    [
      "Invalid type variable [34]: The type variable `Variable[T]` isn't present in the function's \
       parameters.";
    ];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T")
      class C:
        x: T = 1
    |}
    [
      "Invalid type variable [34]: The current class isn't generic with respect to the type \
       variable `Variable[T]`.";
    ];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T")
      x: T = ...
    |}
    [
      "Invalid type variable [34]: The type variable `Variable[T]` can only be used to annotate \
       generic classes or functions.";
    ];

  (* We don't error for inferred generics. *)
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T")
      class C(typing.Generic[T]):
        pass
      class D(C[T]):
        pass
    |}
    [];

  (* The inline Callable type does not actually make a new type variable scope *)
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T")
      def f() -> typing.Callable[[T], T]:
        def g(x: T) -> T:
          return x
        return g
    |}
    [
      "Invalid type variable [34]: The type variable `Variable[T]` isn't present in the function's \
       parameters.";
    ];

  (* Check invalid type variables in parameters and returns. *)
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T", covariant=True)
      class Foo(typing.Generic[T]):
        def foo(self, x: T) -> T:
          return x
    |}
    [
      "Invalid type variance [46]: The type variable `Variable[T](covariant)` is covariant "
      ^ "and cannot be a parameter type.";
    ];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T", covariant=True)
      class Foo(typing.Generic[T]):
        def __init__(self, x: T) -> None:
          return
    |}
    [];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T", covariant=True)
      class Foo(typing.Generic[T]):
        def foo(self, x: typing.List[T]) -> T:
          return x[0]
    |}
    [];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T", contravariant=True)
      class Foo(typing.Generic[T]):
        def foo(self, x: T) -> T:
          return x
    |}
    [
      "Invalid type variance [46]: The type variable `Variable[T](contravariant)` is "
      ^ "contravariant and cannot be a return type.";
    ];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T", contravariant=True)
      class Foo(typing.Generic[T]):
        def foo(self, x: T) -> typing.List[T]:
          return [x]
    |}
    [];
  assert_type_errors
    {|
      import typing
      T = typing.TypeVar("T", covariant=True)
      def foo(x: T) -> T:
        return x
    |}
    [
      "Invalid type variance [46]: The type variable `Variable[T](covariant)` is covariant "
      ^ "and cannot be a parameter type.";
    ]


let test_check_aliases context =
  assert_type_errors
    ~context
    {|
      import typing_extensions
      class C(typing_extensions.Protocol):
        ...
    |}
    [];
  assert_type_errors
    ~context
    {|
      import typing_extensions
      class C(typing_extensions.Protocol[int]):
        ...
    |}
    [];
  assert_type_errors
    ~context
    {|
      class FOO:
        x: int = 0
      class BAR:
        pass
      FOO = BAR
      def foo(a: FOO) -> int:
        return a.x
      foo(FOO())
    |}
    [
      "Incompatible return type [7]: Expected `int` but got `unknown`.";
      "Undefined attribute [16]: `BAR` has no attribute `x`.";
      "Incompatible parameter type [6]: Expected `BAR` for 1st positional only parameter to call \
       `foo` but got `FOO`.";
    ];

  (* Locals are not aliases *)
  assert_type_errors
    ~context
    {|
      def foo() -> None:
        x = int
        y: x = 1
    |}
    ["Undefined or invalid type [11]: Annotation `foo.x` is not defined as a type."];

  assert_type_errors ~context {|
      def foo(type: int) -> None:
        x = type
    |} [];

  (* Aliases to undefined types *)
  assert_type_errors
    ~context
    {|
      import typing
      MyAlias = typing.Union[int, UndefinedName]
    |}
    [
      "Missing global annotation [5]: Globally accessible variable `MyAlias` has no type specified.";
      "Unbound name [10]: Name `UndefinedName` is used but not defined in the current scope.";
    ];
  (* TODO (T61917464): Surface explicit type aliases registeration failures as type errors *)
  assert_type_errors
    ~context
    {|
      import typing
      MyAlias: typing.TypeAlias = typing.Union[int, UndefinedName]
    |}
    ["Unbound name [10]: Name `UndefinedName` is used but not defined in the current scope."];
  (* TODO (T61917464): Surface explicit type aliases registeration failures as type errors *)
  assert_type_errors
    ~context
    {|
      import typing
      MyAlias: typing.TypeAlias = typing.Union[int, "UndefinedName"]
    |}
    [];

  (* Aliases to invalid types *)
  assert_type_errors
    ~context
    {|
      import typing
      MyAlias = typing.Union[int, 3]
    |}
    ["Missing global annotation [5]: Globally accessible variable `MyAlias` has no type specified."];
  assert_type_errors
    ~context
    {|
      import typing
      MyAlias: typing.TypeAlias = typing.Union[int, 3]
    |}
    []


let test_final_type context =
  assert_type_errors ~context {|
      from typing import Final
      x: Final[int] = 3
    |} [];
  assert_type_errors
    ~context
    {|
      from typing import Final
      x: Final[str] = 3
    |}
    ["Incompatible variable type [9]: x is declared to have type `str` but is used as type `int`."]


let test_check_invalid_inheritance context =
  assert_type_errors
    ~context
    {|
      from typing import Callable
      class MyCallable(Callable):
        pass
    |}
    ["Invalid inheritance [39]: `typing.Callable[..., typing.Any]` is not a valid parent class."];
  assert_type_errors
    ~context
    {|
      from typing import Any
      class MySpecialClass(Any, int):
        pass
    |}
    ["Invalid inheritance [39]: `typing.Any` is not a valid parent class."];
  ()


let test_check_invalid_generic_inheritance context =
  assert_type_errors
    ~context
    {|
        from typing import Generic, TypeVar

        T = TypeVar('T')
        class Base(Generic[T]):
          def __init__(self, foo: T) -> None:
            self.foo = foo
        class Child(Base[T]): pass
        class InstantiatedChild(Base[int]): pass

        y: Base[str] = Base(0)
        # Check __init__.
        InstantiatedChild("foo")

        x: Child[str] = Child(0)
        correct: Child[str] = Child("bar")
      |}
    [
      "Incompatible variable type [9]: y is declared to have type `Base[str]` but is used as type \
       `Base[int]`.";
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `Base.__init__` but got `str`.";
      "Incompatible variable type [9]: x is declared to have type `Child[str]` but is used as type \
       `Child[int]`.";
      "Incompatible variable type [9]: correct is declared to have type `Child[str]` but is used \
       as type `Child[str]`.";
    ];
  (* Check __new__. *)
  assert_type_errors
    ~context
    {|
        from typing import Generic, TypeVar

        T = TypeVar('T')
        T2 = TypeVar('T2')
        class Base(Generic[T, T2]):
          def __new__(cls, foo: T, bar: T2) -> Base[T, T2]:
            self = super(Base, cls).__new__(cls)
            self.foo = foo
            self.bar = bar
            return self
        class PartialChild(Base[int, T2], Generic[T2]): pass

        PartialChild("hello", "world")
      |}
    [
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `Base.__new__` but got `str`.";
    ];
  assert_type_errors
    ~context
    {|
        from typing import Generic, TypeVar

        T = TypeVar('T')
        T2 = TypeVar('T2')
        class Base(Generic[T, T2]):
          def __init__(self, foo: T, bar: T2) -> None:
            self.foo = foo
            self.bar = bar
        class PartialChild(Base[int, T2], Generic[T2]): pass

        PartialChild("hello", "world")
        y1: PartialChild[str] = PartialChild(0, "hello")
        y2: PartialChild[str] = PartialChild(0, 1)
        y3: PartialChild[str] = PartialChild("hello", 0)
        y4: PartialChild[int] = PartialChild(0, "hello")
      |}
    [
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `Base.__init__` but got `str`.";
      "Incompatible variable type [9]: y1 is declared to have type `PartialChild[str]` but is used \
       as type `PartialChild[str]`.";
      "Incompatible variable type [9]: y2 is declared to have type `PartialChild[str]` but is used \
       as type `PartialChild[int]`.";
      "Incompatible variable type [9]: y3 is declared to have type `PartialChild[str]` but is used \
       as type `PartialChild[int]`.";
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `Base.__init__` but got `str`.";
      "Incompatible variable type [9]: y4 is declared to have type `PartialChild[int]` but is used \
       as type `PartialChild[str]`.";
    ];
  assert_type_errors
    ~context
    {|
        from typing import Generic, TypeVar

        T = TypeVar('T')
        T2 = TypeVar('T2')
        class Base(Generic[T, T2]):
          def __init__(self, foo: T, bar: T2) -> None:
            self.foo = foo
            self.bar = bar
        class PartialChildWithConstructor(Base[int, T2], Generic[T2]):
          def __init__(self, first: T2, second: int, third: str) -> None:
            self.foo: int = second
            self.bar: T2 = first
            self.third: str = third

        PartialChildWithConstructor("hello", 0, 0)
        y3: PartialChildWithConstructor[str] = PartialChildWithConstructor(0, 0, "world")
      |}
    [
      "Incompatible parameter type [6]: Expected `str` for 3rd positional only parameter to call \
       `PartialChildWithConstructor.__init__` but got `int`.";
      "Incompatible variable type [9]: y3 is declared to have type \
       `PartialChildWithConstructor[str]` but is used as type `PartialChildWithConstructor[int]`.";
    ];
  assert_type_errors
    ~context
    {|
        from typing import Generic, TypeVar

        T = TypeVar('T')
        T2 = TypeVar('T2')
        T3 = TypeVar('T3')
        class Base(Generic[T, T2]):
          def __init__(self, foo: T, bar: T2) -> None:
            self.foo = foo
            self.bar = bar
        class TypeNotUsedInConstructor(Base[int, T2], Generic[T2, T3]):
          def __init__(self, first: T2, second: int, third: str) -> None:
            self.foo: int = second
            self.bar: T2 = first
            self.third: str = third

          def identity(self, x: T3) -> T3: ...

        y1: TypeNotUsedInConstructor[str, int]
        reveal_type(y1.identity(0))
        y1.identity("hello")
        reveal_type(y1.identity("hello"))
      |}
    [
      "Revealed type [-1]: Revealed type for `y1.identity(0)` is `int`.";
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `TypeNotUsedInConstructor.identity` but got `str`.";
      "Revealed type [-1]: Revealed type for `y1.identity(\"hello\")` is `int`.";
    ];
  assert_type_errors
    ~context
    {|
        from typing import Generic, TypeVar

        T = TypeVar('T')
        T2 = TypeVar('T2')
        class Base(Generic[T, T2]):
          def __init__(self, foo: T, bar: T2) -> None:
            self.foo = foo
            self.bar = bar
          def generic_method(self, x: T, y: T2) -> None: ...

        class Child(Base[T, T2]): pass
        class PartialChild(Base[int, T2], Generic[T2]): pass

        y1: Base[str, int] = Base("hello", 1)
        y2: Child[str, int] = Child("hello", 1)
        y3: PartialChild[str] = PartialChild(0, "hello")
        def call_base(x: Base[str, int]) -> None:
          x.generic_method("hello", 1)
          x.generic_method("hello", "world")
        def call_child(x: Child[str, int]) -> None:
          x.generic_method("hello", 1)
          x.generic_method("hello", "world")
        def call_partial_child(x: PartialChild[str]) -> None:
          x.generic_method(1, "world")
          x.generic_method("hello", "world")
      |}
    [
      "Incompatible variable type [9]: y1 is declared to have type `Base[str, int]` but is used as \
       type `Base[str, int]`.";
      "Incompatible variable type [9]: y2 is declared to have type `Child[str, int]` but is used \
       as type `Child[str, int]`.";
      "Incompatible variable type [9]: y3 is declared to have type `PartialChild[str]` but is used \
       as type `PartialChild[str]`.";
      "Incompatible parameter type [6]: Expected `int` for 2nd positional only parameter to call \
       `Base.generic_method` but got `str`.";
      "Incompatible parameter type [6]: Expected `int` for 2nd positional only parameter to call \
       `Base.generic_method` but got `str`.";
      "Incompatible parameter type [6]: Expected `int` for 1st positional only parameter to call \
       `Base.generic_method` but got `str`.";
    ];
  ()


let test_check_literal_assignment context =
  assert_type_errors
    ~context
    {|
      from typing_extensions import Literal
      x: Literal["on", "off"] = "on"
    |}
    [];
  assert_type_errors
    ~context
    {|
      from typing import Generic, TypeVar

      T = TypeVar('T')
      class Foo(Generic[T]):
        foo: T
        def __init__(self, foo: T) -> None:
          self.foo = foo

      def foo(s: str) -> None:
        string: Foo[str] = Foo(s)
        literal_string: Foo[str] = Foo("bar")
    |}
    [
      "Incompatible variable type [9]: literal_string is declared to have type `Foo[str]` but is \
       used as type `Foo[str]`.";
    ];
  ()


let test_check_safe_cast context =
  assert_type_errors
    ~context
    {|
      import pyre_extensions
      def foo(input: float) -> int:
        return pyre_extensions.safe_cast(int, input)
    |}
    [
      "Unsafe cast [49]: `safe_cast` is only permitted to loosen the type of `input`. `float` is \
       not a super type of `input`.";
    ];
  assert_type_errors
    ~context
    {|
        import pyre_extensions
        def foo(input: int) -> float:
          return pyre_extensions.safe_cast(float, input)
    |}
    []


let test_check_annotation_with_any context =
  assert_type_errors
    ~context
    {|
      from typing import List, Any
      def foo(x: List[Any] = None) -> None:
        pass
    |}
    [
      "Incompatible variable type [9]: x is declared to have type `List[typing.Any]` but is used \
       as type `None`.";
      "Missing parameter annotation [2]: Parameter `x` is used as type `None` and must have a type \
       that does not contain `Any`.";
    ]


let () =
  "annotation"
  >::: [
         "check_undefined_type" >:: test_check_undefined_type;
         "check_invalid_type" >:: test_check_invalid_type;
         "check_illegal_annotation_target" >:: test_check_illegal_annotation_target;
         "check_invalid_type_variables" >:: test_check_invalid_type_variables;
         "check_missing_type_parameters" >:: test_check_missing_type_parameters;
         "check_analysis_failure" >:: test_check_analysis_failure;
         "check_immutable_annotations" >:: test_check_immutable_annotations;
         "check_incomplete_annotations" >:: test_check_incomplete_annotations;
         "check_incomplete_callable" >:: test_check_incomplete_callable;
         "check_refinement" >:: test_check_refinement;
         "check_aliases" >:: test_check_aliases;
         "check_final_type" >:: test_final_type;
         "check_invalid_inheritance" >:: test_check_invalid_inheritance;
         "check_invalid_generic_inheritance" >:: test_check_invalid_generic_inheritance;
         "check_literal_assignment" >:: test_check_literal_assignment;
         "check_safe_cast" >:: test_check_safe_cast;
         "check_annotation_with_any" >:: test_check_annotation_with_any;
       ]
  |> Test.run
