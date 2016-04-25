# elm-protobuf

```java
public class Test {}
```

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

## Format

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

```proto
message Person {
  string name = 1;
  int32 id = 2;
  optional string email = 3;
}
```

```json
{
  "name": "John Smith",
  "id": 123,
  "email": "test@example.com"
}
```
