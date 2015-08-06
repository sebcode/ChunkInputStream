# ChunkInputStream

ChunkInputStream is a subclass of NSInputStream that wraps read access to a certain byte-range (chunk) of a file.

Use case: upload a chunk of a file by constructing `NSURLRequest` with `HTTPBodyStream`.

### Example

    let fileInputStream = NSInputStream(fileAtPath: "/tmp/readme")
    let inputStream = ChunkInputStream(inputStream: fileInputStream)
    inputStream.startPosition = 2097152
    inputStream.readMax = 1048576

This creates an inputStream that gives access to the byte-range 2097152-3145727 of the file `/tmp/readme`.

See the included test project for a full example.

### Credits

This is an adaption of BJ Homer's great example subclass [HSCountingInputStream](https://github.com/bjhomer/HSCountingInputStream).
