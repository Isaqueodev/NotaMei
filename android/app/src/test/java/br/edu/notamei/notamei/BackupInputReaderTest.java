package br.edu.notamei.notamei;

import java.io.*;
import java.util.Arrays;

/** JVM-only regression tests: run main with javac/java, no Android or user files. */
public final class BackupInputReaderTest {
  private static int checks;
  private static void check(boolean ok) { if (!ok) throw new AssertionError(); checks++; }
  private static final class Source extends InputStream {
    final int size; int read; boolean closed; final boolean fail;
    Source(int size, boolean fail) { this.size=size; this.fail=fail; }
    @Override public int read() throws IOException {
      if (fail) throw new IOException("PRIVATE_PATH_AND_NOTE");
      return read++ < size ? 42 : -1;
    }
    @Override public void close() { closed=true; }
  }
  public static void main(String[] args) throws Exception {
    Source small = new Source(3, false);
    check(Arrays.equals(BackupInputReader.read(small), new byte[]{42,42,42}));
    check(small.closed);
    Source exact = new Source(BackupInputReader.MAX_BYTES, false);
    check(BackupInputReader.read(exact).length == BackupInputReader.MAX_BYTES);
    check(exact.closed);
    Source large = new Source(BackupInputReader.MAX_BYTES+20000, false);
    try { BackupInputReader.read(large); throw new AssertionError(); }
    catch (BackupInputReader.TooLargeException expected) { check(large.closed); }
    check(large.read <= BackupInputReader.MAX_BYTES+1);
    Source broken = new Source(1, true);
    try { BackupInputReader.read(broken); throw new AssertionError(); }
    catch (IOException expected) { check(broken.closed); }
    check(BackupInputReader.read(new ByteArrayInputStream(new byte[0])).length == 0);
    System.out.println("PASS " + checks + " assertions: exact limit, excess, early stop, I/O and stream closing");
  }
}
