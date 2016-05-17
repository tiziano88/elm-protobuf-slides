# elm-protobuf

_Cross-language data serialization and RPC for the web._

https://github.com/tiziano88/elm-protobuf

## Tiziano Santoro

### _Software Engineer - Google_

--

## Protocol Buffers

> Protocol buffers are a language-neutral, platform-neutral extensible mechanism
> for serializing structured data.

-   Developed by Google.
-   First released in 2008.
-   Officially supported languages: C++, C#, Go, Java, Python.
-   Schema for data.
-   Used for storage and RPCs.
-   Efficient binary encoding.
-   Initially only supported binary encoding, now also JSON.

--

## How it works

-   Define message formats in a `.proto` file.
-   Run the protocol buffer compiler for the relevant target language(s):

    ```
    protoc --elm_out=./elm --go_out=./go proto/*.proto
    ```

--

## Syntax

-   proto2:

    ```protobuf
    message Person {
      required string name = 1;
      optional string email = 2;
      optional Address address = 3;
      repeated Order orders = 3;
    }
    ```

-   proto3:

    ```protobuf
    message Person {
      string name = 1;
      string email = 2;
      Address address = 3;
      repeated Order orders = 4;
    }
    ```

--

## JSON

```protobuf
message Person {
  string name = 1;
  string email = 2;
  Address address = 3;
  repeated Order orders = 4;
}
```

```json
{
  "name": "John Smith",
  "email": "test@example.com",
  "address": {
    "city": "London",
    "country": "GB"
  },
  "orders": [
    ...
  ]
}
```

--

## Implementing a new protoc plugin

> `protoc` (aka the Protocol Compiler) can be extended via plugins. A plugin is
> just a program that reads a `CodeGeneratorRequest` from stdin and writes a
> `CodeGeneratorResponse` to stdout.
>
> A plugin executable needs only to be placed somewhere in the path. The plugin
> should be named `protoc-gen-$NAME`, and will then be used when the flag
> `--${NAME}_out` is passed to protoc.

https://developers.google.com/protocol-buffers/docs/reference/cpp/google.protobuf.compiler.plugin.pb

--

## API for protoc plugins

```protobuf
message CodeGeneratorRequest {
  repeated string file_to_generate = 1;
  optional string parameter = 2;
  repeated FileDescriptorProto proto_file = 15;
}

message CodeGeneratorResponse {
  optional string error = 1;
  message File {
    optional string name = 1;
    optional string insertion_point = 2;
    optional string content = 15;
  }
  repeated File file = 15;
}
```

--

## protoc-gen-elm

-   Written in Go.
-   Generates Elm code.
-   Generated code has no runtime dependencies apart from `elm-lang/core`.
    -   No Elm protobuf runtime library (though it may change in the future).

--

## Primitive types

-   `{double,float}` → `Float`
-   `{int,uint,sint,fixed}{32,64}` → `Int`
-   `bool` → `Bool`
-   `string` → `String`

-   Zero value by default (in proto3):

    -   numeric: `0` / `0.0`
    -   string: `""`
    -   bool: `false`
    -   message field: absent
    -   repeated field: empty list
    -   enum field: default enum value

-   If a field is not explicitly set, it is the same as its default value, and
    it may be skipped during serialisation.

--

## Enum types

-   Must start with zero value (default).
-   Converted to new Elm type (sum type).

```protobuf
enum Colour {
  COLOUR_UNSPECIFIED = 0;
  RED = 1;
  GREEN = 2;
  BLUE = 3;
  BLACK = 99;
}
```

```elm
type Colour
  = ColourUnspecified
  | Red
  | Green
  | Blue
  | Black
```

--

## Enum encoder

```elm
colourEncoder : Colour -> Json.Encode.Value
colourEncoder v =
  let
    lookup s = case s of
      ColourUnspecified -> "COLOUR_UNSPECIFIED"
      Red -> "RED"
      Green -> "GREEN"
      Blue -> "BLUE"
      Black -> "BLACK"
  in
    Json.Encode.string <| lookup v
```

http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Encode#string

--

## Enum decoder

```elm
colourDecoder : Json.Decode.Decoder Colour
colourDecoder =
  let
    lookup s = case s of
      "COLOUR_UNSPECIFIED" -> ColourUnspecified
      "RED" -> Red
      "GREEN" -> Green
      "BLUE" -> Blue
      "BLACK" -> Black
  in
    Json.Decode.map lookup string
```

http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Decode#map

--

## Message types

-   Converted to Elm record type alias (product type).

```protobuf
message Person {
  string name = 1;
  string email = 2;
  Address address = 3;
  repeated Order orders = 4;
}
```

```elm
type alias Person =
  { name : String
  , email : String
  , address : Maybe Address
  , orders : List Order
  }
```

--

## Message encoder

```elm
personEncoder : Person -> Json.Encode.Value
personEncoder v =
  Json.Encode.object
    [ ("name", Json.Encode.string v.name)
    , ("email", Json.Encode.string v.email)
    , ("address", optionalEncoder addressEncoder v.address)
    , ("orders", repeatedFieldEncoder orderEncoder v.orders)
    ]
```

http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Encode#object

--

## Message decoder

```elm
personDecoder : Json.Decode.Decoder Person
personDecoder =
  Json.Decode.object4
    Person
    (stringFieldDecoder "name")
    (stringFieldDecoder "email")
    (optionalFieldDecoder addressDecoder "address")
    (repeatedFieldDecoder orderDecoder "orders")
```

http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Decode#object4

--

## objectN combinators

```elm
object1 : (a -> value)
    -> Decoder a
    -> Decoder value
object2 : (a -> b -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder value
object3 : (a -> b -> c -> value)
    -> Decoder a
    -> Decoder b
    -> Decoder c
    -> Decoder value
...
object8 : ...
```

-   _Lift_ regular constructors of various arity to corresponding Decoder
    instances.
-   Does not scale beyond 8 arguments.

--

## Generalizing decoders

```elm
map : (a -> b) -> Decoder a -> Decoder b

decoderA : Decoder A
decoderB : Decoder B
```

http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Decode#map

```elm
type alias Foo1 = { a : A }
Foo1 : A -> Foo1

map Foo1 decoderA : Decoder Foo1
```

```elm
type alias Foo2 = { a : A, b : B }
Foo2 : A -> B -> Foo2

map Foo2 decoderA : Decoder (B -> Foo2)
```

```elm
??? : Decoder (a -> b) -> Decoder a -> Decoder b
```

--

## The missing link

```elm
??? : Decoder (a -> b) -> Decoder a -> Decoder b
```

```elm
map : (a -> b) -> Decoder a -> Decoder b
andThen : Decoder a -> (a -> Decoder b) -> Decoder b
```

http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Decode#map
http://package.elm-lang.org/packages/elm-lang/core/4.0.0/Json-Decode#andThen

```elm
ap : Decoder (a -> b) -> Decoder a -> Decoder b
ap d1 d2 = andThen d1 (\x -> map x d2)
ap d1 d2 = d1 `andThen` (\x -> map x d2)

d1 : Decoder (A -> B)
d2 : Decoder A

andThen d1 : ((A -> B) -> Decoder B) -> Decoder B
(\x -> map x d2) : (A -> B) -> Decoder B
```

--

## Applicative-style parsing in Haskell

```haskell
class Functor f where
  fmap :: (a -> b) -> f a -> f b
(<$>) = fmap
class (Functor f) => Applicative f where
  pure :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
```

```haskell
Foo3 :: A -> B -> C -> Foo4

decoderA :: Decoder A
decoderB :: Decoder B
decoderC :: Decoder C

Foo3 <$> decoderA
  == fmap Foo3 decoderA
  :: Decoder (B -> C -> Foo3)

Foo3 <$> decoderA <*> decoderB <*> decoderC
  :: Decoder Foo3
```

--

## Applicative-style parsing in Elm

```elm
(<$>) : (a -> b) -> (Decoder a -> Decoder b)
(<$>) = map

(<*>) : Decoder (a -> b) -> Decoder a -> Decoder b
(<*>) f v = f `andThen` (\x -> x <$> v)
```

```elm
personDecoder : Json.Decode.Decoder Person
personDecoder =
  Person
    <$> (stringDecoder "name")
    <*> (stringDecoder "email")
    <*> (optionalFieldDecoder addressDecoder "address")
    <*> (repeatedFieldDecoder orderDecoder "orders")
```

--

## Testing

-   Equivalence testing:
    -   Written in Go.
    -   Only test the protoc plugin.
    -   Convert Proto file to Elm using the plugin, compare output against
        golden.
-   Integration testing:
    -   Written in Elm.
    -   Also test the generated elm code.
    -   JSON encode/decode sample data.

--

## Future work

-   reserved keywords
-   proto imports
-   proto packages
-   proto options
-   `Any` type
-   `Timestamp` type
-   `Duration` type
-   Wrapper types
-   `oneof` fields
-   `map` fields
