# elm-protobuf

_Cross-language data serialization and RPC for the web._

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
      required int32 id = 2;
      optional string email = 3;
    }
    ```

-   proto3:

    ```protobuf
    message Person {
      string name = 1;
      int32 id = 2;
      string email = 3;
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

> A plugin executable needs only to be placed somewhere in the path. The
> plugin should be named "protoc-gen-$NAME", and will then be used when the
> flag "--${NAME}_out" is passed to protoc.

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

- Written in Go.
