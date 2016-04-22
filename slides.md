# elm-protobuf

--

# Protocol Buffers

> Protocol buffers are a language-neutral, platform-neutral extensible mechanism
> for serializing structured data.

-   Developed by Google
-   First released in 2008

--

# Format

-   proto2:

```proto
message Person {
  required string name = 1;
  required int32 id = 2;
  optional string email = 3;
}
```

-   proto3:

```proto
message Person {
  string name = 1;
  int32 id = 2;
  optional string email = 3;
}
```
