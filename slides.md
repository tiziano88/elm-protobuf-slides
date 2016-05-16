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

--

-   Schema for data.
-   Used for storage and RPCs.
-   Efficient binary encoding.

--

## How it works

-   Define message formats in a `.proto` file.
-   Use the protocol buffer compiler.

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
  int32 id = 2;
  string email = 3;
}
```

```json
{
  "name": "John Smith",
  "id": 123,
  "email": "test@example.com"
}
```

--

## Usage

```
protoc --elm_out=./elm --go_out=./go proto/*.proto
```

--

## Implementing a new plugin

> protoc (aka the Protocol Compiler) can be extended via plugins. A plugin is
> just a program that reads a CodeGeneratorRequest from stdin and writes a
> CodeGeneratorResponse to stdout.
>
> A plugin executable needs only to be placed somewhere in the path. The plugin
> should be named "protoc-gen-$NAME", and will then be used when the flag
> "--${NAME}_out" is passed to protoc.

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

-   Written in Go
-   No dependencies
    -   Not even runtime library (though it may change)

--

## Primitive Types

-   `{double,float}` → `Float`
-   `{int,uint,sint,fixed}{32,64}` → `Int`
-   `bool` → `Bool`
-   `string` → `String`

--

## Enum Types

-   Must start with zero value (default)
-   Converted to new Elm type

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

## Enum Encoder

```elm
colourEncoder : Colour -> Value
colourEncoder v =
  let
    lookup s = case s of
      ColourUnspecified -> "COLOUR_UNSPECIFIED"
      Red -> "RED"
      Green -> "GREEN"
      Blue -> "BLUE"
      Black -> "BLACK"
  in
    string <| lookup v
```

--

## Enum Decoder

```elm
colourDecoder : Decoder Colour
colourDecoder =
  let
    lookup s = case s of
      "COLOUR_UNSPECIFIED" -> ColourUnspecified
      "RED" -> Red
      "GREEN" -> Green
      "BLUE" -> Blue
      "BLACK" -> Black
  in
    map lookup string
```

--

## Message Types

-   Converted to Elm record type alias

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

## Message Encoder

```elm
personEncoder : Person -> Value
personEncoder v =
  Json.Encode.object
    [ ("name", Json.Encode.string v.name)
    , ("email", Json.Encode.string v.email)
    , ("address", optionalEncoder addressEncoder v.address)
    , ("orders", repeatedFieldEncoder orderEncoder v.orders)
    ]
```

--

## Message Decoder

```elm
personDecoder : Json.Decoder Person
personDecoder =
  Json.object4
    Person
    stringDecoder
    stringDecoder
    (optionalFieldDecoder addressDecoder)
    (repeatedFieldDecoder orderDecoder)
```

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

-   _lift_ combinators for various arity.
-   does not scale beyond 8 arguments

--

## Monadic-style parsing

-   `Json.Decode.Decoder a` is (conceptually) a Monad
-   elm does not have type classes or Higher Kinded Types, so this fact cannot
    be expressed within the type system
-   return:
    -   `map : (a -> b) -> (Decoder a -> Decoder b)`
    -   `object1 : (a -> value) -> (Decoder a -> Decoder value)`
-   bind (`>>=`):
    -   `andThen : Decoder a -> (a -> Decoder b) -> Decoder b`
-   `Json.Decode.Decoder a` is therefore also (conceptually) an Applicative
    Functor

--

## Applicative-style parsing

-   pure (`<$>`):
    -   `map : (a -> b) -> (Decoder a -> Decoder b)`
-   sequence (`<*>`):
    -   ``f `andThen` (\x -> x <$> v)``

```elm
(<$>) : (a -> b) -> Decoder a -> Decoder b
(<$>) =
  JD.map

(<*>) : Decoder (a -> b) -> Decoder a -> Decoder b
(<*>) f v =
  f `andThen` \x -> x <$> v
```

--

## Testing

-   Equivalence testing
    -   Written in Go
    -   Only test the protoc plugin
    -   Convert proto file to elm using the plugin, compare output against
        golden
-   Integration testing
    -   Written in Elm
    -   Also test the generated elm code
    -   JSON encode/decode sample data
