---
title: Spring 加载含中文 properties 文件的思考
date: 2016-05-23 15:17:18
tags:
  - Java
  - Spring
  - Encoding
categories:
  - Coding
---

在公司项目的中间件代码里看到有些配置文件里有很多 `"\uXXXX"` 标记的 unicode 字符，其实就是配置里的中文字符。我一时不得其解，开发平台是 Linux，项目文件都是 UTF-8 编码，配置文件里的中文字符为什么还会被转码？

<!-- more -->

### 编码那些事儿

Spring 读取 `.properties` 文件并将配置内容加载进 [Properties](http://docs.oracle.com/javase/8/docs/api/java/util/Properties.html) 类，文档中明确写明
> ... the input/output stream is encoded in ISO 8859-1 character encoding. Characters that cannot be directly represented in this encoding can be written using Unicode escapes as defined in section 3.3 of The Java™ Language Specification; only a single 'u' character is allowed in an escape sequence. The native2ascii tool can be used to convert property files to and from other character encodings.

Java 的 I/O 流是由 ISO 8859-1 编码的，如果要让 Java I/O 读写 ISO 8859-1 标准以外的字符，就需要把这些字符用 Unicode 编码。也就是转码成上述的 `"\uXXXX"` 形式。JDK 提供了转码工具 `../bin/native2ascii`。比如项目里需要配置包含中文的属性值，就只能把中文内容转码成 Unicode 编码。
```bash
native2ascii –encoding UTF-8 foo_utf8.properties foo.properties
```
上面的 foo_utf8.properties 是由 UTF-8 编码保存的配置文件，foo.properties 是将非 ISO 8859-1 字符转码为 Unicode 后的配置文件，也就是提供给 Spring 解析的配置文件。
```
// foo_utf8.properties
city=北京
company=京东

// foo.properties
city=\u5317\u4eac
company=\u4eac\u4e1c
```

### Java 读取 UTF-8

虽然明白了这其中的蹊跷，但是包含中文的配置文件一定得转码吗，仔细阅读 Properties Class 的源码后，还是有更优雅的解决方案，原来 Sun 公司都已经帮我们设计好了。
Properties 类调用 load() 方法加载配置文件：
```java
// Properties Class source code
package java.util;

public synchronized void load(Reader reader) throws IOException {
    load0(new LineReader(reader));
}

public synchronized void load(InputStream inStream) throws IOException {
    load0(new LineReader(inStream));
}

private void load0 (LineReader lr) throws IOException {
    char[] convtBuf = new char[1024];
    int limit;
    int keyLen;
    int valueStart;
    char c;
    boolean hasSep;
    boolean precedingBackslash;

    while ((limit = lr.readLine()) >= 0) {
        c = 0;
        keyLen = 0;
        valueStart = limit;
        hasSep = false;

        //System.out.println("line=<" + new String(lineBuf, 0, limit) + ">");
        precedingBackslash = false;
        while (keyLen < limit) {
            c = lr.lineBuf[keyLen];
            //need check if escaped.
            if ((c == '=' ||  c == ':') && !precedingBackslash) {
                valueStart = keyLen + 1;
                hasSep = true;
                break;
            } else if ((c == ' ' || c == '\t' ||  c == '\f') && !precedingBackslash) {
                valueStart = keyLen + 1;
                break;
            }
            if (c == '\\') {
                precedingBackslash = !precedingBackslash;
            } else {
                precedingBackslash = false;
            }
            keyLen++;
        }
        while (valueStart < limit) {
            c = lr.lineBuf[valueStart];
            if (c != ' ' && c != '\t' &&  c != '\f') {
                if (!hasSep && (c == '=' ||  c == ':')) {
                    hasSep = true;
                } else {
                    break;
                }
            }
            valueStart++;
        }
        String key = loadConvert(lr.lineBuf, 0, keyLen, convtBuf);
        String value = loadConvert(lr.lineBuf, valueStart, limit - valueStart, convtBuf);
        put(key, value);
    }
}

private String loadConvert (char[] in, int off, int len, char[] convtBuf) {
    if (convtBuf.length < len) {
        int newLen = len * 2;
        if (newLen < 0) {
            newLen = Integer.MAX_VALUE;
        }
        convtBuf = new char[newLen];
    }
    char aChar;
    char[] out = convtBuf;
    int outLen = 0;
    int end = off + len;

    while (off < end) {
        aChar = in[off++];
        if (aChar == '\\') {
            aChar = in[off++];
            if(aChar == 'u') {
                // Read the xxxx
                int value=0;
                for (int i=0; i<4; i++) {
                    aChar = in[off++];
                    switch (aChar) {
                      case '0': case '1': case '2': case '3': case '4':
                      case '5': case '6': case '7': case '8': case '9':
                         value = (value << 4) + aChar - '0';
                         break;
                      case 'a': case 'b': case 'c':
                      case 'd': case 'e': case 'f':
                         value = (value << 4) + 10 + aChar - 'a';
                         break;
                      case 'A': case 'B': case 'C':
                      case 'D': case 'E': case 'F':
                         value = (value << 4) + 10 + aChar - 'A';
                         break;
                      default:
                          throw new IllegalArgumentException(
                                       "Malformed \\uxxxx encoding.");
                    }
                 }
                out[outLen++] = (char)value;
            } else {
                if (aChar == 't') aChar = '\t';
                else if (aChar == 'r') aChar = '\r';
                else if (aChar == 'n') aChar = '\n';
                else if (aChar == 'f') aChar = '\f';
                out[outLen++] = aChar;
            }
        } else {
            out[outLen++] = aChar;
        }
    }
    return new String (out, 0, outLen);
}
```

我从 Properties Class 的源码里抄录了加载配置文件的关键代码。不难读懂代码的含义，简单说明下，load() 方法是通过调用 load0() 方法来按行读取配置文件，并装配成 key - value 的键值对，在 load0() 内部调用了 loadConvert() 方法，用来将 Unicode 字符转换成原始的格式。其中，load() 方法被重载实现，可以传入 Reader 参数，或者 InputStream 参数。

这里就涉及到Java I/O 里 Reader/Writer 和 InputStream/OutputStream 的差异了，Reader 类用于读取文本数据（char、String 流），InputStream 类则用于读取二进制数据（byte 流）。Reader 类可以指定 Charset 参数来设置编码格式，如 UTF-8 等。因此只需要指定 Reader 对象的 charset，就可以无痛解析带中文的配置文件了，只是有一点要指出， FileReader 的构造函数是假定使用的编码格式是正确的（即默认的ISO 8859-1），不支持指定文件编码格式，因此还是需要借助 InputStream 类。示例代码如下，很简单：
```java
// ReadUTF8Props.java
Properties properties = new Properties();
InputStream inputStream = getClass().getClassLoader().getResourceAsStream("foo_utf8.properties");
try {
    InputStreamReader isr = new InputStreamReader(inputStream, "UTF-8");
    try {
        properties.load(isr);
    } finally {
        isr.close();
    }
} finally {
    inputStream.close();
}
```

到这儿，总算对这个问题有了一点点深入的认识。